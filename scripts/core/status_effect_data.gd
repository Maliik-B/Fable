class_name StatusEffectData
extends Resource
## Defines a status effect (buff or debuff). Used in combat and realm modifiers.

enum DurationType { TURN_BASED, PERMANENT, COMBAT_ONLY, REALM }
enum StackType { INTENSITY, DURATION, NONE }
enum TriggerTiming {
	START_OF_TURN,
	END_OF_TURN,
	ON_DAMAGE_DEALT,
	ON_DAMAGE_TAKEN,
	ON_CARD_PLAYED,
	PASSIVE,
}

@export var effect_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var is_buff: bool = true
@export var duration_type: DurationType = DurationType.TURN_BASED
@export var stack_type: StackType = StackType.INTENSITY
@export var trigger_timing: TriggerTiming = TriggerTiming.PASSIVE
