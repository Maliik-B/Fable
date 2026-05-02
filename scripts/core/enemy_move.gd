class_name EnemyMove
extends Resource
## A single move an enemy can perform. Uses the same CardEffect system as player cards.

enum IntentType { ATTACK, DEFEND, BUFF, DEBUFF, ATTACK_DEBUFF, UNKNOWN }

@export var move_name: String = ""
@export var intent_type: IntentType = IntentType.ATTACK
@export var effects: Array[CardEffect] = []
@export var intent_icon: Texture2D
## Weight for random move selection (higher = more likely to be chosen).
@export var weight: float = 1.0
