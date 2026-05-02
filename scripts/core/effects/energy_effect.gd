class_name EnergyEffect
extends CardEffect
## Modifies the player's energy for the current turn.


func apply(_source, _target, battle_state) -> void:
	if battle_state.has_method("change_energy"):
		battle_state.change_energy(value)


func get_description() -> String:
	if value > 0:
		return "Gain %d Energy." % value
	return "Lose %d Energy." % abs(value)
