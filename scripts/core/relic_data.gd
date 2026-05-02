class_name RelicData
extends Resource
## Defines a relic: a passive stacking bonus acquired during a run.
## Each relic has a trigger (when it fires) and an effect (what it does).

enum RelicRarity { COMMON, UNCOMMON, RARE, BOSS }

enum RelicTrigger {
	ON_PICKUP,        # One-time when acquired
	ON_COMBAT_START,  # Start of each combat
	ON_COMBAT_END,    # After combat victory
	ON_TURN_START,    # Start of each player turn
}

enum RelicEffect {
	GAIN_MAX_HP,
	HEAL,
	GAIN_GOLD,
	GAIN_BLOCK,
	GAIN_STRENGTH,
	GAIN_DEXTERITY,
	APPLY_VULNERABLE_ALL,
	APPLY_WEAK_ALL,
	DRAW_CARDS,
	GAIN_PASSION,
}

@export var relic_name: String = ""
@export_multiline var description: String = ""
@export var rarity: RelicRarity = RelicRarity.COMMON
@export var trigger: RelicTrigger = RelicTrigger.ON_COMBAT_START
@export var effect: RelicEffect = RelicEffect.HEAL
@export var value: int = 0
@export var icon: Texture2D
