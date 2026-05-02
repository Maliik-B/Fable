class_name CharacterData
extends Resource
## Defines a playable character: personalities, passion behavior, and card pools.

@export var character_name: String = ""
@export_multiline var description: String = ""
@export var max_health: int = 80

# Passion configuration
@export var passion_volatility: float = 1.0 # Multiplier for all passion changes
## Breakpoints between tiers: [blazing_min, inspired_min, steady_min, wavering_min]
## Values below wavering_min are Hollow.
@export var passion_thresholds: Array[int] = [80, 60, 40, 20]

# Personality descriptions
@export var primary_personality: String = "" # e.g. "Magic"
@export var secondary_personality: String = "" # e.g. "Physical"

# Card pools
@export var starting_deck: Array[CardData] = []
@export var primary_cards: Array[CardData] = [] # Cards offered at high passion
@export var secondary_cards: Array[CardData] = [] # Cards offered at low passion

# Art
@export var portrait: Texture2D
@export var sprite: Texture2D
