class_name EnemyData
extends Resource
## Defines an enemy type: stats, available moves, and move selection behavior.

@export var enemy_name: String = ""
@export var max_health: int = 50
@export var moves: Array[EnemyMove] = []
@export var sprite: Texture2D
