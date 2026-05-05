extends Node
## Manages the lifecycle of a single run.
## Owns all persistent run state: deck, relics, equipment, gold, passion, act progression.

var current_character: CharacterData
var current_deck: Array[CardData] = []
var relics: Array[RelicData] = []
var equipment: Dictionary = {} # EquipmentData.EquipmentSlot -> EquipmentData
var perks: Array[PerkData] = []
var gold: int = 0
var current_act: int = 0
var current_hp: int = 0
var max_hp: int = 0
var passion: PassionState
var run_active: bool = false
var current_map: MapData
var pending_enemies: Array[EnemyData] = []
var pending_gold_reward: int = 0
var pending_relic_reward: bool = false
var pending_relic_is_boss: bool = false
var pending_act_complete: bool = false
var run_start_time: int = 0 # msec from Time.get_ticks_msec()
var run_stats: Dictionary = {}

const MAX_ACTS := 3


func add_gold(amount: int) -> void:
	gold += amount
	if run_active and amount > 0:
		run_stats["gold_earned"] = run_stats.get("gold_earned", 0) + amount


func start_run(character: CharacterData, seed_value: int = -1) -> void:
	current_character = character
	current_hp = character.max_health
	max_hp = character.max_health
	current_act = 1
	gold = 0
	relics.clear()
	equipment.clear()
	perks.clear()
	run_active = true
	current_map = null
	pending_enemies.clear()
	pending_gold_reward = 0
	pending_relic_reward = false
	pending_relic_is_boss = false
	pending_act_complete = false
	run_start_time = Time.get_ticks_msec()
	run_stats = {
		"cards_played": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"enemies_killed": 0,
		"gold_earned": 0,
		"floors_cleared": 0,
	}

	# Build starting deck (deep copy so upgrades don't modify templates)
	current_deck.clear()
	for card in character.starting_deck:
		current_deck.append(card.duplicate_card())

	# Initialize passion
	passion = PassionState.new()
	passion.current_value = passion.starting_value

	# Setup deterministic RNG
	if seed_value < 0:
		seed_value = RngManager.generate_seed()
	RngManager.setup_run(seed_value)

	Events.run_started.emit(character)


func advance_act() -> void:
	Events.act_ended.emit(current_act)
	current_act += 1
	current_map = null
	pending_act_complete = false
	Events.act_started.emit(current_act)


func end_run(victory: bool) -> void:
	run_active = false
	Events.run_ended.emit(victory)


func add_card_to_deck(card: CardData) -> void:
	current_deck.append(card.duplicate_card())


func remove_card_from_deck(index: int) -> void:
	if index >= 0 and index < current_deck.size():
		current_deck.remove_at(index)


func add_relic(relic: RelicData) -> void:
	relics.append(relic)
	if relic.trigger == RelicData.RelicTrigger.ON_PICKUP:
		_apply_pickup_relic(relic)
	Events.relic_acquired.emit(relic)


func has_relic(relic_name: String) -> bool:
	for r in relics:
		if r.relic_name == relic_name:
			return true
	return false


func get_owned_relic_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for r in relics:
		names.append(r.relic_name)
	return names


func _apply_pickup_relic(relic: RelicData) -> void:
	match relic.effect:
		RelicData.RelicEffect.GAIN_MAX_HP:
			max_hp += relic.value
			current_hp += relic.value
		RelicData.RelicEffect.HEAL:
			heal(relic.value)
		RelicData.RelicEffect.GAIN_GOLD:
			add_gold(relic.value)


func equip(item: EquipmentData) -> void:
	var old = equipment.get(item.slot)
	equipment[item.slot] = item
	Events.equipment_changed.emit(item.slot, old, item)


func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	Events.player_damaged.emit(amount, current_hp)
	if current_hp <= 0:
		end_run(false)


func get_run_elapsed_seconds() -> int:
	return (Time.get_ticks_msec() - run_start_time) / 1000


func get_run_time_string() -> String:
	var total = get_run_elapsed_seconds()
	var minutes = total / 60
	var seconds = total % 60
	return "%d:%02d" % [minutes, seconds]


func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)


func change_passion(amount: int) -> void:
	if passion and current_character:
		var adjusted = int(amount * current_character.passion_volatility)
		var old_value = passion.current_value
		passion.current_value = clampi(
			passion.current_value + adjusted,
			passion.min_value,
			passion.max_value
		)
		Events.passion_changed.emit(old_value, passion.current_value)

		# Check for tier change
		var old_tier = get_passion_tier_for_value(old_value)
		var new_tier = get_passion_tier_for_value(passion.current_value)
		if old_tier != new_tier:
			Events.passion_tier_changed.emit(old_tier, new_tier)


func get_passion_tier() -> int:
	if not passion or not current_character:
		return PassionState.Tier.STEADY
	return get_passion_tier_for_value(passion.current_value)


func get_passion_tier_for_value(value: int) -> int:
	if not current_character:
		return PassionState.Tier.STEADY
	var thresholds = current_character.passion_thresholds
	# thresholds = [blazing_min, inspired_min, steady_min, wavering_min]
	# Values below wavering_min are Hollow
	if value >= thresholds[0]:
		return PassionState.Tier.BLAZING
	elif value >= thresholds[1]:
		return PassionState.Tier.INSPIRED
	elif value >= thresholds[2]:
		return PassionState.Tier.STEADY
	elif value >= thresholds[3]:
		return PassionState.Tier.WAVERING
	else:
		return PassionState.Tier.HOLLOW
