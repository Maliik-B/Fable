class_name EquipmentData
extends Resource
## Defines a piece of equipment: swappable gear with consistent effects.

enum EquipmentSlot { HEAD, ARMS, TORSO, LEGS }

@export var equipment_name: String = ""
@export_multiline var description: String = ""
@export var slot: EquipmentSlot = EquipmentSlot.TORSO
@export var icon: Texture2D
