extends CanvasLayer
## Pause menu autoload — ESC to toggle from any gameplay scene.
## Includes inline settings (volume sliders, fullscreen, screen shake).
## Process mode is ALWAYS so it works while the tree is paused.

# Scenes where ESC should NOT open the pause menu
const EXCLUDED_SCENES: PackedStringArray = [
	"TitleScreen", "title_screen",
	"CharacterSelectScene", "character_select_scene",
	"SettingsScene", "settings_scene",
	"SplashScene", "splash_scene",
	"GameOverScene", "game_over_scene",
]

var _visible := false
var _overlay: ColorRect
var _panel: PanelContainer
var _abandon_btn: Button
var _confirm_container: VBoxContainer
var _settings_container: VBoxContainer
var _main_buttons_container: VBoxContainer
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_check: CheckButton
var _shake_check: CheckButton
var _showing_settings := false
var _showing_confirm := false


func _ready() -> void:
	layer = 99 # Below SceneTransition (100) but above everything else
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_hide_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _showing_confirm:
			_hide_confirm()
			get_viewport().set_input_as_handled()
		elif _showing_settings:
			_hide_settings()
			get_viewport().set_input_as_handled()
		elif _visible:
			_hide_menu()
			get_viewport().set_input_as_handled()
		else:
			if _should_allow_pause():
				_show_menu()
				get_viewport().set_input_as_handled()


# ============================================================
# Scene check
# ============================================================

func _should_allow_pause() -> bool:
	var current_scene = get_tree().current_scene
	if not current_scene:
		return false
	var scene_name: String = current_scene.name
	# Also check the script/scene filename
	var scene_file: String = current_scene.scene_file_path.get_file().get_basename() if current_scene.scene_file_path else ""
	for excluded in EXCLUDED_SCENES:
		if scene_name == excluded or scene_file == excluded:
			return false
	return true


# ============================================================
# Show / Hide
# ============================================================

func _show_menu() -> void:
	_visible = true
	_overlay.visible = true
	_panel.visible = true
	get_tree().paused = true

	# Update abandon button visibility
	_abandon_btn.visible = RunManager.run_active

	# Reset sub-panels
	_showing_confirm = false
	_showing_settings = false
	_confirm_container.visible = false
	_settings_container.visible = false
	_main_buttons_container.visible = true

	# Animate in
	_overlay.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.15)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _hide_menu() -> void:
	_visible = false
	_showing_confirm = false
	_showing_settings = false
	get_tree().paused = false
	_overlay.visible = false
	_panel.visible = false


# ============================================================
# Build UI
# ============================================================

func _build_ui() -> void:
	# Semi-transparent dark overlay
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.7)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP # Block clicks to game
	add_child(_overlay)

	# Centered panel
	var wrapper = CenterContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrapper)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(460, 0)
	_panel.pivot_offset = Vector2(230, 200) # Roughly center for scale animation

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.05, 0.12, 0.95)
	panel_style.set_corner_radius_all(14)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.7, 0.55, 0.3)
	panel_style.content_margin_left = 40
	panel_style.content_margin_right = 40
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	_panel.add_theme_stylebox_override("panel", panel_style)
	wrapper.add_child(_panel)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 20)
	root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(root_vbox)

	# "PAUSED" title
	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4))
	root_vbox.add_child(title)

	# Separator
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.4, 0.35, 0.25, 0.6))
	root_vbox.add_child(sep)

	# ---- Main buttons container ----
	_main_buttons_container = VBoxContainer.new()
	_main_buttons_container.add_theme_constant_override("separation", 10)
	root_vbox.add_child(_main_buttons_container)

	var resume_btn = _create_button("Resume", 20)
	resume_btn.pressed.connect(_on_resume)
	_main_buttons_container.add_child(resume_btn)

	var settings_btn = _create_button("Settings", 18)
	settings_btn.pressed.connect(_on_settings)
	_main_buttons_container.add_child(settings_btn)

	_abandon_btn = _create_button("Abandon Run", 18)
	_abandon_btn.pressed.connect(_on_abandon)
	_main_buttons_container.add_child(_abandon_btn)

	var quit_btn = _create_button("Quit to Desktop", 18)
	quit_btn.pressed.connect(_on_quit)
	_main_buttons_container.add_child(quit_btn)

	# ---- Confirm abandon container (hidden by default) ----
	_confirm_container = VBoxContainer.new()
	_confirm_container.add_theme_constant_override("separation", 14)
	_confirm_container.visible = false
	root_vbox.add_child(_confirm_container)

	var confirm_msg = Label.new()
	confirm_msg.text = "Are you sure?\nProgress will be lost."
	confirm_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_msg.add_theme_font_size_override("font_size", 18)
	confirm_msg.add_theme_color_override("font_color", Color(0.9, 0.5, 0.4))
	_confirm_container.add_child(confirm_msg)

	var confirm_row = HBoxContainer.new()
	confirm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_row.add_theme_constant_override("separation", 20)
	_confirm_container.add_child(confirm_row)

	var yes_btn = _create_button("Yes, Abandon", 16, Vector2(180, 44))
	yes_btn.pressed.connect(_on_confirm_abandon)
	confirm_row.add_child(yes_btn)

	var no_btn = _create_button("Cancel", 16, Vector2(140, 44))
	no_btn.pressed.connect(_on_cancel_abandon)
	confirm_row.add_child(no_btn)

	# ---- Inline settings container (hidden by default) ----
	_settings_container = VBoxContainer.new()
	_settings_container.add_theme_constant_override("separation", 18)
	_settings_container.visible = false
	root_vbox.add_child(_settings_container)

	# Settings title
	var settings_title = Label.new()
	settings_title.text = "Settings"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_font_size_override("font_size", 22)
	settings_title.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	_settings_container.add_child(settings_title)

	# Music Volume
	_music_slider = _add_slider_row(_settings_container, "Music Volume", _get_bus_volume_linear("Music"))
	_music_slider.value_changed.connect(_on_music_volume_changed)

	# SFX Volume
	_sfx_slider = _add_slider_row(_settings_container, "SFX Volume", _get_bus_volume_linear("SFX"))
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	# Fullscreen
	_fullscreen_check = _add_toggle_row(_settings_container, "Fullscreen",
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	# Screen Shake
	_shake_check = _add_toggle_row(_settings_container, "Screen Shake", true)
	_shake_check.toggled.connect(_on_shake_toggled)

	# Back button to return to main pause buttons
	var settings_back_btn = _create_button("Back", 16, Vector2(160, 44))
	settings_back_btn.pressed.connect(_hide_settings)
	_settings_container.add_child(settings_back_btn)


# ============================================================
# Button factory (matches title screen style)
# ============================================================

func _create_button(text: String, font_size: int = 18, min_size: Vector2 = Vector2(320, 54)) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", font_size)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var btn_style = StyleBoxFlat.new()
	btn_style.set_corner_radius_all(10)
	btn_style.set_border_width_all(2)
	btn_style.bg_color = Color(0.15, 0.12, 0.2)
	btn_style.border_color = Color(0.7, 0.55, 0.3)
	btn_style.content_margin_left = 16
	btn_style.content_margin_right = 16
	btn_style.content_margin_top = 8
	btn_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = btn_style.duplicate()
	hover_style.bg_color = Color(0.22, 0.18, 0.3)
	hover_style.border_color = Color(0.9, 0.7, 0.35)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.08, 0.14)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.6))

	return btn


# ============================================================
# Settings sub-panel helpers (replicated from settings_scene.gd)
# ============================================================

func _add_slider_row(parent: VBoxContainer, label_text: String, initial_value: float) -> HSlider:
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	row.add_child(lbl)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = initial_value
	slider.custom_minimum_size = Vector2(360, 24)
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
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var toggle = CheckButton.new()
	toggle.button_pressed = initial_value
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.add_child(toggle)

	return toggle


# ============================================================
# Bus volume helpers (same as settings_scene.gd)
# ============================================================

func _get_bus_volume_linear(bus_name: String) -> float:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return 100.0
	if AudioServer.is_bus_mute(bus_idx):
		return 0.0
	var db_val: float = AudioServer.get_bus_volume_db(bus_idx)
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
# Signal callbacks — main buttons
# ============================================================

func _on_resume() -> void:
	AudioManager.play_sfx("button_click")
	_hide_menu()


func _on_settings() -> void:
	AudioManager.play_sfx("button_click")
	_show_settings()


func _on_abandon() -> void:
	AudioManager.play_sfx("button_click")
	_show_confirm()


func _on_quit() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().quit()


# ============================================================
# Confirm abandon sub-panel
# ============================================================

func _show_confirm() -> void:
	_showing_confirm = true
	_main_buttons_container.visible = false
	_confirm_container.visible = true


func _hide_confirm() -> void:
	_showing_confirm = false
	_confirm_container.visible = false
	_main_buttons_container.visible = true


func _on_confirm_abandon() -> void:
	AudioManager.play_sfx("button_click")
	RunManager.run_active = false
	_hide_menu()
	SceneTransition.change_scene("res://scenes/title/title_screen.tscn")


func _on_cancel_abandon() -> void:
	AudioManager.play_sfx("button_click")
	_hide_confirm()


# ============================================================
# Inline settings sub-panel
# ============================================================

func _show_settings() -> void:
	_showing_settings = true
	_main_buttons_container.visible = false
	_settings_container.visible = true
	# Refresh slider/toggle values to current state
	_music_slider.value = _get_bus_volume_linear("Music")
	_sfx_slider.value = _get_bus_volume_linear("SFX")
	_fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func _hide_settings() -> void:
	AudioManager.play_sfx("button_click")
	_showing_settings = false
	_settings_container.visible = false
	_main_buttons_container.visible = true


# ============================================================
# Signal callbacks — settings
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
	# Sync with settings scene if it has a global reference
	print("[PauseMenu] Screen shake: ", "ON" if toggled_on else "OFF")
