class_name CardEffect
extends Resource
## Base class for all card (and enemy move) effects.
## Subclass this and override apply() to create new effect types.
## Cards and enemy moves compose arrays of these to define their behavior.

@export var value: int = 0


func apply(_source, _target, _battle_state) -> void:
	pass


func get_description() -> String:
	return ""


func get_modified_description(_source: CombatantStats, _target: CombatantStats = null) -> String:
	return get_description()
