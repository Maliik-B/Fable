extends Control
## Splash screen — brief branding display before the title screen.

var _particles: Array[ColorRect] = []
var _time := 0.0
var _fade_overlay: ColorRect


func _ready() -> void:
	_build_ui()
	_run_sequence()


func _process(delta: float) -> void:
	_time += delta
	_update_particles(delta)


func _build_ui() -> void:
	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Floating particles (behind text)
	_spawn_particles()

	# Center content
	var wrapper = CenterContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(wrapper)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	wrapper.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "FABLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "A Portfolio Production"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.45, 0.4, 0.55))
	vbox.add_child(subtitle)

	# Full-screen black overlay for fade effect (starts fully opaque)
	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color.BLACK
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_overlay)


func _spawn_particles() -> void:
	for i in 12:
		var p = ColorRect.new()
		p.custom_minimum_size = Vector2(2, 2)
		p.size = Vector2(2, 2)
		var brightness = randf_range(0.1, 0.25)
		p.color = Color(brightness * 1.2, brightness * 0.9, brightness * 0.5, randf_range(0.08, 0.25))
		p.position = Vector2(randf_range(0, 1920), randf_range(0, 1080))
		p.set_meta("vel_x", randf_range(-6, 6))
		p.set_meta("vel_y", randf_range(-15, -4))
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
		p.modulate.a = 0.2 + sin(_time * 0.8 + phase) * 0.1
		# Wrap when off-screen
		if p.position.y < -10:
			p.position.y = 1090
			p.position.x = randf_range(0, 1920)


func _run_sequence() -> void:
	# Fade in from black (0.8s)
	var fade_in = create_tween()
	fade_in.tween_property(_fade_overlay, "modulate:a", 0.0, 0.8)
	await fade_in.finished

	# Hold (1.5s)
	await get_tree().create_timer(1.5).timeout

	# Fade out to black (0.5s)
	var fade_out = create_tween()
	fade_out.tween_property(_fade_overlay, "modulate:a", 1.0, 0.5)
	await fade_out.finished

	# Transition to title screen
	SceneTransition.change_scene("res://scenes/title/title_screen.tscn")
