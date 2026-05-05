extends Control
## Title screen — first thing the player sees.

var _particles: Array[ColorRect] = []
var _time := 0.0


func _ready() -> void:
	_build_ui()
	AudioManager.play_music("map")


func _process(delta: float) -> void:
	_time += delta
	_update_particles(delta)


func _build_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Vignette overlay
	_add_vignette()

	# Floating particle layer (behind text)
	_spawn_particles()

	# Center content
	var wrapper = CenterContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(wrapper)

	var center = VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.custom_minimum_size = Vector2(800, 500)
	center.add_theme_constant_override("separation", 12)
	wrapper.add_child(center)

	# Title
	var title = Label.new()
	title.text = "FABLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4))
	title.modulate.a = 0.0
	center.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "A Narrative Deckbuilder"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	subtitle.modulate.a = 0.0
	center.add_child(subtitle)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 60
	center.add_child(spacer)

	# Tagline
	var tagline = Label.new()
	tagline.text = "Every choice writes a page. Every battle turns one."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 16)
	tagline.add_theme_color_override("font_color", Color(0.5, 0.48, 0.42))
	tagline.modulate.a = 0.0
	center.add_child(tagline)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 40
	center.add_child(spacer2)

	# Start button
	var start_btn = Button.new()
	start_btn.text = "Begin Your Fable"
	start_btn.custom_minimum_size = Vector2(320, 70)
	start_btn.add_theme_font_size_override("font_size", 24)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	start_btn.modulate.a = 0.0

	var btn_style = StyleBoxFlat.new()
	btn_style.set_corner_radius_all(12)
	btn_style.set_border_width_all(2)
	btn_style.bg_color = Color(0.15, 0.12, 0.2)
	btn_style.border_color = Color(0.7, 0.55, 0.3)
	btn_style.content_margin_left = 20
	btn_style.content_margin_right = 20
	btn_style.content_margin_top = 12
	btn_style.content_margin_bottom = 12
	start_btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = btn_style.duplicate()
	hover_style.bg_color = Color(0.22, 0.18, 0.3)
	hover_style.border_color = Color(0.9, 0.7, 0.35)
	start_btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.08, 0.14)
	start_btn.add_theme_stylebox_override("pressed", pressed_style)
	start_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	start_btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	start_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.6))

	start_btn.pressed.connect(_on_start)
	center.add_child(start_btn)

	# Version / credit
	var version_lbl = Label.new()
	version_lbl.text = "v0.1 — Portfolio Build"
	version_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_lbl.add_theme_font_size_override("font_size", 13)
	version_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	version_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	version_lbl.offset_top = -30
	add_child(version_lbl)

	# Animate entrance
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title, "modulate:a", 1.0, 1.2).set_delay(0.3)
	tween.tween_property(subtitle, "modulate:a", 1.0, 1.0).set_delay(0.8)
	tween.tween_property(tagline, "modulate:a", 1.0, 1.0).set_delay(1.5)
	tween.tween_property(start_btn, "modulate:a", 1.0, 0.8).set_delay(2.0)


func _add_vignette() -> void:
	# Dark gradient overlay for depth
	var vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0, 0, 0, 0.4)
	# Use shader for radial vignette
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
	for i in 30:
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
		# Wrap
		if p.position.y < -10:
			p.position.y = 1090
			p.position.x = randf_range(0, 1920)


func _on_start() -> void:
	AudioManager.play_sfx("button_click")
	SceneTransition.change_scene("res://scenes/character_select/character_select_scene.tscn")
