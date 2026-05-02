class_name MapGenerator
## Generates an STS-style branching node map for one act.
## Uses random path walks to create organic branching with guaranteed connectivity.

const FLOOR_COUNT := 15
const MAP_WIDTH := 7
const PATH_COUNT := 6


static func generate(rng: RandomNumberGenerator) -> MapData:
	var map = MapData.new()
	map.floor_count = FLOOR_COUNT

	# Phase 1: Generate random paths and collect positions + connections
	var positions: Dictionary = {} # Vector2i(floor, col) -> true
	var connections: Dictionary = {} # Vector2i -> Array of Vector2i

	for p in PATH_COUNT:
		var col = rng.randi_range(0, MAP_WIDTH - 1)

		for floor in FLOOR_COUNT:
			var pos = Vector2i(floor, col)
			positions[pos] = true

			if floor < FLOOR_COUNT - 1:
				var next_col = clampi(col + rng.randi_range(-1, 1), 0, MAP_WIDTH - 1)
				var next_pos = Vector2i(floor + 1, next_col)

				if pos not in connections:
					connections[pos] = []
				if next_pos not in connections[pos]:
					connections[pos].append(next_pos)

				col = next_col

	# Phase 2: Merge all top-floor nodes into a single boss node
	var boss_pos = Vector2i(FLOOR_COUNT - 1, MAP_WIDTH / 2)
	var top_positions: Array = []
	for pos in positions:
		if pos.x == FLOOR_COUNT - 1:
			top_positions.append(pos)
	for pos in top_positions:
		positions.erase(pos)
	positions[boss_pos] = true

	# Redirect all connections to top floor toward the boss node
	for pos in connections:
		if pos.x == FLOOR_COUNT - 2:
			var redirected: Array = []
			for target in connections[pos]:
				if target.x == FLOOR_COUNT - 1:
					if boss_pos not in redirected:
						redirected.append(boss_pos)
				else:
					redirected.append(target)
			connections[pos] = redirected

	# Phase 3: Assign stable IDs (sorted by floor then column)
	var sorted_positions = positions.keys()
	sorted_positions.sort_custom(func(a, b):
		if a.x != b.x: return a.x < b.x
		return a.y < b.y
	)

	var pos_to_id: Dictionary = {}
	var id_counter := 0
	for pos in sorted_positions:
		var node = MapNode.new()
		node.id = id_counter
		node.floor_num = pos.x
		node.column = pos.y
		map.nodes[id_counter] = node
		pos_to_id[pos] = id_counter
		id_counter += 1

	# Phase 4: Convert grid connections to node ID connections
	for pos in connections:
		if pos not in pos_to_id:
			continue
		var from_id: int = pos_to_id[pos]
		for target_pos in connections[pos]:
			if target_pos in pos_to_id:
				var to_id: int = pos_to_id[target_pos]
				if to_id not in map.nodes[from_id].next_nodes:
					map.nodes[from_id].next_nodes.append(to_id)

	# Phase 5: Record starting nodes
	for id in map.nodes:
		if map.nodes[id].floor_num == 0:
			map.starting_node_ids.append(id)

	# Phase 6: Assign node types
	_assign_types(map, rng)

	return map


static func _assign_types(map: MapData, rng: RandomNumberGenerator) -> void:
	for id in map.nodes:
		var node: MapNode = map.nodes[id]
		match node.floor_num:
			0:
				node.node_type = MapNode.NodeType.COMBAT
			5:
				node.node_type = MapNode.NodeType.REST
			9:
				node.node_type = MapNode.NodeType.SHOP
			13:
				node.node_type = MapNode.NodeType.REST
			_:
				if node.floor_num == FLOOR_COUNT - 1:
					node.node_type = MapNode.NodeType.BOSS
				elif node.floor_num <= 4:
					node.node_type = _pick_early(rng)
				elif node.floor_num <= 8:
					node.node_type = _pick_mid(rng)
				else:
					node.node_type = _pick_late(rng)


static func _pick_early(rng: RandomNumberGenerator) -> MapNode.NodeType:
	var roll = rng.randf()
	if roll < 0.55: return MapNode.NodeType.COMBAT
	if roll < 0.8: return MapNode.NodeType.EVENT
	return MapNode.NodeType.MYSTERY


static func _pick_mid(rng: RandomNumberGenerator) -> MapNode.NodeType:
	var roll = rng.randf()
	if roll < 0.3: return MapNode.NodeType.COMBAT
	if roll < 0.5: return MapNode.NodeType.ELITE
	if roll < 0.7: return MapNode.NodeType.EVENT
	if roll < 0.85: return MapNode.NodeType.MYSTERY
	return MapNode.NodeType.REST


static func _pick_late(rng: RandomNumberGenerator) -> MapNode.NodeType:
	var roll = rng.randf()
	if roll < 0.25: return MapNode.NodeType.COMBAT
	if roll < 0.5: return MapNode.NodeType.ELITE
	if roll < 0.7: return MapNode.NodeType.EVENT
	return MapNode.NodeType.MYSTERY
