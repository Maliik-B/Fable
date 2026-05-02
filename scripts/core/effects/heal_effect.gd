class_name HealEffect
extends CardEffect
## Heals the source (card player) for the given value.


func apply(_source, _target, _battle_state) -> void:
	RunManager.heal(value)


func get_description() -> String:
	return "Heal %d HP." % value
