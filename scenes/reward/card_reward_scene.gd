extends Control
## Shows gold reward and 3 card choices after combat victory. Player picks one or skips.

var card_choices: Array[CardData] = []
var card_panels: Dictionary = {} # CardData -> PanelContainer
var gold_earned: int = 0


func _ready() -> void:
	# Award gold immediately
	gold_earned = RunManager.pending_gold_reward
	RunManager.add_gold(gold_earned)
	RunManager.pending_gold_reward = 0

	card_choices = CardPool.get_reward_choices(RngManager.loot_rng)
	_build_ui()


# ============================================================
# UI
# ============================================================

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)

	# Header
	var title = Label.new()
	title.text = "Victory!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(title)

	# Gold reward
	if gold_earned > 0:
		var gold_lbl = Label.new()
		gold_lbl.text = "+%d Gold (Total: %d)" % [gold_earned, RunManager.gold]
		gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gold_lbl.add_theme_font_size_override("font_size", 24)
		gold_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
		vbox.add_child(gold_lbl)

	# Subtitle with passion tier info
	var subtitle = Label.new()
	var tier = RunManager.get_passion_tier()
	var tier_name = PassionState.tier_name(tier)
	subtitle.text = "Choose a card — Passion: %s" % tier_name
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(subtitle)

	# Card choices
	var card_row = HBoxContainer.new()
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 40)
	vbox.add_child(card_row)

	for card in card_choices:
		var panel = _create_card_panel(card)
		card_row.add_child(panel)
		card_panels[card] = panel

	# Skip button
	var skip_btn = Button.new()
	skip_btn.text = "Skip Reward"
	skip_btn.custom_minimum_size = Vector2(200, 50)
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(_on_skip)
	vbox.add_child(skip_btn)

	# Bottom info
	var info_bar = HBoxContainer.new()
	info_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	info_bar.add_theme_constant_override("separation", 40)
	vbox.add_child(info_bar)

	var deck_lbl = Label.new()
	deck_lbl.text = "Deck: %d cards" % RunManager.current_deck.size()
	deck_lbl.add_theme_font_size_override("font_size", 16)
	deck_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	info_bar.add_child(deck_lbl)

	var hp_lbl = Label.new()
	hp_lbl.text = "HP: %d / %d" % [RunManager.current_hp, RunManager.max_hp]
	hp_lbl.add_theme_font_size_override("font_size", 16)
	hp_lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	info_bar.add_child(hp_lbl)

	var gold_total = Label.new()
	gold_total.text = "Gold: %d" % RunManager.gold
	gold_total.add_theme_font_size_override("font_size", 16)
	gold_total.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	info_bar.add_child(gold_total)


# ============================================================
# CARD PANEL
# ============================================================

func _create_card_panel(card: CardData) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 300)

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14

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
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Energy cost
	var cost_lbl = Label.new()
	cost_lbl.text = str(card.energy_cost)
	cost_lbl.add_theme_font_size_override("font_size", 28)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.3))
	vbox.add_child(cost_lbl)

	# Card name
	var name_lbl = Label.new()
	name_lbl.text = card.card_name
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Type + Rarity
	var type_names = ["Attack", "Skill", "Power"]
	var rarity_names = ["Starter", "Common", "Uncommon", "Rare"]
	var rarity_colors = [
		Color(0.5, 0.5, 0.5),
		Color(0.6, 0.6, 0.6),
		Color(0.3, 0.7, 0.9),
		Color(0.95, 0.8, 0.2),
	]
	var type_lbl = Label.new()
	type_lbl.text = "%s - %s" % [type_names[card.card_type], rarity_names[card.rarity]]
	type_lbl.add_theme_font_size_override("font_size", 14)
	type_lbl.add_theme_color_override("font_color", rarity_colors[card.rarity])
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_lbl)

	# Personality tag
	if card.personality != CardData.PersonalityType.NEUTRAL:
		var pers_lbl = Label.new()
		pers_lbl.text = _get_personality_label(card.personality)
		pers_lbl.add_theme_font_size_override("font_size", 13)
		pers_lbl.add_theme_color_override("font_color", _get_personality_color(card.personality))
		pers_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(pers_lbl)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = card.get_generated_description()
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	# Exhaust tag
	if card.exhaust:
		var ex_lbl = Label.new()
		ex_lbl.text = "Exhaust"
		ex_lbl.add_theme_font_size_override("font_size", 13)
		ex_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
		ex_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(ex_lbl)

	# Make all children pass clicks through to the panel
	_ignore_mouse_recursive(vbox)

	# Click handler
	panel.gui_input.connect(_on_card_input.bind(card))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return panel


func _ignore_mouse_recursive(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_ignore_mouse_recursive(child)


func _on_card_input(event: InputEvent, card: CardData) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	_pick_card(card)


func _pick_card(card: CardData) -> void:
	AudioManager.play_sfx("button_click")
	RunManager.add_card_to_deck(card)
	_return_to_map()


func _on_skip() -> void:
	AudioManager.play_sfx("button_click")
	_return_to_map()


func _get_personality_label(pers: CardData.PersonalityType) -> String:
	if RunManager.current_character:
		if pers == CardData.PersonalityType.PRIMARY:
			return RunManager.current_character.primary_personality
		if pers == CardData.PersonalityType.SECONDARY:
			return RunManager.current_character.secondary_personality
	return "Primary" if pers == CardData.PersonalityType.PRIMARY else "Secondary"


func _get_personality_color(pers: CardData.PersonalityType) -> Color:
	if pers == CardData.PersonalityType.PRIMARY:
		return Color(0.9, 0.5, 0.2)
	if pers == CardData.PersonalityType.SECONDARY:
		return Color(0.4, 0.6, 0.9)
	return Color(0.6, 0.6, 0.6)


func _return_to_map() -> void:
	if RunManager.pending_act_complete:
		get_tree().change_scene_to_file("res://scenes/act/act_transition_scene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
