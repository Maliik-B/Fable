class_name PerkData
extends Resource
## Defines a perk: picked 1 of 3 at the start of each act.

@export var perk_name: String = ""
@export_multiline var description: String = ""
@export var is_universal: bool = true # false = character-specific
@export var icon: Texture2D
