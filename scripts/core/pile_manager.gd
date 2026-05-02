class_name PileManager
extends RefCounted
## Manages the four card piles during combat: draw, hand, discard, exhaust.
## Pure data operations — no signals. The CombatEngine handles events.

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var exhaust_pile: Array[CardData] = []


## Copy the run's deck into the draw pile and shuffle.
func setup(deck: Array[CardData]) -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	for card in deck:
		draw_pile.append(card)
	shuffle_draw_pile()


func shuffle_draw_pile() -> void:
	for i in range(draw_pile.size() - 1, 0, -1):
		var j = RngManager.deck_rng.randi_range(0, i)
		var temp = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = temp


## Draw a single card. Reshuffles discard into draw if empty.
func draw_card() -> CardData:
	if draw_pile.is_empty():
		reshuffle_discard_into_draw()
	if draw_pile.is_empty():
		return null
	var card = draw_pile.pop_back()
	hand.append(card)
	return card


func draw_cards(count: int) -> Array[CardData]:
	var drawn: Array[CardData] = []
	for i in count:
		var card = draw_card()
		if card:
			drawn.append(card)
	return drawn


func discard_card(card: CardData) -> void:
	hand.erase(card)
	discard_pile.append(card)


func discard_hand() -> void:
	discard_pile.append_array(hand)
	hand.clear()


func exhaust_card(card: CardData) -> void:
	hand.erase(card)
	exhaust_pile.append(card)


func reshuffle_discard_into_draw() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle_draw_pile()
