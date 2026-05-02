class_name EventData
extends RefCounted
## Defines a narrative event with choices and consequences.

var event_name: String = ""
var description: String = ""
var choices: Array[EventChoice] = []


class EventChoice extends RefCounted:
	var text: String = ""
	var result_text: String = ""
	var hp_change: int = 0
	var max_hp_change: int = 0
	var gold_change: int = 0
	var passion_change: int = 0
	var card_reward: bool = false  # Offer 3 cards to pick from
	var remove_card: bool = false  # Offer to remove a card from deck
