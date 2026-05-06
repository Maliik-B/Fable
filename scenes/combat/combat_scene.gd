extends Control
## Minimal test combat scene. Builds UI programmatically, wires into the
## Events bus, creates sample cards/enemies, and runs a full combat loop.

# -- UI references (built in _build_ui) --
var combat_engine: CombatEngine
var hand_container: HBoxContainer
var enemy_container: HBoxContainer
var hp_label: Label
var energy_label: Label
var block_label: Label
var passion_label: Label
var player_status_label: Label
var draw_label: Button
var discard_label: Button
var exhaust_label: Button
var end_turn_btn: Button
var log_text: RichTextLabel
var pile_popup: PanelContainer

# -- Interaction state --
var selected_card: CardData = null
var card_nodes: Dictionary = {} # CardData -> PanelContainer
var enemy_nodes: Dictionary = {} # EnemyCombatState -> PanelContainer


var continue_btn: Button
var _main_container: MarginContainer
var _hover_popup: PanelContainer
var _is_animating_card := false

# Sprite portrait mapping: enemy_name -> [sprite_path, region_x, region_y, region_w, region_h]
# Regions are tight crops around the actual sprite content (with padding)
const ENEMY_SPRITES = {
	"Slime": ["res://assets/sprites/enemies/monsters_main/Monsters_Creatures_Fantasy/Mushroom/Idle.png", 58, 56, 36, 52],
	"Goblin": ["res://assets/sprites/enemies/monsters_main/Monsters_Creatures_Fantasy/Goblin/Idle.png", 52, 58, 46, 50],
	"Orc Brute": ["res://assets/sprites/enemies/monsters_main/Monsters_Creatures_Fantasy/Skeleton/Idle.png", 52, 42, 62, 66],
	"Realm Guardian": ["res://assets/sprites/enemies/monsters_main/Monsters_Creatures_Fantasy/Flying eye/Flight.png", 50, 54, 56, 46],
	"Hollow Warden": ["res://assets/sprites/enemies/fire_worm/Fire Worm/Sprites/Worm/Idle.png", 12, 12, 62, 52],
	"Fable's End": ["res://assets/sprites/bosses/evil_wizard_2/EVil Wizard 2/Sprites/Idle.png", 100, 64, 72, 110],
}
# Card icon mapping: card_name -> full res:// path
const _CR = "res://assets/sprites/icons/clockwork_raven/Clockwork raven - Weapons and Potions - Free pack/individual_64x64/"
const _ITV = "res://assets/sprites/icons/in_the_void/individual/"
const _CUS = "res://assets/sprites/icons/custom/"
const CARD_ICONS = {
	# Starter attacks
	"Strike": _CR + "tile000.png",
	"Bash": _CR + "tile025.png",
	"Noxious Strike": _CUS + "noxious_strike.png",
	"Cleave": _CR + "tile004.png",
	"Flame Strike": _CUS + "flame_strike.png",
	# Generic attacks
	"Heavy Strike": _CR + "tile008.png",
	"Twin Strike": _CUS + "twin_strike.png",
	"Sweep": _CR + "tile011.png",
	"Reckless Swing": _CR + "tile035.png",
	"Carnage": _CR + "tile041.png",
	"Poison Fang": _CUS + "poison_fang.png",
	"Armor Break": _CR + "tile016.png",
	"Immolate": _CUS + "immolate.png",
	"Execute": _CR + "tile012.png",
	# Primary (Magic) attacks
	"Soul Flare": _CUS + "soul_flare.png",
	"Arcane Bolt": _CUS + "arcane_bolt.png",
	"Blazing Lance": _CR + "tile020.png",
	"Nether Flames": _CUS + "nether_flames.png",
	"Cataclysm": _CUS + "cataclysm.png",
	# Secondary (Physical) attacks
	"Power Slash": _CR + "tile006.png",
	"Quick Jab": _CR + "tile005.png",
	"Rampage": _CR + "tile050.png",
	"Devastating Blow": _CR + "tile030.png",
	# Starter skills
	"Defend": _ITV + "shield.png",
	"Meditate": _CUS + "meditate.png",
	# Generic skills
	"Iron Wave": _ITV + "gem_blue.png",
	"Shield Bash": _ITV + "gauntlet.png",
	"Battle Cry": _CUS + "battle_cry.png",
	"Fortify": _ITV + "helmet.png",
	"Dark Pact": _CUS + "dark_pact.png",
	"Inner Fire": _CUS + "inner_fire.png",
	"Weaken": _ITV + "scroll_red.png",
	"Adrenaline": _CR + "tile083.png",
	"Apparition": _CUS + "apparition.png",
	# Primary (Magic) skills
	"Spirit Ward": _CUS + "spirit_ward.png",
	"Hex": _ITV + "scroll_purple.png",
	"Soul Sacrifice": _CUS + "soul_sacrifice.png",
	# Secondary (Physical) skills
	"Brace": _ITV + "chestplate.png",
	"Iron Curtain": _CUS + "iron_curtain.png",
	"Riposte": _CR + "tile009.png",
	"Bulwark": _ITV + "shield.png",
}
var _hp_trail_bars: Dictionary = {} # ProgressBar -> trail ProgressBar
var _damage_flash: ColorRect
var _dragging_card: CardData = null
var _drag_panel: PanelContainer = null
var _drag_offset := Vector2.ZERO


func _ready() -> void:
	_build_ui()
	_connect_events()
	_start_combat()


func _unhandled_input(event: InputEvent) -> void:
	if combat_engine == null or combat_engine.phase != CombatEngine.Phase.PLAYER_TURN:
		return
	if _is_animating_card:
		return

	# Keyboard: Space/Enter to end turn
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_end_turn_pressed()
			get_viewport().set_input_as_handled()
			return
		# Number keys 1-9 to select cards
		var key_num := -1
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			key_num = event.keycode - KEY_1
		if key_num >= 0 and key_num < combat_engine.piles.hand.size():
			var card = combat_engine.piles.hand[key_num]
			_on_card_input(_make_click_event(), card)
			get_viewport().set_input_as_handled()
			return

	# Right-click to deselect card
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if selected_card:
			selected_card = null
			_update_card_highlights()
			get_viewport().set_input_as_handled()
			return
		if _dragging_card:
			_cancel_drag()
			get_viewport().set_input_as_handled()
			return

	# Drag: mouse motion while dragging
	if event is InputEventMouseMotion and _dragging_card and _drag_panel:
		_drag_panel.global_position = event.global_position - _drag_offset
		get_viewport().set_input_as_handled()
		return

	# Drag: mouse up to complete drag
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _dragging_card and _drag_panel:
			_complete_drag(event.global_position)
			get_viewport().set_input_as_handled()
			return


func _make_click_event() -> InputEventMouseButton:
	var ev = InputEventMouseButton.new()
	ev.pressed = true
	ev.button_index = MOUSE_BUTTON_LEFT
	return ev


# ============================================================
# UI CONSTRUCTION
# ============================================================

func _build_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.07, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Vignette
	var vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv) * 1.3;
	float vig = smoothstep(0.35, 1.0, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vig * 0.6);
}
"""
	mat.shader = shader
	vignette.material = mat
	add_child(vignette)

	# Damage flash overlay (hidden by default)
	_damage_flash = ColorRect.new()
	_damage_flash.color = Color(0.8, 0.05, 0.05, 0.0)
	_damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_flash.z_index = 40

	# Main layout with margins
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	_main_container = margin

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Top bar: pile counts
	vbox.add_child(_build_top_bar())

	# Enemy area
	enemy_container = HBoxContainer.new()
	enemy_container.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_container.add_theme_constant_override("separation", 40)
	enemy_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(enemy_container)

	# Player info bar
	vbox.add_child(_build_player_bar())

	# Hand + End Turn
	vbox.add_child(_build_bottom_area())

	# Combat log
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.custom_minimum_size.y = 140
	log_text.scroll_following = true
	log_text.scroll_active = true
	var log_style = StyleBoxFlat.new()
	log_style.bg_color = Color(0.08, 0.07, 0.14, 0.95)
	log_style.set_corner_radius_all(6)
	log_style.content_margin_left = 12
	log_style.content_margin_right = 12
	log_style.content_margin_top = 8
	log_style.content_margin_bottom = 8
	log_text.add_theme_stylebox_override("normal", log_style)
	vbox.add_child(log_text)

	# Add damage flash on top of everything
	add_child(_damage_flash)


func _build_top_bar() -> HBoxContainer:
	var bar = HBoxContainer.new()

	draw_label = _make_pile_button(Color(0.5, 0.7, 0.9))
	draw_label.pressed.connect(_on_pile_clicked.bind("draw"))
	bar.add_child(draw_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	exhaust_label = _make_pile_button(Color(0.6, 0.5, 0.6))
	exhaust_label.pressed.connect(_on_pile_clicked.bind("exhaust"))
	bar.add_child(exhaust_label)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size.x = 30
	bar.add_child(spacer2)

	discard_label = _make_pile_button(Color(0.7, 0.5, 0.5))
	discard_label.pressed.connect(_on_pile_clicked.bind("discard"))
	bar.add_child(discard_label)

	return bar


func _make_pile_button(color: Color) -> Button:
	var btn = Button.new()
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", color.lightened(0.3))
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _build_player_bar() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18, 0.8)
	style.set_corner_radius_all(6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var bar = HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 40)
	panel.add_child(bar)

	hp_label = _make_stat_label(Color(0.9, 0.3, 0.3))
	bar.add_child(hp_label)

	block_label = _make_stat_label(Color(0.3, 0.6, 0.9))
	bar.add_child(block_label)

	energy_label = _make_stat_label(Color(0.9, 0.9, 0.3))
	bar.add_child(energy_label)

	passion_label = _make_stat_label(Color(0.9, 0.5, 0.2))
	bar.add_child(passion_label)

	player_status_label = _make_stat_label(Color(0.8, 0.8, 0.6))
	player_status_label.add_theme_font_size_override("font_size", 18)
	bar.add_child(player_status_label)

	return panel


func _build_bottom_area() -> HBoxContainer:
	var bottom = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 20)

	hand_container = HBoxContainer.new()
	hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_container.add_theme_constant_override("separation", 10)
	hand_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hand_container)

	end_turn_btn = Button.new()
	end_turn_btn.text = "End Turn"
	end_turn_btn.custom_minimum_size = Vector2(140, 60)
	end_turn_btn.add_theme_font_size_override("font_size", 20)
	end_turn_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var et_style = StyleBoxFlat.new()
	et_style.set_corner_radius_all(10)
	et_style.set_border_width_all(2)
	et_style.bg_color = Color(0.24, 0.17, 0.08)
	et_style.border_color = Color(0.8, 0.6, 0.2)
	et_style.content_margin_left = 12
	et_style.content_margin_right = 12
	et_style.content_margin_top = 8
	et_style.content_margin_bottom = 8
	end_turn_btn.add_theme_stylebox_override("normal", et_style)

	var et_hover = et_style.duplicate()
	et_hover.bg_color = Color(0.34, 0.24, 0.08)
	et_hover.border_color = Color(1.0, 0.78, 0.25)
	end_turn_btn.add_theme_stylebox_override("hover", et_hover)

	var et_pressed = et_style.duplicate()
	et_pressed.bg_color = Color(0.16, 0.12, 0.04)
	end_turn_btn.add_theme_stylebox_override("pressed", et_pressed)

	var et_disabled = et_style.duplicate()
	et_disabled.bg_color = Color(0.12, 0.12, 0.12)
	et_disabled.border_color = Color(0.3, 0.3, 0.3)
	end_turn_btn.add_theme_stylebox_override("disabled", et_disabled)
	end_turn_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	end_turn_btn.add_theme_color_override("font_color", Color(0.9, 0.75, 0.35))
	end_turn_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.5))
	end_turn_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))

	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	bottom.add_child(end_turn_btn)

	return bottom


func _make_hp_bar(width: int, height: int) -> Control:
	# Container holds trail bar behind main bar
	var container = Control.new()
	container.custom_minimum_size = Vector2(width, height)

	var trail = ProgressBar.new()
	trail.custom_minimum_size = Vector2(width, height)
	trail.size = Vector2(width, height)
	trail.show_percentage = false
	trail.max_value = 100
	trail.value = 100
	var trail_bg = StyleBoxFlat.new()
	trail_bg.bg_color = Color(0.2, 0.08, 0.06)
	trail_bg.set_corner_radius_all(3)
	trail.add_theme_stylebox_override("background", trail_bg)
	var trail_fill = StyleBoxFlat.new()
	trail_fill.bg_color = Color(0.7, 0.15, 0.08, 0.6)
	trail_fill.set_corner_radius_all(3)
	trail.add_theme_stylebox_override("fill", trail_fill)
	container.add_child(trail)

	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, height)
	bar.size = Vector2(width, height)
	bar.show_percentage = false
	bar.max_value = 100
	bar.value = 100
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0)
	bg_style.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg_style)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.2, 0.15)
	fill_style.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill_style)
	container.add_child(bar)

	_hp_trail_bars[bar] = trail
	return container


func _make_stat_label(color: Color) -> Label:
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", color)
	return lbl


func _on_pile_clicked(pile_name: String) -> void:
	# Toggle off if already showing
	if pile_popup:
		pile_popup.queue_free()
		pile_popup = null
		return

	var cards: Array = []
	var title: String
	match pile_name:
		"draw":
			cards = combat_engine.piles.draw_pile.duplicate()
			title = "Draw Pile"
		"discard":
			cards = combat_engine.piles.discard_pile.duplicate()
			title = "Discard Pile"
		"exhaust":
			cards = combat_engine.piles.exhaust_pile.duplicate()
			title = "Exhaust Pile"

	_show_pile_popup(title, cards)


func _show_pile_popup(title: String, cards: Array) -> void:
	pile_popup = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.16, 0.95)
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = Color(0.45, 0.38, 0.6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	pile_popup.add_theme_stylebox_override("panel", style)
	pile_popup.set_anchors_preset(Control.PRESET_CENTER)
	pile_popup.custom_minimum_size = Vector2(500, 300)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	pile_popup.add_child(vbox)

	# Title row
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title_lbl = Label.new()
	title_lbl.text = "%s (%d)" % [title, cards.size()]
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_pile_popup)
	header.add_child(close_btn)

	# Card type breakdown
	var pile_type_counts := {CardData.CardType.ATTACK: 0, CardData.CardType.SKILL: 0, CardData.CardType.POWER: 0}
	for card in cards:
		pile_type_counts[card.card_type] = pile_type_counts.get(card.card_type, 0) + 1
	var pile_stats_lbl = Label.new()
	pile_stats_lbl.text = "%d Attack / %d Skill / %d Power" % [
		pile_type_counts[CardData.CardType.ATTACK],
		pile_type_counts[CardData.CardType.SKILL],
		pile_type_counts[CardData.CardType.POWER]]
	pile_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pile_stats_lbl.add_theme_font_size_override("font_size", 16)
	pile_stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(pile_stats_lbl)

	# Card list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	if cards.size() == 0:
		var empty = Label.new()
		empty.text = "(empty)"
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		list.add_child(empty)
	else:
		var grid = GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		list.add_child(grid)
		for card in cards:
			var cpanel = PanelContainer.new()
			cpanel.custom_minimum_size = Vector2(160, 100)
			var cs = StyleBoxFlat.new()
			cs.set_corner_radius_all(6)
			cs.set_border_width_all(2)
			cs.content_margin_left = 6
			cs.content_margin_right = 6
			cs.content_margin_top = 4
			cs.content_margin_bottom = 4
			match card.card_type:
				CardData.CardType.ATTACK:
					cs.bg_color = Color(0.28, 0.1, 0.08)
					cs.border_color = Color(0.8, 0.2, 0.18)
				CardData.CardType.SKILL:
					cs.bg_color = Color(0.08, 0.12, 0.28)
					cs.border_color = Color(0.2, 0.38, 0.8)
				CardData.CardType.POWER:
					cs.bg_color = Color(0.28, 0.24, 0.08)
					cs.border_color = Color(0.8, 0.65, 0.15)
			# Upgraded card green border tint
			if card.upgraded:
				cs.border_color = cs.border_color.lerp(Color(0.3, 0.9, 0.3), 0.5)
			cpanel.add_theme_stylebox_override("panel", cs)
			var cvb = VBoxContainer.new()
			cvb.add_theme_constant_override("separation", 2)
			cpanel.add_child(cvb)
			var cn = Label.new()
			cn.text = "[%d] %s" % [card.energy_cost, card.card_name]
			cn.add_theme_font_size_override("font_size", 14)
			cn.add_theme_color_override("font_color", cs.border_color.lightened(0.4))
			cvb.add_child(cn)
			var cd = Label.new()
			cd.text = card.get_generated_description()
			cd.add_theme_font_size_override("font_size", 11)
			cd.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
			cd.autowrap_mode = TextServer.AUTOWRAP_WORD
			cvb.add_child(cd)
			grid.add_child(cpanel)

	add_child(pile_popup)


func _close_pile_popup() -> void:
	if pile_popup:
		pile_popup.queue_free()
		pile_popup = null


# ============================================================
# EVENT CONNECTIONS
# ============================================================

func _connect_events() -> void:
	Events.combat_started.connect(_on_combat_started)
	Events.combat_won.connect(_on_combat_won)
	Events.combat_lost.connect(_on_combat_lost)
	Events.card_played.connect(_on_card_played)
	Events.card_exhausted.connect(_on_card_exhausted)
	Events.player_turn_started.connect(_on_player_turn_started)
	Events.enemy_turn_started.connect(_on_enemy_turn_started)
	Events.player_damaged.connect(_on_player_damaged)
	Events.enemy_damaged.connect(_on_enemy_damaged)
	Events.enemy_died.connect(_on_enemy_died)
	Events.block_gained.connect(_on_block_gained)
	Events.passion_changed.connect(_on_passion_changed)
	Events.status_applied.connect(_on_status_applied)
	Events.status_removed.connect(_on_status_removed)


# ============================================================
# COMBAT SETUP
# ============================================================

func _start_combat() -> void:
	# If no run is active, start a test run (direct scene launch for debugging)
	if not RunManager.run_active:
		var character = _create_test_character()
		RunManager.start_run(character)

	combat_engine = CombatEngine.new()
	combat_engine.name = "CombatEngine"
	add_child(combat_engine)

	# Use pending enemies from map, or fall back to test enemies
	var enemy_datas: Array[EnemyData] = []
	if RunManager.pending_enemies.size() > 0:
		enemy_datas = RunManager.pending_enemies.duplicate()
		RunManager.pending_enemies.clear()
	else:
		enemy_datas = [_create_slime(), _create_goblin()]

	combat_engine.start_combat(
		RunManager.current_deck,
		RunManager.current_hp,
		RunManager.max_hp,
		enemy_datas
	)
	_log("[color=gold]Combat begins![/color]")


func _create_test_character() -> CharacterData:
	var c = CharacterData.new()
	c.character_name = "Emo Hybrid Caster"
	c.max_health = 80
	c.passion_volatility = 1.0
	c.passion_thresholds.assign([80, 60, 40, 20])
	c.primary_personality = "Magic"
	c.secondary_personality = "Physical"

	var strike = _make_card("Strike", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, [_make_damage(6)])
	var defend = _make_card("Defend", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, [_make_block(5)])
	var bash = _make_card("Bash", 2, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, [_make_damage(8), _make_status(StatusEffects.VULNERABLE, 2)])
	var noxious = _make_card("Noxious Strike", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, [_make_damage(4), _make_status(StatusEffects.POISON, 3)])
	var flame_strike = _make_card("Flame Strike", 1, CardData.CardType.ATTACK,
		CardData.TargetType.SINGLE_ENEMY, [_make_damage(10), _make_passion(-3)])
	flame_strike.personality = CardData.PersonalityType.PRIMARY
	var meditate = _make_card("Meditate", 1, CardData.CardType.SKILL,
		CardData.TargetType.SELF, [_make_block(4), _make_passion(3)])

	for i in 2:
		c.starting_deck.append(strike)
	for i in 2:
		c.starting_deck.append(defend)
	var cleave = _make_card("Cleave", 1, CardData.CardType.ATTACK,
		CardData.TargetType.ALL_ENEMIES, [_make_damage(4)])
	c.starting_deck.append(bash)
	c.starting_deck.append(noxious)
	c.starting_deck.append(cleave)
	c.starting_deck.append(flame_strike)
	c.starting_deck.append(meditate)

	# Personality card pools for tier-based rewards
	c.primary_cards = CardPool.build_emo_primary_pool()
	c.secondary_cards = CardPool.build_emo_secondary_pool()

	return c


func _create_slime() -> EnemyData:
	var e = EnemyData.new()
	e.enemy_name = "Slime"
	e.max_health = 42

	var tackle = EnemyMove.new()
	tackle.move_name = "Tackle"
	tackle.intent_type = EnemyMove.IntentType.ATTACK
	tackle.effects.assign([_make_damage(6)])
	tackle.weight = 2.0

	var harden = EnemyMove.new()
	harden.move_name = "Harden"
	harden.intent_type = EnemyMove.IntentType.DEFEND
	harden.effects.assign([_make_block(5)])
	harden.weight = 1.0

	var slam = EnemyMove.new()
	slam.move_name = "Slam"
	slam.intent_type = EnemyMove.IntentType.ATTACK
	slam.effects.assign([_make_damage(12)])
	slam.weight = 0.5

	var spit = EnemyMove.new()
	spit.move_name = "Spit"
	spit.intent_type = EnemyMove.IntentType.DEBUFF
	spit.effects.assign([_make_status(StatusEffects.WEAK, 1)])
	spit.weight = 1.0

	e.moves.assign([tackle, harden, slam, spit])
	return e


func _create_goblin() -> EnemyData:
	var e = EnemyData.new()
	e.enemy_name = "Goblin"
	e.max_health = 26

	var stab = EnemyMove.new()
	stab.move_name = "Stab"
	stab.intent_type = EnemyMove.IntentType.ATTACK
	stab.effects.assign([_make_damage(4)])
	stab.weight = 2.0

	var slash = EnemyMove.new()
	slash.move_name = "Slash"
	slash.intent_type = EnemyMove.IntentType.ATTACK
	slash.effects.assign([_make_damage(8)])
	slash.weight = 1.0

	var poison_dart = EnemyMove.new()
	poison_dart.move_name = "Poison Dart"
	poison_dart.intent_type = EnemyMove.IntentType.ATTACK
	poison_dart.effects.assign([_make_damage(2), _make_status(StatusEffects.POISON, 2)])
	poison_dart.weight = 0.7

	e.moves.assign([stab, slash, poison_dart])
	return e


# -- Factory helpers --

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


func _make_damage(amount: int) -> DamageEffect:
	var e = DamageEffect.new()
	e.value = amount
	return e


func _make_block(amount: int) -> BlockEffect:
	var e = BlockEffect.new()
	e.value = amount
	return e


func _make_status(effect: StatusEffectData, stacks: int) -> StatusApplyEffect:
	var e = StatusApplyEffect.new()
	e.status_effect = effect
	e.value = stacks
	return e


func _make_passion(amount: int) -> PassionEffect:
	var e = PassionEffect.new()
	e.value = amount
	return e


func _get_personality_label(pers: CardData.PersonalityType) -> String:
	if RunManager.current_character:
		if pers == CardData.PersonalityType.PRIMARY:
			return RunManager.current_character.primary_personality
		if pers == CardData.PersonalityType.SECONDARY:
			return RunManager.current_character.secondary_personality
	var names = {
		CardData.PersonalityType.PRIMARY: "Primary",
		CardData.PersonalityType.SECONDARY: "Secondary",
	}
	return names.get(pers, "")


func _get_personality_color(pers: CardData.PersonalityType) -> Color:
	if pers == CardData.PersonalityType.PRIMARY:
		return Color(0.9, 0.5, 0.2) # Warm orange for magic
	if pers == CardData.PersonalityType.SECONDARY:
		return Color(0.4, 0.6, 0.9) # Cool blue for physical
	return Color(0.6, 0.6, 0.6)


# ============================================================
# CARD UI
# ============================================================

func _create_card_panel(card: CardData) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 220)

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10

	match card.card_type:
		CardData.CardType.ATTACK:
			style.bg_color = Color(0.3, 0.12, 0.1)
			style.border_color = Color(0.9, 0.25, 0.2)
		CardData.CardType.SKILL:
			style.bg_color = Color(0.1, 0.14, 0.3)
			style.border_color = Color(0.25, 0.45, 0.9)
		CardData.CardType.POWER:
			style.bg_color = Color(0.28, 0.24, 0.08)
			style.border_color = Color(0.9, 0.75, 0.15)

	# Upgraded card green border tint
	if card.upgraded:
		style.border_color = style.border_color.lerp(Color(0.3, 0.9, 0.3), 0.5)

	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Energy cost in circle ornament
	var cost_container = PanelContainer.new()
	cost_container.custom_minimum_size = Vector2(36, 36)
	var cost_style = StyleBoxFlat.new()
	cost_style.set_corner_radius_all(18)
	cost_style.bg_color = Color(0.18, 0.14, 0.06)
	cost_style.set_border_width_all(2)
	cost_style.border_color = Color(0.95, 0.8, 0.2)
	cost_style.content_margin_left = 4
	cost_style.content_margin_right = 4
	cost_style.content_margin_top = 2
	cost_style.content_margin_bottom = 2
	cost_container.add_theme_stylebox_override("panel", cost_style)
	var cost_lbl = Label.new()
	cost_lbl.text = str(card.energy_cost)
	cost_lbl.add_theme_font_size_override("font_size", 22)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.3))
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_container.add_child(cost_lbl)
	vbox.add_child(cost_container)

	# Card name
	var name_lbl = Label.new()
	name_lbl.text = card.card_name
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Type + Rarity
	var type_names = ["Attack", "Skill", "Power"]
	var rarity_names = ["Starter", "Common", "Uncommon", "Rare"]
	var rarity_colors = [
		Color(0.5, 0.5, 0.5), Color(0.55, 0.55, 0.55),
		Color(0.3, 0.7, 0.9), Color(0.95, 0.8, 0.2),
	]
	var type_lbl = Label.new()
	type_lbl.text = "%s - %s" % [type_names[card.card_type], rarity_names[card.rarity]]
	type_lbl.add_theme_font_size_override("font_size", 12)
	type_lbl.add_theme_color_override("font_color", rarity_colors[card.rarity])
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_lbl)

	# Personality tag (Magic / Physical)
	if card.personality != CardData.PersonalityType.NEUTRAL:
		var pers_lbl = Label.new()
		pers_lbl.text = _get_personality_label(card.personality)
		pers_lbl.add_theme_font_size_override("font_size", 11)
		pers_lbl.add_theme_color_override("font_color", _get_personality_color(card.personality))
		pers_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(pers_lbl)

	# Card art area
	var art_frame = PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(0, 40)
	var art_style = StyleBoxFlat.new()
	art_style.set_corner_radius_all(4)
	art_style.content_margin_top = 4
	art_style.content_margin_bottom = 4
	match card.card_type:
		CardData.CardType.ATTACK:
			art_style.bg_color = Color(0.4, 0.1, 0.08)
			art_style.set_border_width_all(1)
			art_style.border_color = Color(0.7, 0.18, 0.1, 0.5)
		CardData.CardType.SKILL:
			art_style.bg_color = Color(0.08, 0.15, 0.35)
			art_style.set_border_width_all(1)
			art_style.border_color = Color(0.15, 0.28, 0.65, 0.5)
		CardData.CardType.POWER:
			art_style.bg_color = Color(0.35, 0.28, 0.06)
			art_style.set_border_width_all(1)
			art_style.border_color = Color(0.65, 0.5, 0.1, 0.5)
	art_frame.add_theme_stylebox_override("panel", art_style)
	var icon_file = CARD_ICONS.get(card.card_name, "")
	if icon_file != "":
		var art_icon = TextureRect.new()
		art_icon.texture = load(icon_file)
		art_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art_icon.custom_minimum_size = Vector2(36, 36)
		art_frame.add_child(art_icon)
	else:
		var art_lbl = Label.new()
		match card.card_type:
			CardData.CardType.ATTACK: art_lbl.text = "⚔"
			CardData.CardType.SKILL: art_lbl.text = "◆"
			CardData.CardType.POWER: art_lbl.text = "★"
		art_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		art_lbl.add_theme_font_size_override("font_size", 24)
		art_lbl.add_theme_color_override("font_color", style.border_color.lightened(0.3))
		art_frame.add_child(art_lbl)
	vbox.add_child(art_frame)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Description (show modified values if in combat)
	var desc_lbl = Label.new()
	if combat_engine and combat_engine.player_stats:
		desc_lbl.text = card.get_modified_description(combat_engine.player_stats)
	else:
		desc_lbl.text = card.get_generated_description()
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	# Make all children pass clicks through to the panel
	_ignore_mouse_recursive(vbox)

	# Click handler
	panel.gui_input.connect(_on_card_input.bind(card))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.pivot_offset = Vector2(80, 110)

	# Hover animation + detail popup
	panel.mouse_entered.connect(func():
		if panel.modulate != Color(0.5, 0.5, 0.5):
			var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			t.tween_property(panel, "scale", Vector2(1.08, 1.08), 0.12)
			_show_card_hover(card, panel)
	)
	panel.mouse_exited.connect(func():
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(panel, "scale", Vector2.ONE, 0.12)
		_hide_card_hover()
	)

	return panel


func _ignore_mouse_recursive(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_ignore_mouse_recursive(child)


func _on_card_input(event: InputEvent, card: CardData) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if combat_engine.phase != CombatEngine.Phase.PLAYER_TURN or _is_animating_card:
		return
	if _dragging_card:
		return

	if not combat_engine.can_play_card(card):
		_log("[color=red]Not enough energy![/color]")
		return

	selected_card = card

	match card.target_type:
		CardData.TargetType.SELF, CardData.TargetType.NONE:
			_play_selected_card(combat_engine.player_stats)
		CardData.TargetType.ALL_ENEMIES:
			_play_selected_card(null)
		CardData.TargetType.SINGLE_ENEMY:
			# Click-select + click-enemy, or drag to target
			_start_drag(card, event)
			_update_card_highlights()
			_log("Drag to target or click an enemy...")


func _play_selected_card(target: CombatantStats) -> void:
	if not selected_card or _is_animating_card:
		return
	var card = selected_card
	selected_card = null
	var panel: PanelContainer = card_nodes.get(card)
	if panel:
		_is_animating_card = true
		# Find target position
		var target_pos := Vector2(960, 300)
		if target:
			for enemy in combat_engine.enemies:
				if enemy.stats == target:
					var epanel = enemy_nodes.get(enemy)
					if epanel:
						target_pos = epanel.global_position + epanel.size / 2.0
					break
		else:
			# AoE — fly to center of enemy area
			target_pos = enemy_container.global_position + enemy_container.size / 2.0

		# Reparent card for animation
		var start_pos = panel.global_position
		panel.get_parent().remove_child(panel)
		add_child(panel)
		panel.global_position = start_pos
		panel.z_index = 30

		var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		t.set_parallel(true)
		t.tween_property(panel, "global_position", target_pos - panel.size / 2.0, 0.25)
		t.tween_property(panel, "scale", Vector2(0.5, 0.5), 0.25)
		t.tween_property(panel, "modulate:a", 0.0, 0.15).set_delay(0.15)
		t.chain().tween_callback(func():
			panel.queue_free()
			_is_animating_card = false
			combat_engine.play_card(card, target)
			_refresh_ui()
		)
	else:
		combat_engine.play_card(card, target)
		_refresh_ui()


func _update_card_highlights() -> void:
	for card in card_nodes:
		var panel: PanelContainer = card_nodes[card]
		if card == selected_card:
			panel.modulate = Color(1.4, 1.4, 1.1)
		elif not combat_engine.can_play_card(card):
			panel.modulate = Color(0.5, 0.5, 0.5)
		else:
			panel.modulate = Color.WHITE


# ============================================================
# DRAG AND DROP
# ============================================================

func _start_drag(card: CardData, event: InputEvent) -> void:
	var panel: PanelContainer = card_nodes.get(card)
	if not panel:
		return
	_dragging_card = card
	_hide_card_hover()
	var start_pos = panel.global_position
	_drag_offset = event.global_position - start_pos if event is InputEventMouseButton else panel.size / 2.0
	panel.get_parent().remove_child(panel)
	add_child(panel)
	panel.global_position = start_pos
	panel.z_index = 35
	panel.rotation_degrees = 0
	panel.modulate = Color(1.3, 1.3, 1.0, 0.9)
	_drag_panel = panel


func _complete_drag(drop_pos: Vector2) -> void:
	if not _dragging_card or not _drag_panel:
		return
	var card = _dragging_card
	var target_enemy: EnemyCombatState = null
	for enemy in combat_engine.enemies:
		if enemy.stats.is_dead():
			continue
		var epanel: PanelContainer = enemy_nodes.get(enemy)
		if epanel and Rect2(epanel.global_position, epanel.size).has_point(drop_pos):
			target_enemy = enemy
			break
	if not target_enemy and drop_pos.y < 500:
		var closest_dist := INF
		for enemy in combat_engine.enemies:
			if enemy.stats.is_dead():
				continue
			var epanel: PanelContainer = enemy_nodes.get(enemy)
			if epanel:
				var center = epanel.global_position + epanel.size / 2.0
				var dist = center.distance_to(drop_pos)
				if dist < closest_dist:
					closest_dist = dist
					target_enemy = enemy
	if target_enemy:
		_drag_panel.queue_free()
		card_nodes.erase(card)
		_dragging_card = null
		_drag_panel = null
		selected_card = card
		_play_selected_card(target_enemy.stats)
	else:
		_cancel_drag()


func _cancel_drag() -> void:
	if _drag_panel:
		_drag_panel.queue_free()
	_dragging_card = null
	_drag_panel = null
	_refresh_ui()


# ============================================================
# ENEMY UI
# ============================================================

func _create_enemy_panel(enemy: EnemyCombatState) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 220)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.25)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.5, 0.4, 0.5)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Enemy portrait area — sprite from spritesheet
	var sprite_info = ENEMY_SPRITES.get(enemy.enemy_data.enemy_name)
	if sprite_info:
		var sheet: Texture2D = load(sprite_info[0])
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(sprite_info[1], sprite_info[2], sprite_info[3], sprite_info[4])
		var portrait = TextureRect.new()
		portrait.texture = atlas
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.custom_minimum_size = Vector2(120, 120)
		vbox.add_child(portrait)
	else:
		# Fallback for unknown enemies
		var portrait = PanelContainer.new()
		portrait.custom_minimum_size = Vector2(0, 70)
		var port_style = StyleBoxFlat.new()
		port_style.set_corner_radius_all(6)
		port_style.bg_color = Color(0.22, 0.17, 0.28)
		portrait.add_theme_stylebox_override("panel", port_style)
		var port_icon = Label.new()
		port_icon.text = "?"
		port_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		port_icon.add_theme_font_size_override("font_size", 36)
		portrait.add_child(port_icon)
		vbox.add_child(portrait)

	var name_lbl = Label.new()
	name_lbl.text = enemy.enemy_data.enemy_name
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# --- HP section (own panel) ---
	var hp_panel = PanelContainer.new()
	hp_panel.name = "HPPanel"
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.14, 0.06, 0.06, 0.8)
	hp_style.set_corner_radius_all(5)
	hp_style.set_border_width_all(1)
	hp_style.border_color = Color(0.4, 0.15, 0.15)
	hp_style.content_margin_left = 8
	hp_style.content_margin_right = 8
	hp_style.content_margin_top = 4
	hp_style.content_margin_bottom = 4
	hp_panel.add_theme_stylebox_override("panel", hp_style)
	vbox.add_child(hp_panel)

	var hp_vbox = VBoxContainer.new()
	hp_vbox.add_theme_constant_override("separation", 8)
	hp_panel.add_child(hp_vbox)

	var hp_bar_container = _make_hp_bar(180, 20)
	hp_bar_container.name = "HPBarContainer"
	var enemy_hp_bar: ProgressBar = hp_bar_container.get_child(1)
	enemy_hp_bar.name = "HPBar"
	enemy_hp_bar.max_value = enemy.enemy_data.max_health
	enemy_hp_bar.value = enemy.stats.current_hp
	var enemy_trail: ProgressBar = hp_bar_container.get_child(0)
	enemy_trail.max_value = enemy.enemy_data.max_health
	enemy_trail.value = enemy.stats.current_hp
	# HP text overlaid inside the bar
	var hp_lbl = Label.new()
	hp_lbl.name = "HP"
	hp_lbl.add_theme_font_size_override("font_size", 14)
	hp_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	hp_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hp_lbl.add_theme_constant_override("shadow_offset_x", 1)
	hp_lbl.add_theme_constant_override("shadow_offset_y", 1)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_container.add_child(hp_lbl)
	hp_vbox.add_child(hp_bar_container)

	var block_lbl = Label.new()
	block_lbl.name = "Block"
	block_lbl.add_theme_font_size_override("font_size", 16)
	block_lbl.add_theme_color_override("font_color", Color(0.3, 0.6, 0.9))
	block_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_vbox.add_child(block_lbl)

	var status_lbl = Label.new()
	status_lbl.name = "Statuses"
	status_lbl.add_theme_font_size_override("font_size", 13)
	status_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	hp_vbox.add_child(status_lbl)

	# Spacer between HP and intent
	var hp_intent_spacer = Control.new()
	hp_intent_spacer.custom_minimum_size.y = 12
	vbox.add_child(hp_intent_spacer)

	# --- Intent section (own panel) ---
	var intent_panel = PanelContainer.new()
	intent_panel.name = "IntentPanel"
	var intent_style = StyleBoxFlat.new()
	intent_style.bg_color = Color(0.1, 0.08, 0.16, 0.8)
	intent_style.set_corner_radius_all(5)
	intent_style.set_border_width_all(1)
	intent_style.border_color = Color(0.35, 0.28, 0.5)
	intent_style.content_margin_left = 8
	intent_style.content_margin_right = 8
	intent_style.content_margin_top = 5
	intent_style.content_margin_bottom = 5
	intent_panel.add_theme_stylebox_override("panel", intent_style)
	vbox.add_child(intent_panel)

	var intent_lbl = Label.new()
	intent_lbl.name = "Intent"
	intent_lbl.add_theme_font_size_override("font_size", 16)
	intent_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	intent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_panel.add_child(intent_lbl)

	# Click to target
	panel.gui_input.connect(_on_enemy_input.bind(enemy))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	return panel


func _on_enemy_input(event: InputEvent, enemy: EnemyCombatState) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if enemy.stats.is_dead():
		return
	# Complete drag onto enemy
	if _dragging_card and _drag_panel:
		var card = _dragging_card
		_drag_panel.queue_free()
		card_nodes.erase(card)
		_dragging_card = null
		_drag_panel = null
		selected_card = card
		_play_selected_card(enemy.stats)
		return
	if selected_card:
		_play_selected_card(enemy.stats)


func _update_enemy_panel(enemy: EnemyCombatState) -> void:
	var panel: PanelContainer = enemy_nodes.get(enemy)
	if not panel:
		return

	var vbox = panel.get_child(0)
	var hp_panel: PanelContainer = vbox.get_node("HPPanel")
	var hp_vbox = hp_panel.get_child(0)
	var block_lbl: Label = hp_vbox.get_node("Block")
	var status_lbl: Label = hp_vbox.get_node("Statuses")
	var intent_panel: PanelContainer = vbox.get_node("IntentPanel")
	var intent_lbl: Label = intent_panel.get_node("Intent")

	var hp_container = hp_vbox.get_node_or_null("HPBarContainer")
	if hp_container:
		var hp_lbl: Label = hp_container.get_node("HP")
		hp_lbl.text = "%d / %d" % [enemy.stats.current_hp, enemy.stats.max_hp]
		var hp_bar: ProgressBar = hp_container.get_child(1)
		hp_bar.max_value = enemy.stats.max_hp
		_animate_hp_bar(hp_bar, enemy.stats.current_hp)
		var ep = float(enemy.stats.current_hp) / enemy.stats.max_hp
		var ef: StyleBoxFlat = hp_bar.get_theme_stylebox("fill")
		if ep > 0.5:
			ef.bg_color = Color(0.8, 0.2, 0.15)
		elif ep > 0.25:
			ef.bg_color = Color(0.9, 0.5, 0.1)
		else:
			ef.bg_color = Color(0.5, 0.1, 0.1)

	if enemy.stats.block > 0:
		block_lbl.text = "Block: %d" % enemy.stats.block
		block_lbl.visible = true
	else:
		block_lbl.text = ""
		block_lbl.visible = false

	status_lbl.text = _format_statuses(enemy.stats)
	status_lbl.tooltip_text = _format_status_tooltips(enemy.stats)
	status_lbl.visible = status_lbl.text != ""

	if enemy.current_intent:
		var icon := ""
		var intent_color := Color(0.95, 0.85, 0.5)
		var value_str := ""
		match enemy.current_intent.intent_type:
			EnemyMove.IntentType.ATTACK:
				icon = "⚔"
				intent_color = Color(1.0, 0.4, 0.3)
				for effect in enemy.current_intent.effects:
					if effect is DamageEffect:
						var modified = effect.value
						modified += enemy.stats.get_status_stacks(StatusEffects.STRENGTH)
						if enemy.stats.has_status(StatusEffects.WEAK):
							modified = int(modified * 0.75)
						modified = maxi(0, modified)
						if modified != effect.value:
							value_str = " %d [%d]" % [effect.value, modified]
						else:
							value_str = " %d" % effect.value
						break
			EnemyMove.IntentType.DEFEND:
				icon = "◆"
				intent_color = Color(0.3, 0.7, 1.0)
				for effect in enemy.current_intent.effects:
					if effect is BlockEffect:
						var modified = effect.value + enemy.stats.get_status_stacks(StatusEffects.DEXTERITY)
						if modified != effect.value:
							value_str = " %d [%d]" % [effect.value, modified]
						else:
							value_str = " %d" % effect.value
						break
			EnemyMove.IntentType.DEBUFF:
				icon = "☠"
				intent_color = Color(0.8, 0.3, 0.8)
				for effect in enemy.current_intent.effects:
					if effect is StatusApplyEffect:
						value_str = " %s" % effect.status_effect.effect_name
						break
			EnemyMove.IntentType.BUFF:
				icon = "★"
				intent_color = Color(0.3, 0.9, 0.4)
				for effect in enemy.current_intent.effects:
					if effect is StatusApplyEffect:
						value_str = " %s" % effect.status_effect.effect_name
						break
		intent_lbl.add_theme_color_override("font_color", intent_color)
		intent_lbl.text = "%s %s%s" % [icon, enemy.current_intent.move_name, value_str]
	else:
		intent_lbl.text = ""

	panel.modulate = Color(0.4, 0.4, 0.4, 0.5) if enemy.stats.is_dead() else Color.WHITE


# ============================================================
# FULL UI REFRESH
# ============================================================

func _refresh_ui() -> void:
	if not combat_engine or not combat_engine.player_stats:
		return

	# Player stats
	hp_label.text = "HP: %d / %d" % [combat_engine.player_stats.current_hp,
		combat_engine.player_stats.max_hp]
	block_label.text = "Block: %d" % combat_engine.player_stats.block
	energy_label.text = "Energy: %d / %d" % [combat_engine.energy, CombatEngine.MAX_ENERGY]

	if RunManager.passion:
		var tier = RunManager.get_passion_tier()
		passion_label.text = "Passion: %d (%s)" % [
			RunManager.passion.current_value, PassionState.tier_name(tier)]
		if RunManager.current_character:
			var t = RunManager.current_character.passion_thresholds
			var c = RunManager.current_character
			passion_label.tooltip_text = (
				"Passion determines which personality dominates.\n" +
				"High = %s (Primary)  |  Low = %s (Secondary)\n\n" % [
					c.primary_personality, c.secondary_personality] +
				"Blazing: %d+  (Primary at full power)\n" % t[0] +
				"Inspired: %d-%d  (Primary favored)\n" % [t[1], t[0] - 1] +
				"Steady: %d-%d  (Balanced)\n" % [t[2], t[1] - 1] +
				"Wavering: %d-%d  (Secondary favored)\n" % [t[3], t[2] - 1] +
				"Hollow: <%d  (Secondary at full power)" % t[3])
	else:
		passion_label.text = "Passion: --"

	player_status_label.text = _format_statuses(combat_engine.player_stats)
	player_status_label.tooltip_text = _format_status_tooltips(combat_engine.player_stats)

	# Piles
	draw_label.text = "Draw: %d" % combat_engine.piles.draw_pile.size()
	discard_label.text = "Discard: %d" % combat_engine.piles.discard_pile.size()
	exhaust_label.text = "Exhaust: %d" % combat_engine.piles.exhaust_pile.size()

	# Hand — fan cards in an arc
	for child in hand_container.get_children():
		child.queue_free()
	card_nodes.clear()

	var hand = combat_engine.piles.hand
	var card_count = hand.size()
	for i in card_count:
		var card = hand[i]
		var panel = _create_card_panel(card)
		hand_container.add_child(panel)
		card_nodes[card] = panel
		# Fan rotation: spread cards in an arc
		if card_count > 1:
			var max_angle := 3.0 * minf(card_count, 7)  # degrees total spread
			var angle = lerp(-max_angle, max_angle, float(i) / (card_count - 1))
			panel.rotation_degrees = angle
			# Vertical arc offset (middle cards higher)
			var t_norm = float(i) / (card_count - 1) - 0.5  # -0.5 to 0.5
			panel.position.y = abs(t_norm) * 20.0  # edges lower

	# Enemies
	for enemy in combat_engine.enemies:
		_update_enemy_panel(enemy)

	_update_card_highlights()

	# End turn button
	var can_act = combat_engine.phase == CombatEngine.Phase.PLAYER_TURN
	end_turn_btn.disabled = not can_act


# ============================================================
# COMBAT LOG
# ============================================================

func _format_statuses(stats: CombatantStats) -> String:
	var parts: PackedStringArray = []
	for effect in stats.statuses:
		var stacks = stats.statuses[effect]
		if stacks > 0:
			parts.append("%s(%d)" % [effect.effect_name, stacks])
	return "  ".join(parts)


func _format_status_tooltips(stats: CombatantStats) -> String:
	var lines: PackedStringArray = []
	for effect in stats.statuses:
		var stacks = stats.statuses[effect]
		if stacks > 0:
			lines.append("%s (%d): %s" % [effect.effect_name, stacks, effect.description])
	return "\n".join(lines) if lines.size() > 0 else ""


func _log(msg: String) -> void:
	log_text.append_text(msg + "\n")


func _log_relic_activations(trigger: RelicData.RelicTrigger) -> void:
	for relic in RunManager.relics:
		if relic.trigger == trigger:
			_log("[color=cyan]>> %s: %s[/color]" % [relic.relic_name, relic.description])


# ============================================================
# EVENT HANDLERS
# ============================================================

func _on_combat_started() -> void:
	for enemy in combat_engine.enemies:
		var panel = _create_enemy_panel(enemy)
		enemy_container.add_child(panel)
		enemy_nodes[enemy] = panel
	_log_relic_activations(RelicData.RelicTrigger.ON_COMBAT_START)
	_refresh_ui()
	_animate_card_draw()


func _on_card_played(card: CardData, _target) -> void:
	_log("Played [color=white]%s[/color]." % card.card_name)
	RunManager.run_stats["cards_played"] = RunManager.run_stats.get("cards_played", 0) + 1
	_refresh_ui()


func _on_card_exhausted(card: CardData) -> void:
	_log("[color=gray]%s exhausted.[/color]" % card.card_name)


func _on_player_turn_started() -> void:
	_log("[color=cyan]--- Your Turn %d ---[/color]" % combat_engine.turn_number)
	_log_relic_activations(RelicData.RelicTrigger.ON_TURN_START)
	_show_turn_banner("Your Turn", Color(0.3, 0.8, 0.9))
	_refresh_ui()
	_animate_card_draw()


func _on_enemy_turn_started() -> void:
	_log("[color=orange]--- Enemy Turn ---[/color]")
	_show_turn_banner("Enemy Turn", Color(0.9, 0.4, 0.3))
	for enemy in combat_engine.enemies:
		if not enemy.stats.is_dead() and enemy.current_intent:
			_log("%s uses [color=white]%s[/color]!" % [
				enemy.enemy_data.enemy_name, enemy.current_intent.move_name])
	_refresh_ui()


func _on_player_damaged(amount: int, new_hp: int) -> void:
	_log("[color=red]You take %d damage! (HP: %d)[/color]" % [amount, new_hp])
	RunManager.run_stats["damage_taken"] = RunManager.run_stats.get("damage_taken", 0) + amount
	_screen_shake(10.0, 0.25)
	_flash_damage_overlay()
	_refresh_ui()


func _on_enemy_damaged(enemy, amount: int, new_hp: int) -> void:
	_log("%s takes [color=yellow]%d damage[/color]. (HP: %d)" % [
		enemy.enemy_data.enemy_name, amount, new_hp])
	RunManager.run_stats["damage_dealt"] = RunManager.run_stats.get("damage_dealt", 0) + amount
	var panel = enemy_nodes.get(enemy)
	_spawn_damage_number("-%d" % amount, Color(1.0, 0.3, 0.2), panel)
	_refresh_ui()


func _on_enemy_died(enemy) -> void:
	_log("[color=green]%s defeated![/color]" % enemy.enemy_data.enemy_name)
	RunManager.run_stats["enemies_killed"] = RunManager.run_stats.get("enemies_killed", 0) + 1
	_animate_enemy_death(enemy)
	_refresh_ui()


func _on_block_gained(target, amount: int) -> void:
	if target == combat_engine.player_stats:
		_log("Gained [color=cyan]%d Block[/color]." % amount)
		_spawn_damage_number("+%d" % amount, Color(0.3, 0.7, 1.0), null)
	else:
		for enemy in combat_engine.enemies:
			if enemy.stats == target:
				_log("%s gains [color=cyan]%d Block[/color]." % [
					enemy.enemy_data.enemy_name, amount])
				var panel = enemy_nodes.get(enemy)
				_spawn_damage_number("+%d" % amount, Color(0.3, 0.7, 1.0), panel)
				break
	_refresh_ui()


func _on_passion_changed(old_value: int, new_value: int) -> void:
	var diff = new_value - old_value
	if diff > 0:
		_log("[color=orange]Passion +%d (%d)[/color]" % [diff, new_value])
	else:
		_log("[color=orange]Passion %d (%d)[/color]" % [diff, new_value])
	_refresh_ui()


func _on_status_applied(target, effect: StatusEffectData, stacks: int) -> void:
	var name = _get_combatant_name(target)
	var color = "green" if effect.is_buff else "magenta"
	_log("[color=%s]%s: +%d %s[/color]" % [color, name, stacks, effect.effect_name])
	_refresh_ui()


func _on_status_removed(target, effect: StatusEffectData) -> void:
	var name = _get_combatant_name(target)
	_log("[color=gray]%s: %s wore off.[/color]" % [name, effect.effect_name])
	_refresh_ui()


func _get_combatant_name(stats) -> String:
	if stats == combat_engine.player_stats:
		return "You"
	for enemy in combat_engine.enemies:
		if enemy.stats == stats:
			return enemy.enemy_data.enemy_name
	return "???"


func _show_turn_banner(text: String, color: Color) -> void:
	var banner = Label.new()
	banner.text = text
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 36)
	banner.add_theme_color_override("font_color", color)
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	banner.add_theme_constant_override("outline_size", 6)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.modulate.a = 0.0
	banner.z_index = 20
	banner.position.y = -20
	add_child(banner)
	var t = create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.15)
	t.tween_interval(0.6)
	t.tween_property(banner, "modulate:a", 0.0, 0.3)
	t.tween_callback(banner.queue_free)


func _screen_shake(intensity: float = 8.0, duration: float = 0.2) -> void:
	if not _main_container:
		return
	var base_pos = _main_container.position
	var tween = create_tween()
	var steps := 6
	for i in steps:
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		intensity *= 0.7
		tween.tween_property(_main_container, "position", base_pos + offset, duration / steps)
	tween.tween_property(_main_container, "position", base_pos, duration / steps)


func _spawn_damage_number(text: String, color: Color, target_panel: Control) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.z_index = 10

	if target_panel:
		var pos = target_panel.global_position + Vector2(target_panel.size.x / 2.0 - 30, 10)
		lbl.global_position = pos
	else:
		lbl.position = Vector2(960, 400)

	add_child(lbl)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 60, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(lbl.queue_free)


func _on_combat_won() -> void:
	_log("\n[color=gold]========== VICTORY! ==========[/color]")
	AudioManager.play_sfx("gold_gain")
	end_turn_btn.disabled = true
	_spawn_victory_particles()
	# Sync HP back to RunManager
	RunManager.current_hp = combat_engine.player_stats.current_hp
	# Process end-of-combat relics
	combat_engine.process_combat_end_relics()
	for relic in RunManager.relics:
		if relic.trigger == RelicData.RelicTrigger.ON_COMBAT_END:
			_log("[color=cyan]%s: %s[/color]" % [relic.relic_name, relic.description])
	# Show continue button
	_show_continue_button("Continue", _on_continue_pressed)


func _on_combat_lost() -> void:
	_log("\n[color=red]========== DEFEAT ==========[/color]")
	end_turn_btn.disabled = true
	RunManager.end_run(false)
	_show_continue_button("Game Over", _on_game_over_pressed)


func _on_end_turn_pressed() -> void:
	if combat_engine.phase == CombatEngine.Phase.PLAYER_TURN:
		AudioManager.play_sfx("button_click")
		selected_card = null
		combat_engine.end_player_turn()


func _show_continue_button(text: String, callback: Callable) -> void:
	continue_btn = Button.new()
	continue_btn.text = text
	continue_btn.custom_minimum_size = Vector2(200, 60)
	continue_btn.add_theme_font_size_override("font_size", 22)
	continue_btn.pressed.connect(callback)
	# Add next to the end turn button
	end_turn_btn.get_parent().add_child(continue_btn)


func _on_continue_pressed() -> void:
	if RunManager.pending_relic_reward:
		# Check if relics are actually available before showing relic screen
		var owned = RunManager.get_owned_relic_names()
		var has_relics = false
		if RunManager.pending_relic_is_boss:
			has_relics = RelicPool.get_boss_reward_choices(RngManager.loot_rng, owned).size() > 0
		else:
			has_relics = RelicPool.get_reward_choices(RngManager.loot_rng, 3, owned).size() > 0
		RunManager.pending_relic_reward = false
		if has_relics:
			SceneTransition.change_scene("res://scenes/reward/relic_reward_scene.tscn")
		else:
			SceneTransition.change_scene("res://scenes/reward/card_reward_scene.tscn")
	else:
		SceneTransition.change_scene("res://scenes/reward/card_reward_scene.tscn")


func _on_game_over_pressed() -> void:
	SceneTransition.change_scene("res://scenes/game_over/game_over_scene.tscn")


# ============================================================
# ANIMATED HP BARS
# ============================================================

func _animate_hp_bar(bar: ProgressBar, new_value: float) -> void:
	var old_value = bar.value
	bar.value = new_value
	# Animate trail bar with delay
	var trail: ProgressBar = _hp_trail_bars.get(bar)
	if trail:
		trail.max_value = bar.max_value
		if new_value < old_value:
			# Damage: trail lags behind
			var t = create_tween()
			t.tween_property(trail, "value", new_value, 0.6).set_delay(0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		else:
			# Heal: trail catches up instantly
			trail.value = new_value


# ============================================================
# CARD HOVER DETAIL POPUP
# ============================================================

func _show_card_hover(card: CardData, source_panel: PanelContainer) -> void:
	_hide_card_hover()
	_hover_popup = PanelContainer.new()
	_hover_popup.custom_minimum_size = Vector2(260, 340)
	_hover_popup.z_index = 50
	_hover_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	match card.card_type:
		CardData.CardType.ATTACK:
			style.bg_color = Color(0.25, 0.08, 0.06, 0.97)
			style.border_color = Color(1.0, 0.3, 0.2)
		CardData.CardType.SKILL:
			style.bg_color = Color(0.06, 0.1, 0.28, 0.97)
			style.border_color = Color(0.25, 0.5, 1.0)
		CardData.CardType.POWER:
			style.bg_color = Color(0.25, 0.22, 0.04, 0.97)
			style.border_color = Color(1.0, 0.85, 0.15)

	# Upgraded card green border tint
	if card.upgraded:
		style.border_color = style.border_color.lerp(Color(0.3, 0.9, 0.3), 0.5)

	_hover_popup.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_hover_popup.add_child(vbox)

	# Cost circle
	var cost_lbl = Label.new()
	cost_lbl.text = str(card.energy_cost) + " Energy"
	cost_lbl.add_theme_font_size_override("font_size", 20)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.3))
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_lbl)

	# Name
	var name_lbl = Label.new()
	name_lbl.text = card.card_name
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Type + Rarity
	var type_names = ["Attack", "Skill", "Power"]
	var rarity_names = ["Starter", "Common", "Uncommon", "Rare"]
	var rarity_colors = [Color(0.5, 0.5, 0.5), Color(0.55, 0.55, 0.55), Color(0.3, 0.7, 0.9), Color(0.95, 0.8, 0.2)]
	var tr_lbl = Label.new()
	tr_lbl.text = "%s - %s" % [type_names[card.card_type], rarity_names[card.rarity]]
	tr_lbl.add_theme_font_size_override("font_size", 15)
	tr_lbl.add_theme_color_override("font_color", rarity_colors[card.rarity])
	tr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tr_lbl)

	# Personality
	if card.personality != CardData.PersonalityType.NEUTRAL:
		var pers_lbl = Label.new()
		pers_lbl.text = _get_personality_label(card.personality)
		pers_lbl.add_theme_font_size_override("font_size", 14)
		pers_lbl.add_theme_color_override("font_color", _get_personality_color(card.personality))
		pers_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(pers_lbl)

	# Art area
	var art = PanelContainer.new()
	art.custom_minimum_size = Vector2(0, 60)
	var art_s = StyleBoxFlat.new()
	art_s.set_corner_radius_all(6)
	art_s.content_margin_top = 8
	art_s.content_margin_bottom = 8
	match card.card_type:
		CardData.CardType.ATTACK:
			art_s.bg_color = Color(0.4, 0.1, 0.08)
		CardData.CardType.SKILL:
			art_s.bg_color = Color(0.08, 0.15, 0.35)
		CardData.CardType.POWER:
			art_s.bg_color = Color(0.35, 0.28, 0.06)
	art.add_theme_stylebox_override("panel", art_s)
	var icon_file2 = CARD_ICONS.get(card.card_name, "")
	if icon_file2 != "":
		var art_icon = TextureRect.new()
		art_icon.texture = load(icon_file2)
		art_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art_icon.custom_minimum_size = Vector2(48, 48)
		art.add_child(art_icon)
	else:
		var art_lbl = Label.new()
		match card.card_type:
			CardData.CardType.ATTACK: art_lbl.text = "⚔"
			CardData.CardType.SKILL: art_lbl.text = "◆"
			CardData.CardType.POWER: art_lbl.text = "★"
		art_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		art_lbl.add_theme_font_size_override("font_size", 32)
		art_lbl.add_theme_color_override("font_color", style.border_color.lightened(0.3))
		art.add_child(art_lbl)
	vbox.add_child(art)

	# Description
	var desc = Label.new()
	if combat_engine and combat_engine.player_stats:
		desc.text = card.get_modified_description(combat_engine.player_stats)
	else:
		desc.text = card.get_generated_description()
	desc.add_theme_font_size_override("font_size", 18)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	# Exhaust tag
	if card.exhaust:
		var ex = Label.new()
		ex.text = "Exhaust"
		ex.add_theme_font_size_override("font_size", 14)
		ex.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
		ex.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(ex)

	# Target type
	var target_lbl = Label.new()
	match card.target_type:
		CardData.TargetType.SINGLE_ENEMY: target_lbl.text = "Target: Single Enemy"
		CardData.TargetType.ALL_ENEMIES: target_lbl.text = "Target: All Enemies"
		CardData.TargetType.SELF: target_lbl.text = "Target: Self"
		_: target_lbl.text = ""
	if target_lbl.text:
		target_lbl.add_theme_font_size_override("font_size", 13)
		target_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		target_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(target_lbl)

	_ignore_mouse_recursive(_hover_popup)

	# Position above the source card
	add_child(_hover_popup)
	await get_tree().process_frame
	if not is_instance_valid(source_panel) or not is_instance_valid(_hover_popup):
		if is_instance_valid(_hover_popup):
			_hover_popup.queue_free()
			_hover_popup = null
		return
	var pos = source_panel.global_position
	_hover_popup.global_position = Vector2(
		clampf(pos.x - 50, 10, 1920 - _hover_popup.size.x - 10),
		maxf(10, pos.y - _hover_popup.size.y - 10)
	)


func _hide_card_hover() -> void:
	if _hover_popup:
		_hover_popup.queue_free()
		_hover_popup = null


# ============================================================
# VICTORY PARTICLES
# ============================================================

func _spawn_victory_particles() -> void:
	for i in 30:
		var p = ColorRect.new()
		p.custom_minimum_size = Vector2(4, 4)
		p.size = Vector2(4, 4)
		var brightness = randf_range(0.7, 1.0)
		p.color = Color(brightness, brightness * 0.85, brightness * 0.3, randf_range(0.3, 0.8))
		p.position = Vector2(randf_range(200, 1720), randf_range(400, 700))
		p.z_index = 25
		add_child(p)
		var t = create_tween().set_parallel(true)
		t.tween_property(p, "position:y", p.position.y - randf_range(200, 500), randf_range(1.0, 2.5)).set_ease(Tween.EASE_OUT)
		t.tween_property(p, "position:x", p.position.x + randf_range(-100, 100), randf_range(1.0, 2.5))
		t.tween_property(p, "modulate:a", 0.0, 1.5).set_delay(0.8)
		t.chain().tween_callback(p.queue_free)


# ============================================================
# DAMAGE FLASH
# ============================================================

func _flash_damage_overlay() -> void:
	if not _damage_flash:
		return
	_damage_flash.color.a = 0.35
	var t = create_tween()
	t.tween_property(_damage_flash, "color:a", 0.0, 0.3).set_ease(Tween.EASE_OUT)


# ============================================================
# ENEMY DEATH ANIMATION
# ============================================================

func _animate_enemy_death(enemy: EnemyCombatState) -> void:
	var panel: PanelContainer = enemy_nodes.get(enemy)
	if not panel:
		return
	# Burst particles from the enemy position
	var center = panel.global_position + panel.size / 2.0
	for i in 15:
		var p = ColorRect.new()
		p.custom_minimum_size = Vector2(5, 5)
		p.size = Vector2(5, 5)
		p.color = Color(randf_range(0.6, 1.0), randf_range(0.2, 0.5), randf_range(0.1, 0.3), 0.8)
		p.position = center
		p.z_index = 20
		add_child(p)
		var angle = randf_range(0, TAU)
		var dist = randf_range(60, 180)
		var target_pos = center + Vector2(cos(angle), sin(angle)) * dist
		var t = create_tween().set_parallel(true)
		t.tween_property(p, "position", target_pos, randf_range(0.4, 0.8)).set_ease(Tween.EASE_OUT)
		t.tween_property(p, "modulate:a", 0.0, 0.6).set_delay(0.2)
		t.chain().tween_callback(p.queue_free)
	# Fade and shrink the enemy panel
	panel.pivot_offset = panel.size / 2.0
	var t = create_tween().set_parallel(true)
	t.tween_property(panel, "modulate:a", 0.0, 0.5)
	t.tween_property(panel, "scale", Vector2(0.3, 0.3), 0.5).set_ease(Tween.EASE_IN)


# ============================================================
# CARD DRAW ANIMATION
# ============================================================

func _animate_card_draw() -> void:
	var delay := 0.0
	for card in card_nodes:
		var panel: PanelContainer = card_nodes[card]
		panel.pivot_offset = panel.custom_minimum_size / 2.0
		panel.scale = Vector2(0.0, 0.0)
		panel.modulate.a = 0.0
		var t = create_tween().set_parallel(true)
		t.tween_property(panel, "scale", Vector2.ONE, 0.25).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(panel, "modulate:a", 1.0, 0.15).set_delay(delay)
		delay += 0.08
