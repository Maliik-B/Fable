class_name CardData
extends Resource
## Defines a single card's properties. Cards are composed of CardEffect arrays.
## Create .tres files from this resource to define individual cards.

enum CardType { ATTACK, SKILL, POWER }
enum CardRarity { STARTER, COMMON, UNCOMMON, RARE }
enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SELF, NONE }
enum PersonalityType { PRIMARY, SECONDARY, NEUTRAL, NEGATIVE }

@export var card_name: String = ""
@export var energy_cost: int = 1
@export_multiline var description: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var rarity: CardRarity = CardRarity.COMMON
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var personality: PersonalityType = PersonalityType.NEUTRAL
@export var effects: Array[CardEffect] = []
@export var exhaust: bool = false
@export var card_art: Texture2D

# Upgrade tracking
@export var upgraded: bool = false
@export var upgrade_effects: Array[CardEffect] = [] # Effects when upgraded (replaces base effects)


## Deep copy this card for mutable per-instance state (deck building, upgrades).
## Required because Resource.duplicate(true) has bugs with Array sub-resources.
func duplicate_card() -> CardData:
	var copy = CardData.new()
	copy.card_name = card_name
	copy.energy_cost = energy_cost
	copy.description = description
	copy.card_type = card_type
	copy.rarity = rarity
	copy.target_type = target_type
	copy.personality = personality
	copy.exhaust = exhaust
	copy.card_art = card_art
	copy.upgraded = upgraded

	for effect in effects:
		copy.effects.append(effect.duplicate())

	for effect in upgrade_effects:
		copy.upgrade_effects.append(effect.duplicate())

	return copy


## Upgrades this card. Uses upgrade_effects if defined, otherwise boosts base effect values.
func upgrade_card() -> void:
	if upgraded:
		return
	upgraded = true
	card_name = card_name + "+"

	if upgrade_effects.size() > 0:
		return # Will use upgrade_effects via get_active_effects()

	# Generic upgrade: boost base effect values
	for effect in effects:
		if effect is DamageEffect or effect is BlockEffect:
			effect.value += 3
		elif effect is DrawEffect or effect is EnergyEffect:
			effect.value += 1
		elif effect is StatusApplyEffect:
			effect.value += 1
		elif effect is HealEffect:
			effect.value += 3
		elif effect is PassionEffect:
			if effect.value > 0:
				effect.value += 1
			else:
				effect.value -= 1


## Returns the currently active effects (base or upgraded).
func get_active_effects() -> Array[CardEffect]:
	if upgraded and upgrade_effects.size() > 0:
		return upgrade_effects
	return effects


## Generates a description string from the card's effects.
func get_generated_description() -> String:
	var parts: PackedStringArray = []
	for effect in get_active_effects():
		var desc = effect.get_description()
		if desc != "":
			parts.append(desc)
	var text = " ".join(parts)
	if target_type == TargetType.ALL_ENEMIES:
		text += " Hits all enemies."
	return text


## Generates description with combat modifiers (Strength, Weak, Dexterity) applied.
func get_modified_description(source: CombatantStats) -> String:
	var parts: PackedStringArray = []
	for effect in get_active_effects():
		var desc = effect.get_modified_description(source)
		if desc != "":
			parts.append(desc)
	var text = " ".join(parts)
	if target_type == TargetType.ALL_ENEMIES:
		text += " Hits all enemies."
	if CombatEngine.is_zone_penalized(personality):
		text += " [Zone Penalty: -25% dmg]"
	return text
