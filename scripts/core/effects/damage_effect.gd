class_name DamageEffect
extends CardEffect
## Deals damage to the target. Respects block and damage modifiers (Vulnerable, Weak).

@export var hits: int = 1 # For multi-hit attacks


func apply(source, target, battle_state) -> void:
	for i in hits:
		battle_state.deal_damage(target, value, source)


func get_description() -> String:
	if hits > 1:
		return "Deal %d damage %d times." % [value, hits]
	return "Deal %d damage." % value


## Returns description with combat modifiers (Strength, Weak) shown as base [modified].
func get_modified_description(source: CombatantStats, _target: CombatantStats = null) -> String:
	var modified = value
	if source:
		modified += source.get_status_stacks(StatusEffects.STRENGTH)
		if source.has_status(StatusEffects.WEAK):
			modified = int(modified * 0.75)
	modified = maxi(0, modified)
	if modified != value:
		if hits > 1:
			return "Deal %d [%d] damage %d times." % [value, modified, hits]
		return "Deal %d [%d] damage." % [value, modified]
	return get_description()
