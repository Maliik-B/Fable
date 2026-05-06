class_name CardPool
## Generates reward card options. Returns random cards filtered by rarity weights.
## Supports tier-based reward splits: passion tier determines how many primary,
## secondary, and generic cards are offered.


## Tier-based reward split: [primary_count, secondary_count, generic_count]
## Blazing 2P+1G, Inspired 1P+2G, Steady 3G, Wavering 1S+2G, Hollow 2S+1G
static func _get_tier_split(tier: int) -> Array[int]:
	match tier:
		PassionState.Tier.BLAZING:
			return [2, 0, 1]
		PassionState.Tier.INSPIRED:
			return [1, 0, 2]
		PassionState.Tier.STEADY:
			return [0, 0, 3]
		PassionState.Tier.WAVERING:
			return [0, 1, 2]
		PassionState.Tier.HOLLOW:
			return [0, 2, 1]
	return [0, 0, 3]


static func get_reward_choices(rng: RandomNumberGenerator, count: int = 3) -> Array[CardData]:
	var character = RunManager.current_character
	var tier = RunManager.get_passion_tier()

	# If character has personality pools, use tier-based split
	if character and (character.primary_cards.size() > 0 or character.secondary_cards.size() > 0):
		return _get_tier_reward_choices(rng, character, tier, count)

	# Fallback: all generic (original behavior)
	return _pick_from_pool(_build_generic_pool(), rng, count)


static func _get_tier_reward_choices(rng: RandomNumberGenerator,
		character: CharacterData, tier: int, _count: int) -> Array[CardData]:
	var split = _get_tier_split(tier)
	var primary_needed: int = split[0]
	var secondary_needed: int = split[1]
	var generic_needed: int = split[2]

	var picked: Array[CardData] = []

	# Pick from primary pool
	if primary_needed > 0 and character.primary_cards.size() > 0:
		var primary_pool = _build_character_pool(character.primary_cards)
		var primary_picks = _pick_from_pool(primary_pool, rng, primary_needed)
		picked.append_array(primary_picks)
		generic_needed += primary_needed - primary_picks.size()

	# Pick from secondary pool
	if secondary_needed > 0 and character.secondary_cards.size() > 0:
		var secondary_pool = _build_character_pool(character.secondary_cards)
		var secondary_picks = _pick_from_pool(secondary_pool, rng, secondary_needed)
		picked.append_array(secondary_picks)
		generic_needed += secondary_needed - secondary_picks.size()

	# Fill remaining with generic
	if generic_needed > 0:
		var generic_pool = _build_generic_pool()
		# Exclude already picked names
		var picked_names: PackedStringArray = []
		for card in picked:
			picked_names.append(card.card_name)
		var filtered: Array[CardData] = []
		for card in generic_pool:
			if card.card_name not in picked_names:
				filtered.append(card)
		var generic_picks = _pick_from_pool(filtered, rng, generic_needed)
		picked.append_array(generic_picks)

	return picked


## Picks unique cards from a pool with rarity weighting.
static func _pick_from_pool(pool: Array[CardData], rng: RandomNumberGenerator,
		count: int) -> Array[CardData]:
	pool.shuffle()

	var picked: Array[CardData] = []
	var rarity = _roll_rarity(rng)
	for card in pool:
		if picked.size() >= count:
			break
		if card.rarity == rarity or picked.size() < count - (pool.size() - pool.find(card)):
			var dupe = false
			for p in picked:
				if p.card_name == card.card_name:
					dupe = true
					break
			if not dupe:
				picked.append(card)
				rarity = _roll_rarity(rng)

	# Fallback: just grab unique cards if weighting didn't fill
	if picked.size() < count:
		for card in pool:
			if picked.size() >= count:
				break
			var dupe = false
			for p in picked:
				if p.card_name == card.card_name:
					dupe = true
					break
			if not dupe:
				picked.append(card)

	return picked


static func _roll_rarity(rng: RandomNumberGenerator) -> CardData.CardRarity:
	var roll = rng.randf()
	if roll < 0.6:
		return CardData.CardRarity.COMMON
	if roll < 0.9:
		return CardData.CardRarity.UNCOMMON
	return CardData.CardRarity.RARE


## Builds pool from character card templates (deep copies with rarity-weighted duplication).
static func _build_character_pool(templates: Array[CardData]) -> Array[CardData]:
	var pool: Array[CardData] = []
	for card in templates:
		pool.append(card.duplicate_card())
	return pool


## Generic card pool — personality-neutral cards available to all characters.
static func _build_generic_pool() -> Array[CardData]:
	var pool: Array[CardData] = []

	# -- COMMON ATTACKS --
	pool.append(_card("Crushing Blow", 2, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.COMMON,
		[_damage(12)]))

	pool.append(_card("Paired Strikes", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.COMMON,
		[_damage(3, 2)]))

	pool.append(_card("Sweep", 1, CardData.CardType.ATTACK,
		CardData.TargetType.ALL_ENEMIES, CardData.CardRarity.COMMON,
		[_damage(5)]))

	pool.append(_card("Reckless Swing", 0, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.COMMON,
		[_damage(5)]))

	# -- COMMON SKILLS --
	pool.append(_card("Retaliate", 1, CardData.CardType.SKILL,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.COMMON,
		[_damage(5), _block(5)]))

	pool.append(_card("Shield Bash", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.COMMON,
		[_block(8)]))

	pool.append(_card("Battle Cry", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.COMMON,
		[_block(3), _draw(1)]))

	# -- UNCOMMON ATTACKS --
	pool.append(_card("Havoc", 2, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.UNCOMMON,
		[_damage(18)]))

	pool.append(_card("Poison Fang", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.UNCOMMON,
		[_damage(3), _status(StatusEffects.POISON, 4)]))

	pool.append(_card("Armor Break", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.UNCOMMON,
		[_damage(8), _status(StatusEffects.VULNERABLE, 1)]))

	# -- UNCOMMON SKILLS --
	pool.append(_card("Bolster", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.UNCOMMON,
		[_block(12)]))

	pool.append(_card("Dark Pact", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.UNCOMMON,
		[_draw(2), _passion(-5)]))

	pool.append(_card("Inner Fire", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.UNCOMMON,
		[_block(6), _passion(5)]))

	pool.append(_card("Weaken", 1, CardData.CardType.SKILL,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.UNCOMMON,
		[_status(StatusEffects.WEAK, 2)]))

	# -- RARE ATTACKS --
	pool.append(_card("Wildfire", 2, CardData.CardType.ATTACK,
		CardData.TargetType.ALL_ENEMIES, CardData.CardRarity.RARE,
		[_damage(14)]))

	pool.append(_card("Execute", 2, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.RARE,
		[_damage(8, 3)]))

	# -- RARE SKILLS --
	pool.append(_card("Second Wind", 0, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.RARE,
		[_energy(2), _draw(2)]))

	pool.append(_card("Phantom Guard", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.RARE,
		[_block(16), _draw(1)], true))

	return pool


# ============================================================
# EMO HYBRID CASTER — PRIMARY (MAGIC) POOL
# Swingy, exhaust-for-power, DoT, multi-hit
# ============================================================

static func build_emo_primary_pool() -> Array[CardData]:
	var pool: Array[CardData] = []

	# -- COMMON --
	pool.append(_pcard("Soul Flare", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.COMMON,
		CardData.PersonalityType.PRIMARY,
		[_damage(4, 2), _passion(3)]))

	pool.append(_pcard("Arcane Bolt", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.COMMON,
		CardData.PersonalityType.PRIMARY,
		[_damage(9)]))

	pool.append(_pcard("Spirit Ward", 1, CardData.CardType.SKILL,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.COMMON,
		CardData.PersonalityType.PRIMARY,
		[_status(StatusEffects.WEAK, 1), _passion(3)]))

	# -- UNCOMMON --
	pool.append(_pcard("Blazing Lance", 2, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.UNCOMMON,
		CardData.PersonalityType.PRIMARY,
		[_damage(16), _passion(5)]))

	pool.append(_pcard("Hex", 1, CardData.CardType.SKILL,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.UNCOMMON,
		CardData.PersonalityType.PRIMARY,
		[_status(StatusEffects.VULNERABLE, 2), _passion(3)]))

	pool.append(_pcard("Nether Flames", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.UNCOMMON,
		CardData.PersonalityType.PRIMARY,
		[_damage(3), _status(StatusEffects.POISON, 5)]))

	# -- RARE --
	pool.append(_pcard("Soul Sacrifice", 0, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.RARE,
		CardData.PersonalityType.PRIMARY,
		[_draw(3), _passion(-5)], true))

	pool.append(_pcard("Cataclysm", 2, CardData.CardType.ATTACK,
		CardData.TargetType.ALL_ENEMIES, CardData.CardRarity.RARE,
		CardData.PersonalityType.PRIMARY,
		[_damage(12), _passion(5)], true))

	return pool


# ============================================================
# EMO HYBRID CASTER — SECONDARY (PHYSICAL) POOL
# Consistent block/damage
# ============================================================

static func build_emo_secondary_pool() -> Array[CardData]:
	var pool: Array[CardData] = []

	# -- COMMON --
	pool.append(_pcard("Power Slash", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.COMMON,
		CardData.PersonalityType.SECONDARY,
		[_damage(7), _block(3)]))

	pool.append(_pcard("Brace", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.COMMON,
		CardData.PersonalityType.SECONDARY,
		[_block(9)]))

	pool.append(_pcard("Quick Jab", 0, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.COMMON,
		CardData.PersonalityType.SECONDARY,
		[_damage(4)]))

	# -- UNCOMMON --
	pool.append(_pcard("Rampage", 2, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.UNCOMMON,
		CardData.PersonalityType.SECONDARY,
		[_damage(7, 2)]))

	pool.append(_pcard("Iron Curtain", 2, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.UNCOMMON,
		CardData.PersonalityType.SECONDARY,
		[_block(16), _passion(-3)]))

	pool.append(_pcard("Riposte", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.UNCOMMON,
		CardData.PersonalityType.SECONDARY,
		[_block(6), _status_self(StatusEffects.STRENGTH, 1)]))

	# -- RARE --
	pool.append(_pcard("Devastating Blow", 3, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, CardData.CardRarity.RARE,
		CardData.PersonalityType.SECONDARY,
		[_damage(28)]))

	pool.append(_pcard("Bulwark", 2, CardData.CardType.SKILL,
		CardData.TargetType.SELF, CardData.CardRarity.RARE,
		CardData.PersonalityType.SECONDARY,
		[_block(20), _draw(1)]))

	return pool


# -- Factory helpers --

static func _card(card_name: String, cost: int, type: CardData.CardType,
		target: CardData.TargetType, rarity: CardData.CardRarity,
		card_effects: Array, exhaust: bool = false) -> CardData:
	var c = CardData.new()
	c.card_name = card_name
	c.energy_cost = cost
	c.card_type = type
	c.target_type = target
	c.rarity = rarity
	c.exhaust = exhaust
	for e in card_effects:
		c.effects.append(e)
	return c


## Card factory with personality type.
static func _pcard(card_name: String, cost: int, type: CardData.CardType,
		target: CardData.TargetType, rarity: CardData.CardRarity,
		pers: CardData.PersonalityType,
		card_effects: Array, exhaust: bool = false) -> CardData:
	var c = _card(card_name, cost, type, target, rarity, card_effects, exhaust)
	c.personality = pers
	return c


static func _damage(amount: int, hit_count: int = 1) -> DamageEffect:
	var e = DamageEffect.new()
	e.value = amount
	e.hits = hit_count
	return e


static func _block(amount: int) -> BlockEffect:
	var e = BlockEffect.new()
	e.value = amount
	return e


static func _status(effect: StatusEffectData, stacks: int) -> StatusApplyEffect:
	var e = StatusApplyEffect.new()
	e.status_effect = effect
	e.value = stacks
	return e


static func _status_self(effect: StatusEffectData, stacks: int) -> StatusApplyEffect:
	var e = StatusApplyEffect.new()
	e.status_effect = effect
	e.value = stacks
	e.apply_to_source = true
	return e


static func _draw(amount: int) -> DrawEffect:
	var e = DrawEffect.new()
	e.value = amount
	return e


static func _passion(amount: int) -> PassionEffect:
	var e = PassionEffect.new()
	e.value = amount
	return e


static func _energy(amount: int) -> EnergyEffect:
	var e = EnergyEffect.new()
	e.value = amount
	return e
