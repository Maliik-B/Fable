class_name MapNode
extends RefCounted
## A single node on the act map. Holds type, position, and connections.

enum NodeType { COMBAT, ELITE, REST, SHOP, EVENT, MYSTERY, BOSS }

var id: int = 0
var floor_num: int = 0
var column: int = 0
var node_type: NodeType = NodeType.COMBAT
var next_nodes: Array[int] = [] # IDs of connected nodes on the next floor
var visited: bool = false


static func type_label(t: NodeType) -> String:
	match t:
		NodeType.COMBAT: return "C"
		NodeType.ELITE: return "E"
		NodeType.REST: return "R"
		NodeType.SHOP: return "$"
		NodeType.EVENT: return "!"
		NodeType.MYSTERY: return "?"
		NodeType.BOSS: return "B"
	return "?"


static func type_name(t: NodeType) -> String:
	match t:
		NodeType.COMBAT: return "Combat"
		NodeType.ELITE: return "Elite"
		NodeType.REST: return "Rest"
		NodeType.SHOP: return "Shop"
		NodeType.EVENT: return "Event"
		NodeType.MYSTERY: return "Mystery"
		NodeType.BOSS: return "Boss"
	return "???"


static func type_color(t: NodeType) -> Color:
	match t:
		NodeType.COMBAT: return Color(0.8, 0.3, 0.3)
		NodeType.ELITE: return Color(0.95, 0.65, 0.1)
		NodeType.REST: return Color(0.3, 0.8, 0.4)
		NodeType.SHOP: return Color(0.3, 0.7, 0.9)
		NodeType.EVENT: return Color(0.7, 0.5, 0.8)
		NodeType.MYSTERY: return Color(0.55, 0.55, 0.55)
		NodeType.BOSS: return Color(0.95, 0.15, 0.15)
	return Color.WHITE
