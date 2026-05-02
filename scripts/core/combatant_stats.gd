class_name CombatantStats
extends RefCounted
## Runtime combat stats for a player or enemy. Pure data — no signals.
## The CombatEngine handles events and side effects.

var current_hp: int
var max_hp: int
var block: int = 0
var statuses: Dictionary = {} # StatusEffectData -> int (stacks)


func _init(hp: int = 1, hp_max: int = -1) -> void:
	current_hp = hp
	max_hp = hp_max if hp_max > 0 else hp


## Deals damage after block. Returns actual HP lost.
func take_damage(amount: int) -> int:
	var blocked = mini(block, amount)
	block -= blocked
	var remaining = amount - blocked
	current_hp = maxi(0, current_hp - remaining)
	return remaining


func gain_block(amount: int) -> void:
	block += amount


func reset_block() -> void:
	block = 0


func apply_status(effect: StatusEffectData, stacks: int) -> void:
	if effect in statuses:
		match effect.stack_type:
			StatusEffectData.StackType.INTENSITY:
				statuses[effect] += stacks
			StatusEffectData.StackType.DURATION:
				statuses[effect] = maxi(statuses[effect], stacks)
			StatusEffectData.StackType.NONE:
				statuses[effect] = stacks
	else:
		statuses[effect] = stacks


func remove_status(effect: StatusEffectData) -> void:
	statuses.erase(effect)


func has_status(effect: StatusEffectData) -> bool:
	return effect in statuses


func get_status_stacks(effect: StatusEffectData) -> int:
	return statuses.get(effect, 0)


## Direct HP loss, bypassing block. Used for Poison and similar effects.
func take_direct_damage(amount: int) -> int:
	current_hp = maxi(0, current_hp - amount)
	return amount


func is_dead() -> bool:
	return current_hp <= 0
