extends Control
## Character selection screen — choose your character before starting a run.

var _particles: Array[ColorRect] = []
var _time := 0.0
var _card_panels: Array[PanelContainer] = []


func _ready() -> void:
	_build_ui()
	AudioManager.play_music("map")


func _process(delta: float) -> void:
	_time += delta
	_update_particles(delta)


# ============================================================
# UI CONSTRUCTION
# ============================================================

func _build_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Vignette overlay
	_add_vignette()

	# Floating particles
	_spawn_particles()

	# Main layout
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Choose Your Character"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4))
	title.modulate.a = 0.0
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Each character brings a unique identity to the story"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
	subtitle.modulate.a = 0.0
	vbox.add_child(subtitle)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)

	# Character cards container
	var card_center = CenterContainer.new()
	card_center.modulate.a = 0.0
	vbox.add_child(card_center)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	card_center.add_child(hbox)

	# Character data
	var characters = [
		{
			"name": "Emo Hybrid Caster",
			"hp": 80,
			"primary": "Magic",
			"secondary": "Physical",
			"cards": 9,
			"symbol": "E",
			"portrait_bg": Color(0.25, 0.12, 0.35),
			"portrait_border": Color(0.6, 0.3, 0.8),
			"symbol_color": Color(0.75, 0.45, 0.95),
			"locked": false,
		},
		{
			"name": "Hotheaded Mage",
			"hp": 70,
			"primary": "Destruction",
			"secondary": "Survivability",
			"cards": 9,
			"symbol": "H",
			"portrait_bg": Color(0.35, 0.12, 0.08),
			"portrait_border": Color(0.9, 0.4, 0.15),
			"symbol_color": Color(0.95, 0.5, 0.2),
			"locked": true,
		},
		{
			"name": "Pensive Ranger",
			"hp": 75,
			"primary": "Utility",
			"secondary": "Safety",
			"cards": 9,
			"symbol": "P",
			"portrait_bg": Color(0.08, 0.25, 0.12),
			"portrait_border": Color(0.3, 0.7, 0.35),
			"symbol_color": Color(0.4, 0.85, 0.45),
			"locked": true,
		},
	]

	for i in characters.size():
		var data = characters[i]
		var card = _build_character_card(data, i)
		hbox.add_child(card)
		_card_panels.append(card)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 10
	vbox.add_child(spacer2)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(180, 50)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.modulate.a = 0.0

	var back_style = StyleBoxFlat.new()
	back_style.set_corner_radius_all(10)
	back_style.set_border_width_all(2)
	back_style.bg_color = Color(0.14, 0.11, 0.2)
	back_style.border_color = Color(0.5, 0.4, 0.3)
	back_style.content_margin_left = 16
	back_style.content_margin_right = 16
	back_style.content_margin_top = 8
	back_style.content_margin_bottom = 8
	back_btn.add_theme_stylebox_override("normal", back_style)

	var back_hover = back_style.duplicate()
	back_hover.bg_color = Color(0.22, 0.17, 0.28)
	back_hover.border_color = Color(0.65, 0.55, 0.4)
	back_btn.add_theme_stylebox_override("hover", back_hover)

	var back_pressed = back_style.duplicate()
	back_pressed.bg_color = Color(0.1, 0.08, 0.14)
	back_btn.add_theme_stylebox_override("pressed", back_pressed)
	back_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back_btn.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	back_btn.add_theme_color_override("font_hover_color", Color(0.9, 0.8, 0.6))

	back_btn.pressed.connect(_on_back)
	vbox.add_child(back_btn)

	# Animate entrance
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title, "modulate:a", 1.0, 0.8).set_delay(0.2)
	tween.tween_property(subtitle, "modulate:a", 1.0, 0.7).set_delay(0.5)
	tween.tween_property(card_center, "modulate:a", 1.0, 0.8).set_delay(0.7)
	tween.tween_property(back_btn, "modulate:a", 1.0, 0.6).set_delay(1.2)


func _build_character_card(data: Dictionary, _index: int) -> PanelContainer:
	var is_locked: bool = data["locked"]

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 420)

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	style.bg_color = Color(0.12, 0.09, 0.18)
	style.border_color = Color(0.55, 0.45, 0.25) if not is_locked else Color(0.3, 0.3, 0.3)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	if is_locked:
		panel.modulate = Color(0.5, 0.5, 0.5)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Character name
	var name_lbl = Label.new()
	name_lbl.text = data["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4))
	vbox.add_child(name_lbl)

	# Portrait area
	var portrait_panel = PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(248, 140)
	var portrait_style = StyleBoxFlat.new()
	portrait_style.set_corner_radius_all(10)
	portrait_style.set_border_width_all(2)
	portrait_style.bg_color = data["portrait_bg"]
	portrait_style.border_color = data["portrait_border"]
	portrait_panel.add_theme_stylebox_override("panel", portrait_style)
	vbox.add_child(portrait_panel)

	var portrait_center = CenterContainer.new()
	portrait_panel.add_child(portrait_center)

	var symbol_lbl = Label.new()
	symbol_lbl.text = data["symbol"]
	symbol_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol_lbl.add_theme_font_size_override("font_size", 72)
	symbol_lbl.add_theme_color_override("font_color", data["symbol_color"])
	portrait_center.add_child(symbol_lbl)

	# HP
	var hp_lbl = Label.new()
	hp_lbl.text = "HP: %d" % data["hp"]
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.add_theme_font_size_override("font_size", 18)
	hp_lbl.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
	vbox.add_child(hp_lbl)

	# Primary personality
	var primary_lbl = Label.new()
	primary_lbl.text = "Primary: %s" % data["primary"]
	primary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	primary_lbl.add_theme_font_size_override("font_size", 16)
	primary_lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.2))
	vbox.add_child(primary_lbl)

	# Secondary personality
	var secondary_lbl = Label.new()
	secondary_lbl.text = "Secondary: %s" % data["secondary"]
	secondary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secondary_lbl.add_theme_font_size_override("font_size", 16)
	secondary_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9))
	vbox.add_child(secondary_lbl)

	# Starting deck
	var deck_lbl = Label.new()
	deck_lbl.text = "Starting Deck: %d cards" % data["cards"]
	deck_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_lbl.add_theme_font_size_override("font_size", 15)
	deck_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(deck_lbl)

	# Spacer before button
	var btn_spacer = Control.new()
	btn_spacer.custom_minimum_size.y = 6
	vbox.add_child(btn_spacer)

	if is_locked:
		# Coming Soon label
		var locked_lbl = Label.new()
		locked_lbl.text = "Coming Soon"
		locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_lbl.add_theme_font_size_override("font_size", 18)
		locked_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(locked_lbl)
	else:
		# Select button
		var select_btn = Button.new()
		select_btn.text = "Select"
		select_btn.custom_minimum_size = Vector2(200, 48)
		select_btn.add_theme_font_size_override("font_size", 20)
		select_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		select_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var btn_style = StyleBoxFlat.new()
		btn_style.set_corner_radius_all(10)
		btn_style.set_border_width_all(2)
		btn_style.bg_color = Color(0.18, 0.13, 0.28)
		btn_style.border_color = Color(0.8, 0.6, 0.25)
		btn_style.content_margin_left = 16
		btn_style.content_margin_right = 16
		btn_style.content_margin_top = 8
		btn_style.content_margin_bottom = 8
		select_btn.add_theme_stylebox_override("normal", btn_style)

		var hover_style = btn_style.duplicate()
		hover_style.bg_color = Color(0.26, 0.2, 0.38)
		hover_style.border_color = Color(1.0, 0.78, 0.3)
		select_btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = btn_style.duplicate()
		pressed_style.bg_color = Color(0.12, 0.09, 0.18)
		select_btn.add_theme_stylebox_override("pressed", pressed_style)
		select_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		select_btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
		select_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.6))

		select_btn.pressed.connect(_on_select_character)
		vbox.add_child(select_btn)

		# Hover scale animation for selectable card
		panel.mouse_entered.connect(func():
			var tw = create_tween()
			tw.tween_property(panel, "scale", Vector2(1.04, 1.04), 0.15)
			panel.pivot_offset = panel.size / 2.0
		)
		panel.mouse_exited.connect(func():
			var tw = create_tween()
			tw.tween_property(panel, "scale", Vector2.ONE, 0.15)
		)

	return panel


# ============================================================
# VISUAL EFFECTS (particles, vignette)
# ============================================================

func _add_vignette() -> void:
	var vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0, 0, 0, 0.4)
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv) * 1.5;
	float vig = smoothstep(0.2, 1.0, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vig * 0.7);
}
"""
	mat.shader = shader
	vignette.material = mat
	add_child(vignette)


func _spawn_particles() -> void:
	for i in 25:
		var p = ColorRect.new()
		p.custom_minimum_size = Vector2(2, 2)
		p.size = Vector2(2, 2)
		var brightness = randf_range(0.15, 0.4)
		p.color = Color(brightness * 1.2, brightness * 0.9, brightness * 0.5, randf_range(0.1, 0.4))
		p.position = Vector2(randf_range(0, 1920), randf_range(0, 1080))
		p.set_meta("vel_x", randf_range(-8, 8))
		p.set_meta("vel_y", randf_range(-20, -5))
		p.set_meta("phase", randf_range(0, TAU))
		add_child(p)
		_particles.append(p)


func _update_particles(delta: float) -> void:
	for p in _particles:
		var vx: float = p.get_meta("vel_x")
		var vy: float = p.get_meta("vel_y")
		var phase: float = p.get_meta("phase")
		p.position.x += vx * delta + sin(_time * 0.5 + phase) * 0.3
		p.position.y += vy * delta
		p.modulate.a = 0.3 + sin(_time * 0.8 + phase) * 0.15
		if p.position.y < -10:
			p.position.y = 1090
			p.position.x = randf_range(0, 1920)


# ============================================================
# ACTIONS
# ============================================================

func _on_back() -> void:
	AudioManager.play_sfx("button_click")
	SceneTransition.change_scene("res://scenes/title/title_screen.tscn")


func _on_select_character() -> void:
	AudioManager.play_sfx("button_click")
	var character = _create_emo_hybrid()
	RunManager.start_run(character)
	SceneTransition.change_scene("res://scenes/map/map_scene.tscn")


# ============================================================
# CHARACTER CREATION
# ============================================================

func _create_emo_hybrid() -> CharacterData:
	var c = CharacterData.new()
	c.character_name = "Emo Hybrid Caster"
	c.max_health = 80
	c.passion_volatility = 1.0
	c.passion_thresholds.assign([80, 60, 40, 20])
	c.primary_personality = "Magic"
	c.secondary_personality = "Physical"

	# Build deck
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


# -- Card / effect factory helpers --

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


func _fx_passion(v: int) -> PassionEffect:
	var e = PassionEffect.new()
	e.value = v
	return e
