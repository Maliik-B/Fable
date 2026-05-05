extends Control
## Game Over screen shown when the player dies.
## Displays run statistics and offers a "Try Again" button to return to the title screen.

var _particles: Array[ColorRect] = []
var _time := 0.0


func _ready() -> void:
	_build_ui()
	AudioManager.stop_music()


func _process(delta: float) -> void:
	_time += delta
	_update_particles(delta)


func _build_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.02)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Vignette overlay
	var vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv) * 1.4;
	float vig = smoothstep(0.25, 1.0, dist);
	COLOR = vec4(0.15, 0.0, 0.0, vig * 0.7);
}
"""
	mat.shader = shader
	vignette.material = mat
	add_child(vignette)

	# Falling ember particles (behind text)
	_spawn_particles()

	# Center everything
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)

	# --- DEFEAT title ---
	var title = Label.new()
	title.text = "DEFEAT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.8, 0.15, 0.1))
	title.modulate.a = 0.0
	title.scale = Vector2(0.5, 0.5)
	title.pivot_offset = Vector2(960, 32) # approximate center for scaling
	vbox.add_child(title)

	var t = create_tween().set_parallel(true)
	t.tween_property(title, "modulate:a", 1.0, 0.6)
	t.tween_property(title, "scale", Vector2.ONE, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# --- Flavor text ---
	var flavor = Label.new()
	flavor.text = "Your fable ends here..."
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 18)
	flavor.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
	vbox.add_child(flavor)

	# --- Spacer ---
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 20
	vbox.add_child(spacer1)

	# --- Run Statistics panel ---
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.06, 0.9)
	style.set_corner_radius_all(10)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.15, 0.15)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.x = 400
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(panel)

	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	panel.add_child(stats_vbox)

	_add_stat_row(stats_vbox, "Floors Cleared",
		str(RunManager.run_stats.get("floors_cleared", 0)),
		Color(0.7, 0.7, 0.7))
	_add_stat_row(stats_vbox, "Enemies Defeated",
		str(RunManager.run_stats.get("enemies_killed", 0)),
		Color(0.9, 0.5, 0.2))
	_add_stat_row(stats_vbox, "Cards Played",
		str(RunManager.run_stats.get("cards_played", 0)),
		Color(0.5, 0.7, 0.9))
	_add_stat_row(stats_vbox, "Damage Dealt",
		str(RunManager.run_stats.get("damage_dealt", 0)),
		Color(0.95, 0.8, 0.2))
	_add_stat_row(stats_vbox, "Damage Taken",
		str(RunManager.run_stats.get("damage_taken", 0)),
		Color(0.9, 0.3, 0.3))
	_add_stat_row(stats_vbox, "Gold Earned",
		str(RunManager.run_stats.get("gold_earned", 0)),
		Color(0.95, 0.85, 0.3))
	_add_stat_row(stats_vbox, "Time",
		RunManager.get_run_time_string(),
		Color(0.55, 0.55, 0.55))

	# --- Spacer ---
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 30
	vbox.add_child(spacer2)

	# --- Try Again button ---
	var try_btn = Button.new()
	try_btn.text = "Try Again"
	try_btn.custom_minimum_size = Vector2(260, 60)
	try_btn.add_theme_font_size_override("font_size", 22)
	try_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.35))
	try_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	try_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.1, 0.1)
	btn_style.set_corner_radius_all(12)
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.6, 0.2, 0.2)
	btn_style.content_margin_left = 20
	btn_style.content_margin_right = 20
	btn_style.content_margin_top = 10
	btn_style.content_margin_bottom = 10
	try_btn.add_theme_stylebox_override("normal", btn_style)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.3, 0.15, 0.12)
	btn_hover.set_corner_radius_all(12)
	btn_hover.border_width_left = 2
	btn_hover.border_width_right = 2
	btn_hover.border_width_top = 2
	btn_hover.border_width_bottom = 2
	btn_hover.border_color = Color(0.8, 0.3, 0.25)
	btn_hover.content_margin_left = 20
	btn_hover.content_margin_right = 20
	btn_hover.content_margin_top = 10
	btn_hover.content_margin_bottom = 10
	try_btn.add_theme_stylebox_override("hover", btn_hover)
	try_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.5, 0.4))

	try_btn.pressed.connect(_on_try_again)
	vbox.add_child(try_btn)


func _add_stat_row(parent: VBoxContainer, label: String, value: String, color: Color) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	lbl.custom_minimum_size.x = 160
	row.add_child(lbl)

	var val_lbl = Label.new()
	val_lbl.text = str(value)
	val_lbl.add_theme_font_size_override("font_size", 20)
	val_lbl.add_theme_color_override("font_color", color)
	val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)


func _spawn_particles() -> void:
	for i in 22:
		var p = ColorRect.new()
		p.custom_minimum_size = Vector2(3, 3)
		p.size = Vector2(3, 3)
		p.color = Color(
			randf_range(0.6, 0.8),
			randf_range(0.1, 0.3),
			randf_range(0.05, 0.1),
			randf_range(0.2, 0.5))
		p.position = Vector2(randf_range(0, 1920), randf_range(0, 1080))
		p.set_meta("vel_y", randf_range(10, 30))
		p.set_meta("phase", randf_range(0, TAU))
		add_child(p)
		_particles.append(p)


func _update_particles(delta: float) -> void:
	for p in _particles:
		var vy: float = p.get_meta("vel_y")
		var phase: float = p.get_meta("phase")
		p.position.x += sin(_time * 0.4 + phase) * 0.5
		p.position.y += vy * delta
		p.modulate.a = 0.3 + sin(_time * 0.6 + phase) * 0.15
		# Wrap at bottom back to top
		if p.position.y > 1090:
			p.position.y = -10
			p.position.x = randf_range(0, 1920)


func _on_try_again() -> void:
	AudioManager.play_sfx("button_click")
	RunManager.run_active = false
	SceneTransition.change_scene("res://scenes/title/title_screen.tscn")
