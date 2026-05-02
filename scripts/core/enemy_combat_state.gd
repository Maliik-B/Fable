class_name EnemyCombatState
extends RefCounted
## Runtime state for a single enemy during combat.

var enemy_data: EnemyData
var stats: CombatantStats
var current_intent: EnemyMove


func _init(data: EnemyData) -> void:
	enemy_data = data
	stats = CombatantStats.new(data.max_health)


## Picks a move using weighted random selection from the enemy's move pool.
func select_intent() -> void:
	if enemy_data.moves.is_empty():
		current_intent = null
		return

	var total_weight := 0.0
	for move in enemy_data.moves:
		total_weight += move.weight

	var roll = RngManager.enemy_rng.randf() * total_weight
	var cumulative := 0.0
	for move in enemy_data.moves:
		cumulative += move.weight
		if roll <= cumulative:
			current_intent = move
			return

	current_intent = enemy_data.moves[0]
