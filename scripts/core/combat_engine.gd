class_name CombatEngine
extends Node
## Drives combat: state machine, turn flow, card resolution, enemy actions.
## Effects route through this engine so it can emit signals and handle side effects.

enum Phase {
	PLAYER_TURN_START,
	PLAYER_TURN,
	ANIMATING,
	PLAYER_TURN_END,
	ENEMY_TURN,
	BATTLE_WON,
	BATTLE_LOST,
}

const HAND_SIZE := 5
const MAX_ENERGY := 3

var phase: Phase = Phase.PLAYER_TURN_START
var energy: int = MAX_ENERGY
var turn_number: int = 0
var player_stats: CombatantStats
var enemies: Array[EnemyCombatState] = []
var piles: PileManager
var _current_card: CardData = null # Set during card resolution for zone penalty


func start_combat(deck: Array[CardData], player_hp: int, player_max_hp: int,
		enemy_datas: Array[EnemyData]) -> void:
	player_stats = CombatantStats.new(player_hp, player_max_hp)

	piles = PileManager.new()
	piles.setup(deck)

	enemies.clear()
	for data in enemy_datas:
		var enemy = EnemyCombatState.new(data)
		enemy.select_intent()
		enemies.append(enemy)

	turn_number = 0
	Events.combat_started.emit()
	_process_relics(RelicData.RelicTrigger.ON_COMBAT_START)
	start_player_turn()


# -- Turn Flow --

func start_player_turn() -> void:
	turn_number += 1
	phase = Phase.PLAYER_TURN_START

	energy = MAX_ENERGY
	player_stats.reset_block()
	tick_start_of_turn(player_stats)

	if player_stats.is_dead():
		phase = Phase.BATTLE_LOST
		Events.combat_lost.emit()
		return

	_process_relics(RelicData.RelicTrigger.ON_TURN_START)

	var drawn = piles.draw_cards(HAND_SIZE)
	for card in drawn:
		Events.card_drawn.emit(card)

	phase = Phase.PLAYER_TURN
	Events.player_turn_started.emit()


func end_player_turn() -> void:
	phase = Phase.PLAYER_TURN_END
	tick_end_of_turn(player_stats)

	for card in piles.hand:
		Events.card_discarded.emit(card)
	piles.discard_hand()

	Events.turn_ended.emit()

	if phase == Phase.BATTLE_WON or phase == Phase.BATTLE_LOST:
		return
	start_enemy_turn()


func start_enemy_turn() -> void:
	phase = Phase.ENEMY_TURN

	# Reset enemy block at start of their turn (block gained persists through player's turn)
	for enemy in enemies:
		if not enemy.stats.is_dead():
			enemy.stats.reset_block()

	Events.enemy_turn_started.emit()

	for enemy in enemies:
		if enemy.stats.is_dead():
			continue
		# Per-enemy: tick start -> act -> tick end
		tick_start_of_turn(enemy.stats)
		if enemy.stats.is_dead():
			Events.enemy_died.emit(enemy)
			continue
		execute_enemy_turn(enemy)
		tick_end_of_turn(enemy.stats)
		if player_stats.is_dead():
			break

	if player_stats.is_dead():
		phase = Phase.BATTLE_LOST
		Events.combat_lost.emit()
		return

	check_battle_end()
	if phase == Phase.BATTLE_WON:
		return

	# Select new intents for next turn
	for enemy in enemies:
		if not enemy.stats.is_dead():
			enemy.select_intent()

	start_player_turn()


func execute_enemy_turn(enemy: EnemyCombatState) -> void:
	if not enemy.current_intent:
		return
	for effect in enemy.current_intent.effects:
		effect.apply(enemy.stats, player_stats, self)


# -- Card Play --

func can_play_card(card: CardData) -> bool:
	if phase != Phase.PLAYER_TURN:
		return false
	if card.energy_cost > energy:
		return false
	if card not in piles.hand:
		return false
	return true


func play_card(card: CardData, target: CombatantStats) -> bool:
	if not can_play_card(card):
		return false

	energy -= card.energy_cost
	piles.hand.erase(card)

	# Track current card for zone penalty in deal_damage
	_current_card = card

	# Resolve effects — route to correct targets based on card targeting
	for effect in card.get_active_effects():
		match card.target_type:
			CardData.TargetType.SELF, CardData.TargetType.NONE:
				effect.apply(player_stats, player_stats, self)
			CardData.TargetType.ALL_ENEMIES:
				for enemy in enemies:
					if not enemy.stats.is_dead():
						effect.apply(player_stats, enemy.stats, self)
			CardData.TargetType.SINGLE_ENEMY:
				effect.apply(player_stats, target, self)

	_current_card = null
	Events.card_played.emit(card, target)

	if card.exhaust:
		piles.exhaust_pile.append(card)
		Events.card_exhausted.emit(card)
	else:
		piles.discard_pile.append(card)
		Events.card_discarded.emit(card)

	check_battle_end()
	return true


# -- Methods called by CardEffect subclasses --

func deal_damage(target: CombatantStats, base_amount: int,
		source: CombatantStats = null) -> void:
	var amount = base_amount

	# Source modifiers
	if source:
		amount += source.get_status_stacks(StatusEffects.STRENGTH)
		if source.has_status(StatusEffects.WEAK):
			amount = int(amount * 0.75)

	# Zone penalty: 25% damage nerf for off-type cards at extreme tiers
	# Only applies to player cards (source == player_stats), not enemies or neutrals
	if _current_card and source == player_stats:
		amount = _apply_zone_penalty(amount, _current_card.personality)

	# Target modifiers
	if target.has_status(StatusEffects.VULNERABLE):
		amount = int(amount * 1.5)

	amount = maxi(0, amount)
	var actual = target.take_damage(amount)
	_on_damage_dealt(target, actual)


func apply_block(target: CombatantStats, amount: int) -> void:
	var actual = amount + target.get_status_stacks(StatusEffects.DEXTERITY)
	target.gain_block(actual)
	Events.block_gained.emit(target, actual)


func draw_cards(count: int) -> void:
	var drawn = piles.draw_cards(count)
	for card in drawn:
		Events.card_drawn.emit(card)


func change_energy(amount: int) -> void:
	energy = maxi(0, energy + amount)


func apply_status_effect(target: CombatantStats, effect: StatusEffectData,
		stacks: int) -> void:
	target.apply_status(effect, stacks)
	Events.status_applied.emit(target, effect, stacks)


# -- Status Effect Ticking --

func tick_start_of_turn(stats: CombatantStats) -> void:
	if stats.has_status(StatusEffects.POISON):
		var stacks = stats.get_status_stacks(StatusEffects.POISON)
		stats.take_direct_damage(stacks)
		_on_damage_dealt(stats, stacks)
		_reduce_status(stats, StatusEffects.POISON)


func tick_end_of_turn(stats: CombatantStats) -> void:
	_reduce_status(stats, StatusEffects.VULNERABLE)
	_reduce_status(stats, StatusEffects.WEAK)


func _reduce_status(stats: CombatantStats, effect: StatusEffectData) -> void:
	if not stats.has_status(effect):
		return
	stats.statuses[effect] -= 1
	if stats.get_status_stacks(effect) <= 0:
		stats.remove_status(effect)
		Events.status_removed.emit(stats, effect)


func _on_damage_dealt(target: CombatantStats, amount: int) -> void:
	if target == player_stats:
		Events.player_damaged.emit(amount, target.current_hp)
		if target.is_dead():
			phase = Phase.BATTLE_LOST
			Events.combat_lost.emit()
	else:
		for enemy in enemies:
			if enemy.stats == target:
				Events.enemy_damaged.emit(enemy, amount, target.current_hp)
				if target.is_dead():
					Events.enemy_died.emit(enemy)
				break


# -- Relic Processing --

func _process_relics(trigger: RelicData.RelicTrigger) -> void:
	for relic in RunManager.relics:
		if relic.trigger != trigger:
			continue
		_apply_relic_effect(relic)


func process_combat_end_relics() -> void:
	for relic in RunManager.relics:
		if relic.trigger != RelicData.RelicTrigger.ON_COMBAT_END:
			continue
		match relic.effect:
			RelicData.RelicEffect.HEAL:
				RunManager.heal(relic.value)
			RelicData.RelicEffect.GAIN_GOLD:
				RunManager.add_gold(relic.value)


func _apply_relic_effect(relic: RelicData) -> void:
	match relic.effect:
		RelicData.RelicEffect.GAIN_BLOCK:
			apply_block(player_stats, relic.value)
		RelicData.RelicEffect.GAIN_STRENGTH:
			apply_status_effect(player_stats, StatusEffects.STRENGTH, relic.value)
		RelicData.RelicEffect.GAIN_DEXTERITY:
			apply_status_effect(player_stats, StatusEffects.DEXTERITY, relic.value)
		RelicData.RelicEffect.APPLY_VULNERABLE_ALL:
			for enemy in enemies:
				if not enemy.stats.is_dead():
					apply_status_effect(enemy.stats, StatusEffects.VULNERABLE, relic.value)
		RelicData.RelicEffect.APPLY_WEAK_ALL:
			for enemy in enemies:
				if not enemy.stats.is_dead():
					apply_status_effect(enemy.stats, StatusEffects.WEAK, relic.value)
		RelicData.RelicEffect.DRAW_CARDS:
			draw_cards(relic.value)
		RelicData.RelicEffect.GAIN_PASSION:
			RunManager.change_passion(relic.value)
		RelicData.RelicEffect.HEAL:
			player_stats.current_hp = mini(
				player_stats.current_hp + relic.value, player_stats.max_hp)


# -- Zone Penalty --

## Applies 25% damage nerf when playing off-type cards at extreme passion tiers.
## Blazing + SECONDARY card = 0.75x. Hollow + PRIMARY card = 0.75x. Neutrals exempt.
func _apply_zone_penalty(amount: int, personality: CardData.PersonalityType) -> int:
	if personality == CardData.PersonalityType.NEUTRAL:
		return amount
	var tier = RunManager.get_passion_tier()
	if tier == PassionState.Tier.BLAZING and personality == CardData.PersonalityType.SECONDARY:
		return int(amount * 0.75)
	if tier == PassionState.Tier.HOLLOW and personality == CardData.PersonalityType.PRIMARY:
		return int(amount * 0.75)
	return amount


## Returns true if zone penalty currently applies for a given personality type.
## Used by UI to show modified damage values on cards.
static func is_zone_penalized(personality: CardData.PersonalityType) -> bool:
	if personality == CardData.PersonalityType.NEUTRAL:
		return false
	var tier = RunManager.get_passion_tier()
	if tier == PassionState.Tier.BLAZING and personality == CardData.PersonalityType.SECONDARY:
		return true
	if tier == PassionState.Tier.HOLLOW and personality == CardData.PersonalityType.PRIMARY:
		return true
	return false


# -- Battle End Check --

func check_battle_end() -> void:
	if player_stats.is_dead():
		phase = Phase.BATTLE_LOST
		Events.combat_lost.emit()
		return

	var all_dead = true
	for enemy in enemies:
		if not enemy.stats.is_dead():
			all_dead = false
			break

	if all_dead:
		phase = Phase.BATTLE_WON
		Events.combat_won.emit()
