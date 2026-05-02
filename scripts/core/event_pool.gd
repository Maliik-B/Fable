class_name EventPool
## Builds and returns random narrative events.


static func get_random_event(rng: RandomNumberGenerator) -> EventData:
	var pool = _build_pool()
	return pool[rng.randi_range(0, pool.size() - 1)]


static func _build_pool() -> Array[EventData]:
	var pool: Array[EventData] = []

	pool.append(_wounded_traveler())
	pool.append(_ancient_shrine())
	pool.append(_forgotten_library())
	pool.append(_ominous_statue())
	pool.append(_wandering_spirit())
	pool.append(_training_grounds())
	pool.append(_suspicious_chest())
	pool.append(_campfire_remnants())

	return pool


# ============================================================
# EVENT DEFINITIONS
# ============================================================

static func _wounded_traveler() -> EventData:
	var e = EventData.new()
	e.event_name = "Wounded Traveler"
	e.description = "A traveler lies wounded by the roadside, clutching a leather pouch. They look up at you with desperate eyes.\n\n\"Please... help me. I can pay.\""

	var c1 = EventData.EventChoice.new()
	c1.text = "Tend to their wounds (Lose 5 HP)"
	c1.result_text = "You bandage their injuries. Grateful, they press a handful of coins into your palm before limping away."
	c1.hp_change = -5
	c1.gold_change = 30
	c1.passion_change = 3

	var c2 = EventData.EventChoice.new()
	c2.text = "Take their pouch and leave"
	c2.result_text = "You snatch the pouch. The traveler says nothing, but their eyes follow you as you walk away."
	c2.gold_change = 20
	c2.passion_change = -5

	var c3 = EventData.EventChoice.new()
	c3.text = "Walk away"
	c3.result_text = "You continue on your path. Some problems aren't yours to solve."

	e.choices.append(c1)
	e.choices.append(c2)
	e.choices.append(c3)
	return e


static func _ancient_shrine() -> EventData:
	var e = EventData.new()
	e.event_name = "Ancient Shrine"
	e.description = "A crumbling stone shrine stands among twisted roots. Faded runes pulse with faint light. The air hums with old power.\n\nYou sense it could still grant a boon... for a price."

	var c1 = EventData.EventChoice.new()
	c1.text = "Pray at the shrine"
	c1.result_text = "Warmth floods through you as the runes flare. Your spirit feels renewed."
	c1.hp_change = 10
	c1.passion_change = 5

	var c2 = EventData.EventChoice.new()
	c2.text = "Desecrate it for materials"
	c2.result_text = "You pry gems from the stonework. The light dies. Something in the air shifts, disappointed."
	c2.gold_change = 40
	c2.passion_change = -8

	var c3 = EventData.EventChoice.new()
	c3.text = "Study the runes carefully"
	c3.result_text = "The runes reveal forgotten knowledge. A new technique crystallizes in your mind."
	c3.card_reward = true

	e.choices.append(c1)
	e.choices.append(c2)
	e.choices.append(c3)
	return e


static func _forgotten_library() -> EventData:
	var e = EventData.new()
	e.event_name = "Forgotten Library"
	e.description = "Shelves of rotting books line a hidden alcove. Most are ruined, but a few tomes remain intact. You could study one... or clear out the dead weight of what you already carry."

	var c1 = EventData.EventChoice.new()
	c1.text = "Study a tome (Add a card)"
	c1.result_text = "You absorb the tome's teachings. New possibilities unfold."
	c1.card_reward = true

	var c2 = EventData.EventChoice.new()
	c2.text = "Burn a useless page (Remove a card)"
	c2.result_text = "You focus on what matters, discarding what holds you back."
	c2.remove_card = true

	var c3 = EventData.EventChoice.new()
	c3.text = "Search for valuables"
	c3.result_text = "Between the pages you find pressed coins and a gemstone."
	c3.gold_change = 25

	e.choices.append(c1)
	e.choices.append(c2)
	e.choices.append(c3)
	return e


static func _ominous_statue() -> EventData:
	var e = EventData.new()
	e.event_name = "Ominous Statue"
	e.description = "A towering obsidian statue looms before you. Its hollow eyes seem to peer into your soul. A basin at its feet is stained dark.\n\nCarved text reads: \"Offer of the flesh, reward of the spirit.\""

	var c1 = EventData.EventChoice.new()
	c1.text = "Offer your blood (Lose 8 HP)"
	c1.result_text = "Pain lances through you as the statue drinks. In return, power surges into your body."
	c1.hp_change = -8
	c1.max_hp_change = 5
	c1.card_reward = true

	var c2 = EventData.EventChoice.new()
	c2.text = "Offer gold (Lose 15 gold)"
	c2.result_text = "The coins dissolve in the basin. The statue's gaze softens, and you feel lighter."
	c2.gold_change = -15
	c2.hp_change = 15

	var c3 = EventData.EventChoice.new()
	c3.text = "Smash it"
	c3.result_text = "The statue shatters. Shards of obsidian rain down, and dark energy crackles across your skin."
	c3.gold_change = 20
	c3.passion_change = -6
	c3.hp_change = -3

	e.choices.append(c1)
	e.choices.append(c2)
	e.choices.append(c3)
	return e


static func _wandering_spirit() -> EventData:
	var e = EventData.new()
	e.event_name = "Wandering Spirit"
	e.description = "A translucent figure drifts between the trees, humming a melancholy tune. It notices you and pauses.\n\n\"Traveler... will you hear my story? I have been alone so long.\""

	var c1 = EventData.EventChoice.new()
	c1.text = "Listen to their story"
	c1.result_text = "The spirit shares a tale of love and loss. As it fades, you feel your resolve harden."
	c1.max_hp_change = 3
	c1.passion_change = 4

	var c2 = EventData.EventChoice.new()
	c2.text = "Ask them to share their power"
	c2.result_text = "The spirit hesitates, then reaches into your chest. Cold energy fills your veins."
	c2.max_hp_change = 5
	c2.hp_change = -5

	var c3 = EventData.EventChoice.new()
	c3.text = "Banish the spirit"
	c3.result_text = "You dispel the spirit with a wave. Its essence scatters into glittering motes you collect."
	c3.gold_change = 25
	c3.passion_change = -4

	e.choices.append(c1)
	e.choices.append(c2)
	e.choices.append(c3)
	return e


static func _training_grounds() -> EventData:
	var e = EventData.new()
	e.event_name = "Training Grounds"
	e.description = "An abandoned training yard. Wooden dummies, rusted weights, and a weapon rack still stand. You could hone your skills here."

	var c1 = EventData.EventChoice.new()
	c1.text = "Train intensely (Lose 3 HP)"
	c1.result_text = "Sweat and effort pay off. You feel sharper, more capable."
	c1.hp_change = -3
	c1.card_reward = true

	var c2 = EventData.EventChoice.new()
	c2.text = "Scavenge the equipment"
	c2.result_text = "You find some serviceable gear and a few coins among the debris."
	c2.gold_change = 20

	var c3 = EventData.EventChoice.new()
	c3.text = "Rest in the shade"
	c3.result_text = "You take a moment to breathe. Sometimes that's enough."
	c3.hp_change = 8

	e.choices.append(c1)
	e.choices.append(c2)
	e.choices.append(c3)
	return e


static func _suspicious_chest() -> EventData:
	var e = EventData.new()
	e.event_name = "Suspicious Chest"
	e.description = "A gilded chest sits in the middle of an empty clearing. No traps visible. No guards. Just a chest, gleaming in the light.\n\nToo good to be true?"

	var c1 = EventData.EventChoice.new()
	c1.text = "Open it carefully"
	c1.result_text = "A hidden needle pricks your finger, but the chest's contents are worth it."
	c1.hp_change = -4
	c1.gold_change = 35
	c1.card_reward = true

	var c2 = EventData.EventChoice.new()
	c2.text = "Smash it open"
	c2.result_text = "The chest explodes with force! Coins scatter everywhere."
	c2.hp_change = -8
	c2.gold_change = 50

	var c3 = EventData.EventChoice.new()
	c3.text = "Leave it alone"
	c3.result_text = "Wisdom is knowing when not to act. You walk on, unscathed."
	c3.passion_change = 2

	e.choices.append(c1)
	e.choices.append(c2)
	e.choices.append(c3)
	return e


static func _campfire_remnants() -> EventData:
	var e = EventData.new()
	e.event_name = "Campfire Remnants"
	e.description = "Embers still glow in a recently abandoned campsite. Bedrolls, supplies, and a journal lie scattered. Whoever was here left in a hurry."

	var c1 = EventData.EventChoice.new()
	c1.text = "Rest by the fire"
	c1.result_text = "The warmth soothes your aches. You drift off briefly and wake feeling restored."
	c1.hp_change = 12

	var c2 = EventData.EventChoice.new()
	c2.text = "Read the journal"
	c2.result_text = "The journal details combat techniques you haven't considered. You feel sharper."
	c2.remove_card = true
	c2.passion_change = 2

	var c3 = EventData.EventChoice.new()
	c3.text = "Loot the supplies"
	c3.result_text = "You stuff your pockets with everything useful. Better you than the wilderness."
	c3.gold_change = 18
	c3.passion_change = -2

	e.choices.append(c1)
	e.choices.append(c2)
	e.choices.append(c3)
	return e
