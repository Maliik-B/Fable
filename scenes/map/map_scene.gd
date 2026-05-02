extends Control
## STS-style branching node map. Displays the map, handles node selection,
## and transitions to combat/rest/etc based on node type.

# Layout
const NODE_SPACING_X := 130
const NODE_SPACING_Y := 90
const MAP_MARGIN_X := 80
const MAP_MARGIN_Y := 60
const NODE_SIZE := 50

# UI references
var scroll_container: ScrollContainer
var map_canvas: Control
var node_buttons: Dictionary = {} # node_id -> Button
var hp_label: Label
var gold_label: Label
var passion_label: Label
var relic_btn: Button
var deck_btn: Button
var timer_label: Label
var info_label: Label
var popup_overlay: PanelContainer


var _timer_accum := 0.0

func _ready() -> void:
	if not RunManager.run_active:
		var character = _create_test_character()
		RunManager.start_run(character)

	if not RunManager.current_map:
		RunManager.current_map = MapGenerator.generate(RngManager.map_rng)

	_build_ui()
	_create_map_display()
	_update_node_states()
	_update_bottom_bar()
	_scroll_to_player.call_deferred()
	AudioManager.play_music("map")


func _process(delta: float) -> void:
	_timer_accum += delta
	if _timer_accum >= 1.0:
		_timer_accum -= 1.0
		timer_label.text = RunManager.get_run_time_string()


# ============================================================
# UI CONSTRUCTION
# ============================================================

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	add_child(margin)
	margin.add_child(vbox)

	# Title
	var boss_names = {1: "Realm Guardian", 2: "Hollow Warden", 3: "Fable's End"}
	var boss_name = boss_names.get(RunManager.current_act, "???")
	var title = Label.new()
	title.text = "Act %d  —  %s" % [RunManager.current_act, boss_name]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	vbox.add_child(title)

	# Info label (shows node info on hover)
	info_label = Label.new()
	info_label.text = "Choose your path"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info_label)

	# Scroll container for the map
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll_container)

	# Map canvas — holds lines and node buttons
	var map = RunManager.current_map
	var canvas_w = MAP_MARGIN_X * 2 + (MapGenerator.MAP_WIDTH - 1) * NODE_SPACING_X + NODE_SIZE
	var canvas_h = MAP_MARGIN_Y * 2 + (map.floor_count - 1) * NODE_SPACING_Y + NODE_SIZE

	map_canvas = Control.new()
	map_canvas.custom_minimum_size = Vector2(canvas_w, canvas_h)
	scroll_container.add_child(map_canvas)

	# Bottom bar
	_build_bottom_bar(vbox)


func _build_bottom_bar(parent: VBoxContainer) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	style.set_corner_radius_all(6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var bar = HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 30)
	panel.add_child(bar)

	hp_label = Label.new()
	hp_label.add_theme_font_size_override("font_size", 22)
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	bar.add_child(hp_label)

	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 22)
	gold_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	bar.add_child(gold_label)

	passion_label = Label.new()
	passion_label.add_theme_font_size_override("font_size", 22)
	passion_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.2))
	bar.add_child(passion_label)

	relic_btn = Button.new()
	relic_btn.flat = true
	relic_btn.add_theme_font_size_override("font_size", 20)
	relic_btn.add_theme_color_override("font_color", Color(0.7, 0.6, 0.8))
	relic_btn.add_theme_color_override("font_hover_color", Color(0.85, 0.75, 0.95))
	relic_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	relic_btn.pressed.connect(_on_relics_clicked)
	bar.add_child(relic_btn)

	deck_btn = Button.new()
	deck_btn.flat = true
	deck_btn.add_theme_font_size_override("font_size", 20)
	deck_btn.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	deck_btn.add_theme_color_override("font_hover_color", Color(0.65, 0.85, 1.0))
	deck_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	deck_btn.pressed.connect(_on_deck_clicked)
	bar.add_child(deck_btn)

	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	bar.add_child(timer_label)


func _update_bottom_bar() -> void:
	hp_label.text = "HP: %d / %d" % [RunManager.current_hp, RunManager.max_hp]
	gold_label.text = "Gold: %d" % RunManager.gold
	if RunManager.passion:
		var tier = RunManager.get_passion_tier()
		passion_label.text = "Passion: %d (%s)" % [
			RunManager.passion.current_value, PassionState.tier_name(tier)]

	relic_btn.text = "Relics: %d" % RunManager.relics.size()
	deck_btn.text = "Deck: %d" % RunManager.current_deck.size()
	timer_label.text = RunManager.get_run_time_string()


# ============================================================
# RELIC & DECK POPUPS
# ============================================================

func _on_relics_clicked() -> void:
	if popup_overlay:
		popup_overlay.queue_free()
		popup_overlay = null
		return
	_show_relic_popup()


func _on_deck_clicked() -> void:
	if popup_overlay:
		popup_overlay.queue_free()
		popup_overlay = null
		return
	_show_deck_popup()


func _show_relic_popup() -> void:
	popup_overlay = _create_popup_panel("Relics (%d)" % RunManager.relics.size())
	var content: VBoxContainer = popup_overlay.get_meta("content")

	if RunManager.relics.size() == 0:
		var empty = Label.new()
		empty.text = "No relics yet"
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		content.add_child(empty)
	else:
		var flow = HBoxContainer.new()
		flow.add_theme_constant_override("separation", 12)
		content.add_child(flow)
		var col_count := 0
		var current_row: HBoxContainer = flow

		for relic in RunManager.relics:
			if col_count >= 3:
				current_row = HBoxContainer.new()
				current_row.add_theme_constant_override("separation", 12)
				content.add_child(current_row)
				col_count = 0

			var rarity_colors = {
				RelicData.RelicRarity.COMMON: Color(0.6, 0.6, 0.6),
				RelicData.RelicRarity.UNCOMMON: Color(0.3, 0.7, 0.9),
				RelicData.RelicRarity.RARE: Color(0.95, 0.8, 0.2),
				RelicData.RelicRarity.BOSS: Color(0.9, 0.3, 0.3),
			}
			var color = rarity_colors.get(relic.rarity, Color(0.6, 0.6, 0.6))

			var relic_panel = PanelContainer.new()
			relic_panel.custom_minimum_size = Vector2(200, 80)
			var rs = StyleBoxFlat.new()
			rs.bg_color = Color(0.12, 0.1, 0.14)
			rs.set_corner_radius_all(6)
			rs.set_border_width_all(2)
			rs.border_color = color
			rs.content_margin_left = 10
			rs.content_margin_right = 10
			rs.content_margin_top = 8
			rs.content_margin_bottom = 8
			relic_panel.add_theme_stylebox_override("panel", rs)

			var rvbox = VBoxContainer.new()
			relic_panel.add_child(rvbox)
			var rname = Label.new()
			rname.text = relic.relic_name
			rname.add_theme_font_size_override("font_size", 16)
			rname.add_theme_color_override("font_color", color)
			rvbox.add_child(rname)
			var rdesc = Label.new()
			rdesc.text = relic.description
			rdesc.add_theme_font_size_override("font_size", 13)
			rdesc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			rdesc.autowrap_mode = TextServer.AUTOWRAP_WORD
			rvbox.add_child(rdesc)

			current_row.add_child(relic_panel)
			col_count += 1

	add_child(popup_overlay)


func _show_deck_popup() -> void:
	popup_overlay = _create_popup_panel("Deck (%d cards)" % RunManager.current_deck.size())
	var content: VBoxContainer = popup_overlay.get_meta("content")

	for card in RunManager.current_deck:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		content.add_child(row)

		var cost_lbl = Label.new()
		cost_lbl.text = "[%d]" % card.energy_cost
		cost_lbl.add_theme_font_size_override("font_size", 16)
		cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.3))
		cost_lbl.custom_minimum_size.x = 30
		row.add_child(cost_lbl)

		var name_lbl = Label.new()
		name_lbl.text = card.card_name
		name_lbl.add_theme_font_size_override("font_size", 16)
		var type_colors = [Color(0.9, 0.5, 0.5), Color(0.5, 0.7, 0.9), Color(0.9, 0.8, 0.3)]
		name_lbl.add_theme_color_override("font_color", type_colors[card.card_type])
		name_lbl.custom_minimum_size.x = 140
		row.add_child(name_lbl)

		var rarity_names = ["Starter", "Common", "Uncommon", "Rare"]
		var rarity_colors = [Color(0.4, 0.4, 0.4), Color(0.5, 0.5, 0.5), Color(0.3, 0.6, 0.8), Color(0.8, 0.7, 0.2)]
		var rarity_lbl = Label.new()
		rarity_lbl.text = rarity_names[card.rarity]
		rarity_lbl.add_theme_font_size_override("font_size", 13)
		rarity_lbl.add_theme_color_override("font_color", rarity_colors[card.rarity])
		rarity_lbl.custom_minimum_size.x = 80
		row.add_child(rarity_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = card.get_generated_description()
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		row.add_child(desc_lbl)

	add_child(popup_overlay)


func _create_popup_panel(title: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08, 0.96)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		if popup_overlay:
			popup_overlay.queue_free()
			popup_overlay = null)
	header.add_child(close_btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)

	panel.set_meta("content", content)
	return panel


# ============================================================
# MAP DISPLAY
# ============================================================

func _get_node_center(node: MapNode) -> Vector2:
	# Floor 0 at bottom, boss at top
	var map = RunManager.current_map
	var x = MAP_MARGIN_X + node.column * NODE_SPACING_X + NODE_SIZE / 2.0
	var y = MAP_MARGIN_Y + (map.floor_count - 1 - node.floor_num) * NODE_SPACING_Y + NODE_SIZE / 2.0
	return Vector2(x, y)


func _create_map_display() -> void:
	var map = RunManager.current_map

	# Draw connection lines first (behind nodes)
	for id in map.nodes:
		var node: MapNode = map.nodes[id]
		var from_pos = _get_node_center(node)
		for next_id in node.next_nodes:
			var next_node = map.get_node(next_id)
			if next_node:
				var to_pos = _get_node_center(next_node)
				var line = Line2D.new()
				line.add_point(from_pos)
				line.add_point(to_pos)
				line.width = 2.0
				line.default_color = Color(0.3, 0.3, 0.4, 0.6)
				map_canvas.add_child(line)

	# Create node buttons
	for id in map.nodes:
		var node: MapNode = map.nodes[id]
		var btn = _create_node_button(node)
		var center = _get_node_center(node)
		btn.position = center - Vector2(NODE_SIZE / 2.0, NODE_SIZE / 2.0)
		map_canvas.add_child(btn)
		node_buttons[id] = btn


func _create_node_button(node: MapNode) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
	btn.size = Vector2(NODE_SIZE, NODE_SIZE)
	btn.text = MapNode.type_label(node.node_type)
	btn.add_theme_font_size_override("font_size", 20)

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(NODE_SIZE / 2)
	style.set_border_width_all(3)
	style.bg_color = MapNode.type_color(node.node_type).darkened(0.5)
	style.border_color = MapNode.type_color(node.node_type)

	var hover_style = style.duplicate()
	hover_style.bg_color = MapNode.type_color(node.node_type).darkened(0.3)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = MapNode.type_color(node.node_type).darkened(0.6)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("disabled", style.duplicate())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	btn.pressed.connect(_on_node_clicked.bind(node))
	btn.mouse_entered.connect(_on_node_hover.bind(node))
	btn.mouse_exited.connect(_on_node_unhover)

	return btn


# ============================================================
# NODE STATES & INTERACTION
# ============================================================

func _update_node_states() -> void:
	var map = RunManager.current_map
	var available = map.get_available_next_ids()

	for id in node_buttons:
		var btn: Button = node_buttons[id]
		var node: MapNode = map.get_node(id)

		if id in available:
			btn.modulate = Color.WHITE
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		elif node.visited:
			btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			btn.modulate = Color(0.3, 0.3, 0.3, 0.5)
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_node_clicked(node: MapNode) -> void:
	var available = RunManager.current_map.get_available_next_ids()
	if node.id not in available:
		return
	AudioManager.play_sfx("button_click")
	_enter_node(node)


func _on_node_hover(node: MapNode) -> void:
	info_label.text = "%s (Floor %d)" % [MapNode.type_name(node.node_type), node.floor_num + 1]


func _on_node_unhover() -> void:
	info_label.text = "Choose your path"


func _enter_node(node: MapNode) -> void:
	RunManager.current_map.move_to(node.id)
	_update_node_states()

	match node.node_type:
		MapNode.NodeType.COMBAT:
			_start_combat(_combat_encounter(node.floor_num), 10 + node.floor_num * 2)
		MapNode.NodeType.ELITE:
			_start_combat(_elite_encounter(), 25 + node.floor_num * 2, true, false)
		MapNode.NodeType.BOSS:
			RunManager.pending_act_complete = true
			_start_combat(_boss_encounter(), 50 + node.floor_num * 2, true, true)
		MapNode.NodeType.REST:
			get_tree().change_scene_to_file("res://scenes/rest/rest_scene.tscn")
		MapNode.NodeType.MYSTERY:
			_handle_mystery(node)
		MapNode.NodeType.SHOP:
			get_tree().change_scene_to_file("res://scenes/shop/shop_scene.tscn")
		MapNode.NodeType.EVENT:
			get_tree().change_scene_to_file("res://scenes/event/event_scene.tscn")


func _start_combat(enemies: Array[EnemyData], gold_reward: int = 0,
		relic_reward: bool = false, is_boss: bool = false) -> void:
	RunManager.pending_enemies.clear()
	for e in enemies:
		RunManager.pending_enemies.append(e)
	RunManager.pending_gold_reward = gold_reward
	RunManager.pending_relic_reward = relic_reward
	RunManager.pending_relic_is_boss = is_boss
	get_tree().change_scene_to_file("res://scenes/combat/combat_scene.tscn")


func _handle_mystery(node: MapNode) -> void:
	var roll = RngManager.event_rng.randf()
	if roll < 0.4:
		node.node_type = MapNode.NodeType.COMBAT
	elif roll < 0.6:
		node.node_type = MapNode.NodeType.EVENT
	elif roll < 0.8:
		node.node_type = MapNode.NodeType.REST
	else:
		node.node_type = MapNode.NodeType.SHOP
	_update_node_visual(node)
	_enter_node(node)


func _update_node_visual(node: MapNode) -> void:
	var btn: Button = node_buttons.get(node.id)
	if not btn:
		return
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(NODE_SIZE / 2)
	style.set_border_width_all(3)
	style.bg_color = MapNode.type_color(node.node_type).darkened(0.5)
	style.border_color = MapNode.type_color(node.node_type)
	btn.add_theme_stylebox_override("normal", style)
	btn.text = MapNode.type_label(node.node_type)


func _scroll_to_player() -> void:
	var map = RunManager.current_map
	var target_floor := 0
	if map.current_node_id >= 0:
		target_floor = map.get_node(map.current_node_id).floor_num

	var target_y = MAP_MARGIN_Y + (map.floor_count - 1 - target_floor) * NODE_SPACING_Y
	var scroll_target = target_y - scroll_container.size.y / 2.0 + NODE_SIZE / 2.0
	scroll_container.scroll_vertical = int(maxf(0, scroll_target))


# ============================================================
# ENCOUNTER GENERATION
# ============================================================

## Returns a scaling multiplier based on the current act.
func _act_scale() -> float:
	return 1.0 + (RunManager.current_act - 1) * 0.4


func _scale_hp(base: int) -> int:
	return int(base * _act_scale())


func _scale_dmg(base: int) -> int:
	return int(base * (1.0 + (RunManager.current_act - 1) * 0.25))


func _combat_encounter(floor_num: int) -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	if floor_num <= 3:
		if RngManager.event_rng.randf() < 0.5:
			result.append(_make_slime(_scale_hp(35 + floor_num * 3)))
		else:
			result.append(_make_goblin(_scale_hp(20 + floor_num * 2)))
	elif floor_num <= 8:
		result.append(_make_slime(_scale_hp(40 + floor_num * 2)))
		result.append(_make_goblin(_scale_hp(22 + floor_num * 2)))
	else:
		result.append(_make_slime(_scale_hp(48 + floor_num)))
		result.append(_make_goblin(_scale_hp(28 + floor_num)))
	return result


func _elite_encounter() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	result.append(_make_elite())
	return result


func _boss_encounter() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	result.append(_make_boss())
	return result


# ============================================================
# ENEMY TEMPLATES
# ============================================================

func _make_slime(hp: int) -> EnemyData:
	var e = EnemyData.new()
	e.enemy_name = "Slime"
	e.max_health = hp
	var m1 = EnemyMove.new()
	m1.move_name = "Tackle"
	m1.intent_type = EnemyMove.IntentType.ATTACK
	m1.effects.assign([_fx_damage(_scale_dmg(6))])
	m1.weight = 2.0
	var m2 = EnemyMove.new()
	m2.move_name = "Harden"
	m2.intent_type = EnemyMove.IntentType.DEFEND
	m2.effects.assign([_fx_block(_scale_dmg(5))])
	m2.weight = 1.0
	var m3 = EnemyMove.new()
	m3.move_name = "Slam"
	m3.intent_type = EnemyMove.IntentType.ATTACK
	m3.effects.assign([_fx_damage(_scale_dmg(12))])
	m3.weight = 0.5
	var m4 = EnemyMove.new()
	m4.move_name = "Spit"
	m4.intent_type = EnemyMove.IntentType.DEBUFF
	m4.effects.assign([_fx_status(StatusEffects.WEAK, 1)])
	m4.weight = 1.0
	e.moves.assign([m1, m2, m3, m4])
	return e


func _make_goblin(hp: int) -> EnemyData:
	var e = EnemyData.new()
	e.enemy_name = "Goblin"
	e.max_health = hp
	var m1 = EnemyMove.new()
	m1.move_name = "Stab"
	m1.intent_type = EnemyMove.IntentType.ATTACK
	m1.effects.assign([_fx_damage(_scale_dmg(4))])
	m1.weight = 2.0
	var m2 = EnemyMove.new()
	m2.move_name = "Slash"
	m2.intent_type = EnemyMove.IntentType.ATTACK
	m2.effects.assign([_fx_damage(_scale_dmg(8))])
	m2.weight = 1.0
	var m3 = EnemyMove.new()
	m3.move_name = "Poison Dart"
	m3.intent_type = EnemyMove.IntentType.ATTACK
	m3.effects.assign([_fx_damage(_scale_dmg(2)), _fx_status(StatusEffects.POISON, 2)])
	m3.weight = 0.7
	e.moves.assign([m1, m2, m3])
	return e


func _make_elite() -> EnemyData:
	var e = EnemyData.new()
	e.enemy_name = "Orc Brute"
	e.max_health = _scale_hp(70)
	var m1 = EnemyMove.new()
	m1.move_name = "Crush"
	m1.intent_type = EnemyMove.IntentType.ATTACK
	m1.effects.assign([_fx_damage(_scale_dmg(10))])
	m1.weight = 2.0
	var m2 = EnemyMove.new()
	m2.move_name = "War Cry"
	m2.intent_type = EnemyMove.IntentType.BUFF
	m2.effects.assign([_fx_self_status(StatusEffects.STRENGTH, 2)])
	m2.weight = 1.0
	var m3 = EnemyMove.new()
	m3.move_name = "Smash"
	m3.intent_type = EnemyMove.IntentType.ATTACK
	m3.effects.assign([_fx_damage(_scale_dmg(16)), _fx_status(StatusEffects.VULNERABLE, 2)])
	m3.weight = 0.5
	e.moves.assign([m1, m2, m3])
	return e


func _make_boss() -> EnemyData:
	var act = RunManager.current_act
	var e = EnemyData.new()

	if act <= 1:
		e.enemy_name = "Realm Guardian"
		e.max_health = 120
		var m1 = EnemyMove.new()
		m1.move_name = "Sweep"
		m1.intent_type = EnemyMove.IntentType.ATTACK
		m1.effects.assign([_fx_damage(8)])
		m1.weight = 2.0
		var m2 = EnemyMove.new()
		m2.move_name = "Fortify"
		m2.intent_type = EnemyMove.IntentType.DEFEND
		m2.effects.assign([_fx_block(12), _fx_self_status(StatusEffects.STRENGTH, 1)])
		m2.weight = 1.0
		var m3 = EnemyMove.new()
		m3.move_name = "Devastate"
		m3.intent_type = EnemyMove.IntentType.ATTACK
		m3.effects.assign([_fx_damage(22)])
		m3.weight = 0.4
		var m4 = EnemyMove.new()
		m4.move_name = "Drain Spirit"
		m4.intent_type = EnemyMove.IntentType.DEBUFF
		m4.effects.assign([_fx_status(StatusEffects.WEAK, 2), _fx_status(StatusEffects.VULNERABLE, 1)])
		m4.weight = 0.8
		e.moves.assign([m1, m2, m3, m4])
	elif act == 2:
		e.enemy_name = "Hollow Warden"
		e.max_health = 180
		var m1 = EnemyMove.new()
		m1.move_name = "Soul Rend"
		m1.intent_type = EnemyMove.IntentType.ATTACK
		m1.effects.assign([_fx_damage(12)])
		m1.weight = 2.0
		var m2 = EnemyMove.new()
		m2.move_name = "Dark Barrier"
		m2.intent_type = EnemyMove.IntentType.DEFEND
		m2.effects.assign([_fx_block(18), _fx_self_status(StatusEffects.STRENGTH, 2)])
		m2.weight = 1.0
		var m3 = EnemyMove.new()
		m3.move_name = "Annihilate"
		m3.intent_type = EnemyMove.IntentType.ATTACK
		m3.effects.assign([_fx_damage(30)])
		m3.weight = 0.3
		var m4 = EnemyMove.new()
		m4.move_name = "Wither"
		m4.intent_type = EnemyMove.IntentType.DEBUFF
		m4.effects.assign([_fx_status(StatusEffects.WEAK, 2), _fx_status(StatusEffects.POISON, 4)])
		m4.weight = 0.7
		e.moves.assign([m1, m2, m3, m4])
	else:
		e.enemy_name = "Fable's End"
		e.max_health = 250
		var m1 = EnemyMove.new()
		m1.move_name = "Unravel"
		m1.intent_type = EnemyMove.IntentType.ATTACK
		m1.effects.assign([_fx_damage(15)])
		m1.weight = 2.0
		var m2 = EnemyMove.new()
		m2.move_name = "Rewrite"
		m2.intent_type = EnemyMove.IntentType.DEFEND
		m2.effects.assign([_fx_block(25), _fx_self_status(StatusEffects.STRENGTH, 3)])
		m2.weight = 0.8
		var m3 = EnemyMove.new()
		m3.move_name = "Erase"
		m3.intent_type = EnemyMove.IntentType.ATTACK
		m3.effects.assign([_fx_damage(40)])
		m3.weight = 0.25
		var m4 = EnemyMove.new()
		m4.move_name = "Silence"
		m4.intent_type = EnemyMove.IntentType.DEBUFF
		m4.effects.assign([_fx_status(StatusEffects.WEAK, 3), _fx_status(StatusEffects.VULNERABLE, 2)])
		m4.weight = 0.6
		e.moves.assign([m1, m2, m3, m4])

	return e


# -- Effect factory helpers --

func _fx_damage(v: int) -> DamageEffect:
	var e = DamageEffect.new()
	e.value = v
	return e

func _fx_block(v: int) -> BlockEffect:
	var e = BlockEffect.new()
	e.value = v
	return e

func _fx_status(effect: StatusEffectData, stacks: int) -> StatusApplyEffect:
	var e = StatusApplyEffect.new()
	e.status_effect = effect
	e.value = stacks
	return e

func _fx_self_status(effect: StatusEffectData, stacks: int) -> StatusApplyEffect:
	var e = StatusApplyEffect.new()
	e.status_effect = effect
	e.value = stacks
	e.apply_to_source = true
	return e


# ============================================================
# TEST CHARACTER (reused from combat scene)
# ============================================================

func _create_test_character() -> CharacterData:
	var c = CharacterData.new()
	c.character_name = "Emo Hybrid Caster"
	c.max_health = 80
	c.passion_volatility = 1.0
	c.passion_thresholds.assign([80, 60, 40, 20])
	c.primary_personality = "Magic"
	c.secondary_personality = "Physical"

	var strike = _make_card("Strike", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, [_fx_damage(6)])
	var defend = _make_card("Defend", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, [_fx_block(5)])
	var bash = _make_card("Bash", 2, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, [_fx_damage(8), _fx_status(StatusEffects.VULNERABLE, 2)])
	var noxious = _make_card("Noxious Strike", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, [_fx_damage(4), _fx_status(StatusEffects.POISON, 3)])
	var cleave = _make_card("Cleave", 1, CardData.CardType.ATTACK,
		CardData.TargetType.ALL_ENEMIES, [_fx_damage(4)])
	var flame = _make_card("Flame Strike", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, [_fx_damage(10), _fx_passion(-3)])
	flame.personality = CardData.PersonalityType.PRIMARY
	var meditate = _make_card("Meditate", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, [_fx_block(4), _fx_passion(3)])

	for i in 2:
		c.starting_deck.append(strike)
	for i in 2:
		c.starting_deck.append(defend)
	c.starting_deck.append(bash)
	c.starting_deck.append(noxious)
	c.starting_deck.append(cleave)
	c.starting_deck.append(flame)
	c.starting_deck.append(meditate)

	# Personality card pools for tier-based rewards
	c.primary_cards = CardPool.build_emo_primary_pool()
	c.secondary_cards = CardPool.build_emo_secondary_pool()

	return c


func _make_card(card_name: String, cost: int, type: CardData.CardType,
		target: CardData.TargetType, card_effects: Array) -> CardData:
	var c = CardData.new()
	c.card_name = card_name
	c.energy_cost = cost
	c.card_type = type
	c.target_type = target
	for e in card_effects:
		c.effects.append(e)
	return c

func _fx_passion(v: int) -> PassionEffect:
	var e = PassionEffect.new()
	e.value = v
	return e
