class_name PassionEffect
extends CardEffect
## Modifies the player's Passion. Positive values increase, negative decrease.
## Passion changes are adjusted by the character's volatility in RunManager.


func apply(_source, _target, _battle_state) -> void:
	RunManager.change_passion(value)


func get_description() -> String:
	if value > 0:
		return "+%d Passion." % value
	return "%d Passion." % value
