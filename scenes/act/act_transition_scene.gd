extends Control
## Shown after a boss is defeated.
## If more acts remain, advances to the next act. Otherwise shows run victory.

var is_final_act: bool
var _particles: Array[ColorRect] = []
var _time := 0.0


func _ready() -> void:
	is_final_act = RunManager.current_act >= RunManager.MAX_ACTS
	_build_ui()
	if is_final_act:
		AudioManager.play_music("victory")
	else:
		AudioManager.stop_music()


func _process(delta: float) -> void:
	_time += delta
	_update_particles(delta)


func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.06)
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
	float dist = length(uv) * 1.4;
	float vig = smoothstep(0.25, 1.0, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vig * 0.6);
}
"""
	mat.shader = shader
	vignette.material = mat
	add_child(vignette)

	# Rising golden particles (behind text)
	_spawn_particles()

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 80)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)

	if is_final_act:
		_build_victory(vbox)
	else:
		_build_act_complete(vbox)


func _build_act_complete(vbox: VBoxContainer) -> void:
	var title = Label.new()
	title.text = "Act %d Complete" % RunManager.current_act
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "The realm shifts as you press deeper..."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(desc)

	# Stats summary
	_build_stats_summary(vbox)

	var next_btn = Button.new()
	next_btn.text = "Enter Act %d" % (RunManager.current_act + 1)
	next_btn.custom_minimum_size = Vector2(260, 60)
	next_btn.add_theme_font_size_override("font_size", 22)
	next_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_btn.pressed.connect(_on_next_act)
	vbox.add_child(next_btn)


func _build_victory(vbox: VBoxContainer) -> void:
	var title = Label.new()
	title.text = "Victory!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	title.modulate.a = 0.0
	title.scale = Vector2(0.5, 0.5)
	title.pivot_offset = Vector2(960, 29)
	vbox.add_child(title)

	var t = create_tween().set_parallel(true)
	t.tween_property(title, "modulate:a", 1.0, 0.8)
	t.tween_property(title, "scale", Vector2.ONE, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var desc = Label.new()
	desc.text = "You have conquered the realm. Your fable is complete."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	vbox.add_child(desc)

	# Stats summary
	_build_stats_summary(vbox)

	var restart_btn = Button.new()
	restart_btn.text = "New Run"
	restart_btn.custom_minimum_size = Vector2(220, 60)
	restart_btn.add_theme_font_size_override("font_size", 22)
	restart_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_btn.pressed.connect(_on_new_run)
	vbox.add_child(restart_btn)


func _build_stats_summary(vbox: VBoxContainer) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	style.set_corner_radius_all(8)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(panel)

	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	panel.add_child(stats_vbox)

	_add_stat_line(stats_vbox, "HP", "%d / %d" % [RunManager.current_hp, RunManager.max_hp],
		Color(0.9, 0.3, 0.3))
	_add_stat_line(stats_vbox, "Gold", str(RunManager.gold),
		Color(0.95, 0.85, 0.3))
	_add_stat_line(stats_vbox, "Deck", "%d cards" % RunManager.current_deck.size(),
		Color(0.7, 0.7, 0.7))

	if RunManager.relics.size() > 0:
		_add_stat_line(stats_vbox, "Relics",
			", ".join(RunManager.get_owned_relic_names()),
			Color(0.7, 0.6, 0.8))

	if RunManager.passion:
		var tier = RunManager.get_passion_tier()
		_add_stat_line(stats_vbox, "Passion",
			"%d (%s)" % [RunManager.passion.current_value, PassionState.tier_name(tier)],
			Color(0.9, 0.5, 0.2))

	_add_stat_line(stats_vbox, "Time", RunManager.get_run_time_string(),
		Color(0.55, 0.55, 0.55))


func _add_stat_line(parent: VBoxContainer, label: String, value: String,
		color: Color) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	parent.add_child(hbox)

	var lbl = Label.new()
	lbl.text = label + ":"
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	lbl.custom_minimum_size.x = 80
	hbox.add_child(lbl)

	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 20)
	val.add_theme_color_override("font_color", color)
	hbox.add_child(val)


func _spawn_particles() -> void:
	for i in 28:
		var p = ColorRect.new()
		p.custom_minimum_size = Vector2(2, 2)
		p.size = Vector2(2, 2)
		var brightness = randf_range(0.7, 1.0)
		p.color = Color(
			brightness,
			brightness * 0.85,
			brightness * 0.3,
			randf_range(0.15, 0.4))
		p.position = Vector2(randf_range(0, 1920), randf_range(0, 1080))
		p.set_meta("vel_y", randf_range(-15, -5))
		p.set_meta("phase", randf_range(0, TAU))
		add_child(p)
		_particles.append(p)


func _update_particles(delta: float) -> void:
	for p in _particles:
		var vy: float = p.get_meta("vel_y")
		var phase: float = p.get_meta("phase")
		p.position.x += sin(_time * 0.4 + phase) * 0.4
		p.position.y += vy * delta
		p.modulate.a = 0.3 + sin(_time * 0.7 + phase) * 0.15
		# Wrap at top back to bottom
		if p.position.y < -10:
			p.position.y = 1090
			p.position.x = randf_range(0, 1920)


func _on_next_act() -> void:
	AudioManager.play_sfx("button_click")
	RunManager.advance_act()
	SceneTransition.change_scene("res://scenes/map/map_scene.tscn")


func _on_new_run() -> void:
	AudioManager.play_sfx("button_click")
	RunManager.run_active = false
	SceneTransition.change_scene("res://scenes/map/map_scene.tscn")
