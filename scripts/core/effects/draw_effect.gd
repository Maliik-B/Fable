class_name DrawEffect
extends CardEffect
## Draws cards from the draw pile into the hand.


func apply(_source, _target, battle_state) -> void:
	if battle_state.has_method("draw_cards"):
		battle_state.draw_cards(value)


func get_description() -> String:
	if value == 1:
		return "Draw a card."
	return "Draw %d cards." % value
