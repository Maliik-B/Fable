class_name PassionState
extends Resource
## Runtime state of the Passion meter for the current run.
## Tier boundaries are defined per-character in CharacterData.

enum Tier { HOLLOW, WAVERING, STEADY, INSPIRED, BLAZING }

@export var current_value: int = 60
@export var min_value: int = 0
@export var max_value: int = 100
@export var starting_value: int = 60


static func tier_name(tier: Tier) -> String:
	match tier:
		Tier.BLAZING: return "Blazing"
		Tier.INSPIRED: return "Inspired"
		Tier.STEADY: return "Steady"
		Tier.WAVERING: return "Wavering"
		Tier.HOLLOW: return "Hollow"
	return "Unknown"
