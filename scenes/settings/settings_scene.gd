extends Control
## Settings screen — adjust audio, display, and gameplay options.

var shake_enabled: bool = true

var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_check: CheckButton
var _shake_check: CheckButton


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Vignette overlay
	_add_vignette()

	# Center wrapper
	var wrapper = CenterContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(wrapper)

	var outer_vbox = VBoxContainer.new()
	outer_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_vbox.add_theme_constant_override("separation", 20)
	wrapper.add_child(outer_vbox)

	# Title
	var title = Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4))
	outer_vbox.add_child(title)

	# Panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.1, 0.9)
	panel_style.set_corner_radius_all(10)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.4, 0.35, 0.25)
	panel_style.content_margin_left = 40
	panel_style.content_margin_right = 40
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", panel_style)
	outer_vbox.add_child(panel)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	panel.add_child(content)

	# Music Volume
	_music_slider = _add_slider_row(content, "Music Volume", _get_bus_volume_linear("Music"))
	_music_slider.value_changed.connect(_on_music_volume_changed)

	# SFX Volume
	_sfx_slider = _add_slider_row(content, "SFX Volume", _get_bus_volume_linear("SFX"))
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	# Fullscreen
	_fullscreen_check = _add_toggle_row(content, "Fullscreen",
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	# Screen Shake
	_shake_check = _add_toggle_row(content, "Screen Shake", shake_enabled)
	_shake_check.toggled.connect(_on_shake_toggled)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(220, 50)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var btn_style = StyleBoxFlat.new()
	btn_style.set_corner_radius_all(10)
	btn_style.set_border_width_all(2)
	btn_style.bg_color = Color(0.15, 0.12, 0.2)
	btn_style.border_color = Color(0.7, 0.55, 0.3)
	btn_style.content_margin_left = 16
	btn_style.content_margin_right = 16
	btn_style.content_margin_top = 8
	btn_style.content_margin_bottom = 8
	back_btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = btn_style.duplicate()
	hover_style.bg_color = Color(0.22, 0.18, 0.3)
	hover_style.border_color = Color(0.9, 0.7, 0.35)
	back_btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.08, 0.14)
	back_btn.add_theme_stylebox_override("pressed", pressed_style)
	back_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back_btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	back_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.6))

	back_btn.pressed.connect(_on_back)
	outer_vbox.add_child(back_btn)


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


func _add_slider_row(parent: VBoxContainer, label_text: String, initial_value: float) -> HSlider:
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	row.add_child(lbl)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = initial_value
	slider.custom_minimum_size = Vector2(400, 24)

	# Grabber icon color (gold tint via theme icon)
	slider.add_theme_color_override("grabber_color", Color(0.95, 0.82, 0.4))
	slider.add_theme_color_override("grabber_highlight_color", Color(1.0, 0.9, 0.55))

	row.add_child(slider)
	return slider


func _add_toggle_row(parent: VBoxContainer, label_text: String, initial_value: bool) -> CheckButton:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var toggle = CheckButton.new()
	toggle.button_pressed = initial_value
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.add_child(toggle)

	return toggle


# ============================================================
# Bus volume helpers
# ============================================================

func _get_bus_volume_linear(bus_name: String) -> float:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return 100.0
	if AudioServer.is_bus_mute(bus_idx):
		return 0.0
	var db_val: float = AudioServer.get_bus_volume_db(bus_idx)
	# Convert dB back to linear 0-100
	return clampf(db_to_linear(db_val) * 100.0, 0.0, 100.0)


func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return
	if linear_value <= 0.0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_value / 100.0))


# ============================================================
# Signal callbacks
# ============================================================

func _on_music_volume_changed(value: float) -> void:
	_set_bus_volume("Music", value)


func _on_sfx_volume_changed(value: float) -> void:
	_set_bus_volume("SFX", value)


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	AudioManager.play_sfx("button_click")
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_shake_toggled(toggled_on: bool) -> void:
	AudioManager.play_sfx("button_click")
	shake_enabled = toggled_on
	print("[Settings] Screen shake: ", "ON" if toggled_on else "OFF")


func _on_back() -> void:
	AudioManager.play_sfx("button_click")
	SceneTransition.change_scene("res://scenes/title/title_screen.tscn")
