extends Control
## Rest site. Choose to heal 30% max HP or upgrade a card.

var main_vbox: VBoxContainer
var info_label: Label
var choice_container: HBoxContainer
var deck_container: Control


func _ready() -> void:
	_build_ui()
	AudioManager.play_music("rest")


# ============================================================
# UI
# ============================================================

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Warm vignette for rest
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
	COLOR = vec4(0.0, 0.02, 0.0, vig * 0.5);
}
"""
	mat.shader = shader
	vignette.material = mat
	add_child(vignette)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 30)
	margin.add_child(main_vbox)

	# Title
	var title = Label.new()
	title.text = "Rest Site"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
	main_vbox.add_child(title)

	# HP display
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 22)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	main_vbox.add_child(info_label)
	_update_info()

	# Choice buttons
	choice_container = HBoxContainer.new()
	choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_container.add_theme_constant_override("separation", 40)
	main_vbox.add_child(choice_container)

	var heal_amount = int(RunManager.max_hp * 0.3)
	_add_choice_button("Rest", "Heal %d HP (30%%)" % heal_amount,
		Color(0.3, 0.8, 0.4), _on_heal)

	var has_upgradable = _get_upgradable_cards().size() > 0
	var upgrade_btn = _add_choice_button("Smith", "Upgrade a card",
		Color(0.9, 0.6, 0.2), _on_upgrade)
	if not has_upgradable:
		upgrade_btn.modulate = Color(0.4, 0.4, 0.4)
		upgrade_btn.disabled = true

	# Deck section (hidden until upgrade chosen)
	deck_container = VBoxContainer.new()
	deck_container.add_theme_constant_override("separation", 14)
	deck_container.visible = false
	main_vbox.add_child(deck_container)


func _update_info() -> void:
	info_label.text = "HP: %d / %d" % [RunManager.current_hp, RunManager.max_hp]


func _add_choice_button(title_text: String, desc_text: String,
		color: Color, callback: Callable) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(280, 120)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(callback)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.bg_color = color.darkened(0.7)
	style.border_color = color
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = color.darkened(0.5)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = color.darkened(0.8)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style = style.duplicate()
	disabled_style.bg_color = Color(0.15, 0.15, 0.15)
	disabled_style.border_color = Color(0.3, 0.3, 0.3)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# Build label content manually since Button only supports single-line text
	btn.text = "%s\n%s" % [title_text, desc_text]

	choice_container.add_child(btn)
	return btn


# ============================================================
# HEAL
# ============================================================

func _on_heal() -> void:
	var heal_amount = int(RunManager.max_hp * 0.3)
	RunManager.heal(heal_amount)
	AudioManager.play_sfx("heal")
	info_label.text = "Healed %d HP! (HP: %d / %d)" % [
		heal_amount, RunManager.current_hp, RunManager.max_hp]
	info_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	_show_done()


# ============================================================
# UPGRADE
# ============================================================

func _on_upgrade() -> void:
	var upgradable = _get_upgradable_cards()
	if upgradable.size() == 0:
		info_label.text = "No cards to upgrade!"
		return

	choice_container.visible = false
	info_label.text = "Choose a card to upgrade"
	deck_container.visible = true

	for child in deck_container.get_children():
		child.queue_free()

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 320
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_container.add_child(scroll)

	var card_row = HBoxContainer.new()
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 20)
	scroll.add_child(card_row)

	for i in RunManager.current_deck.size():
		var card = RunManager.current_deck[i]
		if card.upgraded:
			continue
		var panel = _create_upgrade_card(card, i)
		card_row.add_child(panel)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(160, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.pressed.connect(_on_upgrade_back)
	deck_container.add_child(back_btn)
	# Center the back button
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _get_upgradable_cards() -> Array[CardData]:
	var result: Array[CardData] = []
	for card in RunManager.current_deck:
		if not card.upgraded:
			result.append(card)
	return result


func _create_upgrade_card(card: CardData, index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 280)

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12

	match card.card_type:
		CardData.CardType.ATTACK:
			style.bg_color = Color(0.25, 0.12, 0.12)
			style.border_color = Color(0.8, 0.3, 0.3)
		CardData.CardType.SKILL:
			style.bg_color = Color(0.12, 0.15, 0.25)
			style.border_color = Color(0.3, 0.5, 0.8)
		CardData.CardType.POWER:
			style.bg_color = Color(0.25, 0.22, 0.1)
			style.border_color = Color(0.8, 0.7, 0.2)

	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Cost
	var cost_lbl = Label.new()
	cost_lbl.text = str(card.energy_cost)
	cost_lbl.add_theme_font_size_override("font_size", 24)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.3))
	vbox.add_child(cost_lbl)

	# Name
	var name_lbl = Label.new()
	name_lbl.text = card.card_name
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Current description
	var desc_lbl = Label.new()
	desc_lbl.text = card.get_generated_description()
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	# Arrow
	var arrow = Label.new()
	arrow.text = ">> Upgrade >>"
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(arrow)

	# Preview upgraded description
	var preview = card.duplicate_card()
	preview.upgrade_card()
	var preview_lbl = Label.new()
	preview_lbl.text = preview.get_generated_description()
	preview_lbl.add_theme_font_size_override("font_size", 14)
	preview_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(preview_lbl)

	_ignore_mouse_recursive(vbox)

	panel.gui_input.connect(_on_upgrade_card_input.bind(index))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return panel


func _on_upgrade_card_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	_upgrade_card(index)


func _on_upgrade_back() -> void:
	deck_container.visible = false
	choice_container.visible = true
	_update_info()
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))


func _upgrade_card(index: int) -> void:
	var card = RunManager.current_deck[index]
	card.upgrade_card()
	AudioManager.play_sfx("card_upgrade")
	info_label.text = "Upgraded %s!" % card.card_name
	info_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
	deck_container.visible = false
	_show_done()


# ============================================================
# DONE
# ============================================================

func _show_done() -> void:
	choice_container.visible = false

	var leave_btn = Button.new()
	leave_btn.text = "Continue"
	leave_btn.custom_minimum_size = Vector2(200, 55)
	leave_btn.add_theme_font_size_override("font_size", 20)
	leave_btn.pressed.connect(_on_leave)
	main_vbox.add_child(leave_btn)


func _on_leave() -> void:
	SceneTransition.change_scene("res://scenes/map/map_scene.tscn")


func _ignore_mouse_recursive(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_ignore_mouse_recursive(child)
