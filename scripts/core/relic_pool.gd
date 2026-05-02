class_name RelicPool
## Builds and returns relic choices filtered by rarity.


static func get_reward_choices(rng: RandomNumberGenerator, count: int = 3,
		exclude_names: PackedStringArray = []) -> Array[RelicData]:
	var pool = _build_pool()

	# Remove relics the player already owns
	var filtered: Array[RelicData] = []
	for relic in pool:
		var dominated = false
		for name in exclude_names:
			if relic.relic_name == name:
				dominated = true
				break
		if not dominated:
			filtered.append(relic)

	# Shuffle and pick with rarity weighting
	filtered.shuffle()
	var picked: Array[RelicData] = []
	var rarity = _roll_rarity(rng)

	for relic in filtered:
		if picked.size() >= count:
			break
		if relic.rarity == rarity:
			picked.append(relic)
			rarity = _roll_rarity(rng)

	# Fallback: fill remaining slots
	if picked.size() < count:
		for relic in filtered:
			if picked.size() >= count:
				break
			if relic not in picked:
				picked.append(relic)

	return picked


static func get_boss_reward_choices(rng: RandomNumberGenerator,
		exclude_names: PackedStringArray = []) -> Array[RelicData]:
	var pool = _build_pool()
	var boss_relics: Array[RelicData] = []
	for relic in pool:
		if relic.rarity == RelicData.RelicRarity.BOSS:
			var owned = false
			for name in exclude_names:
				if relic.relic_name == name:
					owned = true
					break
			if not owned:
				boss_relics.append(relic)

	boss_relics.shuffle()
	var result: Array[RelicData] = []
	for i in mini(3, boss_relics.size()):
		result.append(boss_relics[i])
	return result


static func _roll_rarity(rng: RandomNumberGenerator) -> RelicData.RelicRarity:
	var roll = rng.randf()
	if roll < 0.5:
		return RelicData.RelicRarity.COMMON
	if roll < 0.83:
		return RelicData.RelicRarity.UNCOMMON
	return RelicData.RelicRarity.RARE


static func _build_pool() -> Array[RelicData]:
	var pool: Array[RelicData] = []

	# -- COMMON --
	pool.append(_relic("Burning Blood", "Heal 6 HP after each combat.",
		RelicData.RelicRarity.COMMON, RelicData.RelicTrigger.ON_COMBAT_END,
		RelicData.RelicEffect.HEAL, 6))

	pool.append(_relic("Vajra", "Start each combat with 1 Strength.",
		RelicData.RelicRarity.COMMON, RelicData.RelicTrigger.ON_COMBAT_START,
		RelicData.RelicEffect.GAIN_STRENGTH, 1))

	pool.append(_relic("Anchor", "Start each combat with 10 Block.",
		RelicData.RelicRarity.COMMON, RelicData.RelicTrigger.ON_COMBAT_START,
		RelicData.RelicEffect.GAIN_BLOCK, 10))

	pool.append(_relic("Bag of Marbles", "At the start of combat, apply 1 Vulnerable to ALL enemies.",
		RelicData.RelicRarity.COMMON, RelicData.RelicTrigger.ON_COMBAT_START,
		RelicData.RelicEffect.APPLY_VULNERABLE_ALL, 1))

	pool.append(_relic("Red Mask", "At the start of combat, apply 1 Weak to ALL enemies.",
		RelicData.RelicRarity.COMMON, RelicData.RelicTrigger.ON_COMBAT_START,
		RelicData.RelicEffect.APPLY_WEAK_ALL, 1))

	# -- UNCOMMON --
	pool.append(_relic("Oddly Smooth Stone", "Start each combat with 1 Dexterity.",
		RelicData.RelicRarity.UNCOMMON, RelicData.RelicTrigger.ON_COMBAT_START,
		RelicData.RelicEffect.GAIN_DEXTERITY, 1))

	pool.append(_relic("Old Coin", "Gain 15 bonus Gold after each combat.",
		RelicData.RelicRarity.UNCOMMON, RelicData.RelicTrigger.ON_COMBAT_END,
		RelicData.RelicEffect.GAIN_GOLD, 15))

	pool.append(_relic("Mango", "Upon pickup, gain 14 Max HP.",
		RelicData.RelicRarity.UNCOMMON, RelicData.RelicTrigger.ON_PICKUP,
		RelicData.RelicEffect.GAIN_MAX_HP, 14))

	pool.append(_relic("Bag of Preparation", "Draw 2 additional cards at the start of combat.",
		RelicData.RelicRarity.UNCOMMON, RelicData.RelicTrigger.ON_COMBAT_START,
		RelicData.RelicEffect.DRAW_CARDS, 2))

	pool.append(_relic("Flame Pendant", "Gain 3 Passion at the start of combat.",
		RelicData.RelicRarity.UNCOMMON, RelicData.RelicTrigger.ON_COMBAT_START,
		RelicData.RelicEffect.GAIN_PASSION, 3))

	# -- RARE --
	pool.append(_relic("War Paint", "Gain 5 Block at the start of each turn.",
		RelicData.RelicRarity.RARE, RelicData.RelicTrigger.ON_TURN_START,
		RelicData.RelicEffect.GAIN_BLOCK, 5))

	pool.append(_relic("Ember of Resolve", "Gain 1 Passion at the start of each turn.",
		RelicData.RelicRarity.RARE, RelicData.RelicTrigger.ON_TURN_START,
		RelicData.RelicEffect.GAIN_PASSION, 1))

	pool.append(_relic("Thread of Fate", "Draw 1 additional card at the start of each turn.",
		RelicData.RelicRarity.RARE, RelicData.RelicTrigger.ON_TURN_START,
		RelicData.RelicEffect.DRAW_CARDS, 1))

	pool.append(_relic("Demon's Horn", "Gain 1 Strength at the start of each turn.",
		RelicData.RelicRarity.RARE, RelicData.RelicTrigger.ON_TURN_START,
		RelicData.RelicEffect.GAIN_STRENGTH, 1))

	# -- BOSS --
	pool.append(_relic("Black Blood", "Heal 12 HP after each combat.",
		RelicData.RelicRarity.BOSS, RelicData.RelicTrigger.ON_COMBAT_END,
		RelicData.RelicEffect.HEAL, 12))

	pool.append(_relic("Frozen Eye", "Draw 2 additional cards at the start of each turn.",
		RelicData.RelicRarity.BOSS, RelicData.RelicTrigger.ON_TURN_START,
		RelicData.RelicEffect.DRAW_CARDS, 2))

	pool.append(_relic("Mark of Pain", "Start each combat with 2 Strength. Apply 1 Vulnerable to yourself.",
		RelicData.RelicRarity.BOSS, RelicData.RelicTrigger.ON_COMBAT_START,
		RelicData.RelicEffect.GAIN_STRENGTH, 2))

	pool.append(_relic("Runic Crown", "Start each combat with 3 Dexterity.",
		RelicData.RelicRarity.BOSS, RelicData.RelicTrigger.ON_COMBAT_START,
		RelicData.RelicEffect.GAIN_DEXTERITY, 3))

	return pool


static func _relic(relic_name: String, desc: String, rarity: RelicData.RelicRarity,
		trigger: RelicData.RelicTrigger, effect: RelicData.RelicEffect,
		val: int) -> RelicData:
	var r = RelicData.new()
	r.relic_name = relic_name
	r.description = desc
	r.rarity = rarity
	r.trigger = trigger
	r.effect = effect
	r.value = val
	return r
