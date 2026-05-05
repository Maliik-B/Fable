extends Control
## Shows 3 relic choices after elite/boss combat. Player picks one or skips.

var relic_choices: Array[RelicData] = []


func _ready() -> void:
	var is_boss = RunManager.pending_relic_is_boss
	RunManager.pending_relic_is_boss = false

	var owned = RunManager.get_owned_relic_names()
	if is_boss:
		relic_choices = RelicPool.get_boss_reward_choices(RngManager.loot_rng, owned)
	else:
		relic_choices = RelicPool.get_reward_choices(RngManager.loot_rng, 3, owned)

	_build_ui()


# ============================================================
# UI
# ============================================================

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.08)
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
	float vig = smoothstep(0.3, 1.0, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vig * 0.5);
}
"""
	mat.shader = shader
	vignette.material = mat
	add_child(vignette)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Relic Reward"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.95, 0.7, 0.2))
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Choose a relic"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(subtitle)

	# Relic choices
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	vbox.add_child(row)

	for relic in relic_choices:
		row.add_child(_create_relic_panel(relic))

	if relic_choices.size() == 0:
		subtitle.text = "You've collected all available relics!"
		subtitle.add_theme_color_override("font_color", Color(0.95, 0.7, 0.2))

	# Skip button
	var skip_btn = Button.new()
	skip_btn.text = "Skip"
	skip_btn.custom_minimum_size = Vector2(180, 50)
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip_btn.pressed.connect(_on_skip)
	vbox.add_child(skip_btn)

	# Owned relics display
	if RunManager.relics.size() > 0:
		var owned_label = Label.new()
		owned_label.text = "Owned: " + ", ".join(RunManager.get_owned_relic_names())
		owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owned_label.add_theme_font_size_override("font_size", 14)
		owned_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		owned_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(owned_label)


func _create_relic_panel(relic: RelicData) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 180)

	var rarity_colors = {
		RelicData.RelicRarity.COMMON: Color(0.6, 0.6, 0.6),
		RelicData.RelicRarity.UNCOMMON: Color(0.3, 0.7, 0.9),
		RelicData.RelicRarity.RARE: Color(0.95, 0.8, 0.2),
		RelicData.RelicRarity.BOSS: Color(0.9, 0.3, 0.3),
	}
	var border_color = rarity_colors.get(relic.rarity, Color(0.5, 0.5, 0.5))

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.bg_color = Color(0.14, 0.12, 0.18)
	style.border_color = border_color
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Name
	var name_lbl = Label.new()
	name_lbl.text = relic.relic_name
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", border_color)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Rarity
	var rarity_names = ["Common", "Uncommon", "Rare", "Boss"]
	var rarity_lbl = Label.new()
	rarity_lbl.text = rarity_names[relic.rarity]
	rarity_lbl.add_theme_font_size_override("font_size", 14)
	rarity_lbl.add_theme_color_override("font_color", border_color.darkened(0.3))
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_lbl)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = relic.description
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	_ignore_mouse_recursive(vbox)

	panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_pick_relic(relic)
	)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.pivot_offset = Vector2(120, 90)

	panel.mouse_entered.connect(func():
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(panel, "scale", Vector2(1.06, 1.06), 0.12)
	)
	panel.mouse_exited.connect(func():
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(panel, "scale", Vector2.ONE, 0.12)
	)

	return panel


func _pick_relic(relic: RelicData) -> void:
	AudioManager.play_sfx("relic_acquire")
	RunManager.add_relic(relic)
	_go_to_card_reward()


func _on_skip() -> void:
	_go_to_card_reward()


func _go_to_card_reward() -> void:
	SceneTransition.change_scene("res://scenes/reward/card_reward_scene.tscn")


func _ignore_mouse_recursive(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_ignore_mouse_recursive(child)
