class_name StatusApplyEffect
extends CardEffect
## Applies a status effect to the target with the given number of stacks.

@export var status_effect: StatusEffectData
@export var apply_to_source: bool = false # True = buff self, false = debuff target


func apply(source, target, battle_state) -> void:
	var recipient = source if apply_to_source else target
	battle_state.apply_status_effect(recipient, status_effect, value)


func get_description() -> String:
	if not status_effect:
		return ""
	var target_text = "Gain" if apply_to_source else "Apply"
	return "%s %d %s." % [target_text, value, status_effect.effect_name]
