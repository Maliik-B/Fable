class_name StatusEffects
## Static registry of all known status effects.
## Access via StatusEffects.VULNERABLE, StatusEffects.WEAK, etc.

static var VULNERABLE: StatusEffectData
static var WEAK: StatusEffectData
static var STRENGTH: StatusEffectData
static var POISON: StatusEffectData
static var DEXTERITY: StatusEffectData


static func _static_init() -> void:
	VULNERABLE = _make("Vulnerable", "Take 50% more attack damage.", false,
		StatusEffectData.StackType.INTENSITY)
	WEAK = _make("Weak", "Deal 25% less attack damage.", false,
		StatusEffectData.StackType.INTENSITY)
	STRENGTH = _make("Strength", "Deal additional damage equal to stacks.", true,
		StatusEffectData.StackType.INTENSITY)
	POISON = _make("Poison", "At start of turn, lose HP equal to stacks. Reduce by 1.", false,
		StatusEffectData.StackType.INTENSITY)
	DEXTERITY = _make("Dexterity", "Gain additional block equal to stacks.", true,
		StatusEffectData.StackType.INTENSITY)


static func _make(n: String, desc: String, buff: bool,
		stack: StatusEffectData.StackType) -> StatusEffectData:
	var s = StatusEffectData.new()
	s.effect_name = n
	s.description = desc
	s.is_buff = buff
	s.stack_type = stack
	return s
