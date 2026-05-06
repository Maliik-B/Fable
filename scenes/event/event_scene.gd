extends Control
## Narrative event scene. Shows story text, player choices, consequences,
## and optional card reward / card removal follow-ups.

var event: EventData
var main_vbox: VBoxContainer
var info_label: Label
var desc_label: RichTextLabel
var choice_container: VBoxContainer
var follow_up_container: VBoxContainer


func _ready() -> void:
	event = EventPool.get_random_event(RngManager.event_rng)
	_build_ui()
	_show_choices()
	AudioManager.play_music("rest")


# ============================================================
# UI
# ============================================================

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.09, 0.05, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Moody vignette for events
	var vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv) * 1.5;
	float vig = smoothstep(0.2, 1.0, dist);
	COLOR = vec4(0.02, 0.0, 0.04, vig * 0.6);
}
"""
	mat.shader = shader
	vignette.material = mat
	add_child(vignette)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	add_child(margin)

	main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)

	# Title
	var title = Label.new()
	title.text = event.event_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.8, 0.55, 0.9))
	main_vbox.add_child(title)

	# Description
	desc_label = RichTextLabel.new()
	desc_label.text = event.description
	desc_label.bbcode_enabled = false
	desc_label.fit_content = true
	desc_label.scroll_active = false
	desc_label.custom_minimum_size.y = 80
	desc_label.add_theme_font_size_override("normal_font_size", 18)
	desc_label.add_theme_color_override("default_color", Color(0.8, 0.78, 0.7))
	main_vbox.add_child(desc_label)

	# HP / Gold bar
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(info_label)
	_update_info()

	# Choice buttons container
	choice_container = VBoxContainer.new()
	choice_container.add_theme_constant_override("separation", 12)
	main_vbox.add_child(choice_container)

	# Follow-up area (card reward / removal)
	follow_up_container = VBoxContainer.new()
	follow_up_container.add_theme_constant_override("separation", 14)
	follow_up_container.visible = false
	main_vbox.add_child(follow_up_container)


func _update_info() -> void:
	info_label.text = "HP: %d / %d    Gold: %d" % [
		RunManager.current_hp, RunManager.max_hp, RunManager.gold]


# ============================================================
# CHOICES
# ============================================================

func _show_choices() -> void:
	for i in event.choices.size():
		var choice = event.choices[i]
		var btn = _make_choice_button(choice, i)
		# Disable choices the player can't afford
		if choice.gold_change < 0 and RunManager.gold < -choice.gold_change:
			btn.disabled = true
			btn.text += " (Not enough gold)"
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		choice_container.add_child(btn)


func _make_choice_button(choice: EventData.EventChoice, index: int) -> Button:
	var btn = Button.new()
	btn.text = "[%d] %s" % [index + 1, choice.text]
	btn.custom_minimum_size = Vector2(0, 50)
	btn.add_theme_font_size_override("font_size", 17)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.bg_color = Color(0.14, 0.11, 0.2)
	style.border_color = Color(0.55, 0.4, 0.7)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.22, 0.16, 0.3)
	hover_style.border_color = Color(0.8, 0.55, 0.9)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.07, 0.14)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style = style.duplicate()
	disabled_style.bg_color = Color(0.14, 0.11, 0.2)
	disabled_style.border_color = Color(0.3, 0.3, 0.3)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	btn.pressed.connect(_on_choice_selected.bind(index))
	return btn


func _on_choice_selected(index: int) -> void:
	AudioManager.play_sfx("button_click")
	var choice = event.choices[index]
	_apply_effects(choice)
	choice_container.visible = false

	# Show result text
	desc_label.text = choice.result_text
	_update_info()
	_show_effect_summary(choice)

	# Check if player died from event effects
	if RunManager.current_hp <= 0:
		_show_game_over()
		return

	# Handle follow-ups
	if choice.card_reward:
		_show_card_reward()
	elif choice.remove_card:
		_show_card_removal()
	else:
		_show_done()


# ============================================================
# APPLY EFFECTS
# ============================================================

func _apply_effects(choice: EventData.EventChoice) -> void:
	if choice.hp_change != 0:
		if choice.hp_change > 0:
			RunManager.heal(choice.hp_change)
		else:
			# Apply damage directly without triggering run end — we handle death in the UI
			RunManager.current_hp = max(0, RunManager.current_hp - (-choice.hp_change))

	if choice.max_hp_change != 0:
		RunManager.max_hp += choice.max_hp_change
		if choice.max_hp_change > 0:
			RunManager.current_hp += choice.max_hp_change

	if choice.gold_change != 0:
		RunManager.gold = max(0, RunManager.gold + choice.gold_change)

	if choice.passion_change != 0:
		RunManager.change_passion(choice.passion_change)


func _show_effect_summary(choice: EventData.EventChoice) -> void:
	var parts: PackedStringArray = []
	if choice.hp_change > 0:
		parts.append("+%d HP" % choice.hp_change)
	elif choice.hp_change < 0:
		parts.append("%d HP" % choice.hp_change)
	if choice.max_hp_change > 0:
		parts.append("+%d Max HP" % choice.max_hp_change)
	elif choice.max_hp_change < 0:
		parts.append("%d Max HP" % choice.max_hp_change)
	if choice.gold_change > 0:
		parts.append("+%d Gold" % choice.gold_change)
	elif choice.gold_change < 0:
		parts.append("%d Gold" % choice.gold_change)
	if choice.passion_change > 0:
		parts.append("+%d Passion" % choice.passion_change)
	elif choice.passion_change < 0:
		parts.append("%d Passion" % choice.passion_change)

	if parts.size() > 0:
		var summary = Label.new()
		summary.text = ", ".join(parts)
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary.add_theme_font_size_override("font_size", 20)
		summary.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		main_vbox.add_child(summary)
		main_vbox.move_child(summary, main_vbox.get_child_count() - 2)


# ============================================================
# CARD REWARD (pick 1 of 3)
# ============================================================

func _show_card_reward() -> void:
	follow_up_container.visible = true
	for child in follow_up_container.get_children():
		child.queue_free()

	var header = Label.new()
	header.text = "Choose a card to add:"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	follow_up_container.add_child(header)

	var cards = CardPool.get_reward_choices(RngManager.loot_rng, 3)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 200
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_up_container.add_child(scroll)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	scroll.add_child(row)

	for card in cards:
		var panel = _create_card_panel(card)
		row.add_child(panel)

	var skip_btn = Button.new()
	skip_btn.text = "Skip"
	skip_btn.custom_minimum_size = Vector2(140, 40)
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip_btn.pressed.connect(_on_skip_reward)
	follow_up_container.add_child(skip_btn)


func _create_card_panel(card: CardData) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 180)

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
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

	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var cost_lbl = Label.new()
	cost_lbl.text = str(card.energy_cost)
	cost_lbl.add_theme_font_size_override("font_size", 22)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.3))
	vbox.add_child(cost_lbl)

	var name_lbl = Label.new()
	name_lbl.text = card.card_name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = card.get_generated_description()
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	_ignore_mouse_recursive(vbox)

	panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			RunManager.add_card_to_deck(card)
			follow_up_container.visible = false
			info_label.text += "  (Added %s)" % card.card_name
			_show_done()
	)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return panel


func _on_skip_reward() -> void:
	follow_up_container.visible = false
	_show_done()


# ============================================================
# CARD REMOVAL (pick 1 from deck)
# ============================================================

func _show_card_removal() -> void:
	if RunManager.current_deck.size() == 0:
		_show_done()
		return

	follow_up_container.visible = true
	for child in follow_up_container.get_children():
		child.queue_free()

	var header = Label.new()
	header.text = "Choose a card to remove:"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	follow_up_container.add_child(header)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 200
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_up_container.add_child(scroll)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	scroll.add_child(row)

	for i in RunManager.current_deck.size():
		var card = RunManager.current_deck[i]
		var panel = _create_removal_panel(card, i)
		row.add_child(panel)

	var skip_btn = Button.new()
	skip_btn.text = "Skip"
	skip_btn.custom_minimum_size = Vector2(140, 40)
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip_btn.pressed.connect(_on_skip_removal)
	follow_up_container.add_child(skip_btn)


func _create_removal_panel(card: CardData, index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 140)

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
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

	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var cost_lbl = Label.new()
	cost_lbl.text = str(card.energy_cost)
	cost_lbl.add_theme_font_size_override("font_size", 20)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.3))
	vbox.add_child(cost_lbl)

	var name_lbl = Label.new()
	name_lbl.text = card.card_name
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = card.get_generated_description()
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	_ignore_mouse_recursive(vbox)

	panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var removed_name = card.card_name
			RunManager.remove_card_from_deck(index)
			follow_up_container.visible = false
			info_label.text += "  (Removed %s)" % removed_name
			_show_done()
	)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return panel


func _on_skip_removal() -> void:
	follow_up_container.visible = false
	_show_done()


# ============================================================
# DONE
# ============================================================

func _show_done() -> void:
	var leave_btn = Button.new()
	leave_btn.text = "Continue"
	leave_btn.custom_minimum_size = Vector2(200, 55)
	leave_btn.add_theme_font_size_override("font_size", 20)
	leave_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	leave_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	leave_btn.pressed.connect(_on_leave)
	main_vbox.add_child(leave_btn)


func _show_game_over() -> void:
	follow_up_container.visible = false
	info_label.text = "HP: 0 / %d" % RunManager.max_hp
	info_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))

	var death_label = Label.new()
	death_label.text = "You have perished."
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.add_theme_font_size_override("font_size", 28)
	death_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	main_vbox.add_child(death_label)

	var game_over_btn = Button.new()
	game_over_btn.text = "Game Over"
	game_over_btn.custom_minimum_size = Vector2(200, 55)
	game_over_btn.add_theme_font_size_override("font_size", 20)
	game_over_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	game_over_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	game_over_btn.pressed.connect(_on_game_over)
	main_vbox.add_child(game_over_btn)


func _on_game_over() -> void:
	RunManager.end_run(false)
	SceneTransition.change_scene("res://scenes/game_over/game_over_scene.tscn")


func _on_leave() -> void:
	SceneTransition.change_scene("res://scenes/map/map_scene.tscn")


func _ignore_mouse_recursive(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_ignore_mouse_recursive(child)
