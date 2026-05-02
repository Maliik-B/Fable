extends Control
## Shop scene. Buy cards, remove a card from your deck, then leave.

const CARD_REMOVE_COST := 50
const CARD_COUNT := 5
const RELIC_COUNT := 2

var shop_cards: Array[CardData] = []
var card_prices: Dictionary = {} # CardData -> int
var shop_relics: Array[RelicData] = []
var relic_prices: Dictionary = {} # RelicData -> int
var card_row: HBoxContainer
var relic_row: HBoxContainer
var gold_label: Label
var info_label: Label
var deck_section: VBoxContainer
var deck_visible := false


func _ready() -> void:
	_generate_shop()
	_build_ui()
	AudioManager.play_music("shop")


func _generate_shop() -> void:
	shop_cards = CardPool.get_reward_choices(RngManager.loot_rng, CARD_COUNT)
	for card in shop_cards:
		match card.rarity:
			CardData.CardRarity.COMMON:
				card_prices[card] = 40 + RngManager.loot_rng.randi_range(-5, 5)
			CardData.CardRarity.UNCOMMON:
				card_prices[card] = 60 + RngManager.loot_rng.randi_range(-5, 10)
			CardData.CardRarity.RARE:
				card_prices[card] = 90 + RngManager.loot_rng.randi_range(-5, 15)
			_:
				card_prices[card] = 50

	# Generate relics for sale
	var owned = RunManager.get_owned_relic_names()
	shop_relics = RelicPool.get_reward_choices(RngManager.loot_rng, RELIC_COUNT, owned)
	for relic in shop_relics:
		match relic.rarity:
			RelicData.RelicRarity.COMMON:
				relic_prices[relic] = 100 + RngManager.loot_rng.randi_range(-10, 10)
			RelicData.RelicRarity.UNCOMMON:
				relic_prices[relic] = 150 + RngManager.loot_rng.randi_range(-10, 15)
			RelicData.RelicRarity.RARE:
				relic_prices[relic] = 200 + RngManager.loot_rng.randi_range(-10, 20)
			_:
				relic_prices[relic] = 150


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
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Header
	var title = Label.new()
	title.text = "Shop"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))
	vbox.add_child(title)

	# Gold display
	gold_label = Label.new()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 24)
	gold_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	vbox.add_child(gold_label)

	# Info label
	info_label = Label.new()
	info_label.text = "Click a card to buy it"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info_label)

	# Cards for sale
	var scroll = ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	card_row = HBoxContainer.new()
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 24)
	scroll.add_child(card_row)

	_refresh_shop_cards()

	# Relics for sale
	if shop_relics.size() > 0:
		var relic_header = Label.new()
		relic_header.text = "Relics"
		relic_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		relic_header.add_theme_font_size_override("font_size", 22)
		relic_header.add_theme_color_override("font_color", Color(0.7, 0.6, 0.8))
		vbox.add_child(relic_header)

		relic_row = HBoxContainer.new()
		relic_row.alignment = BoxContainer.ALIGNMENT_CENTER
		relic_row.add_theme_constant_override("separation", 24)
		vbox.add_child(relic_row)

		_refresh_shop_relics()

	# Bottom buttons
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	vbox.add_child(btn_row)

	var remove_btn = Button.new()
	remove_btn.text = "Remove a Card (%d gold)" % CARD_REMOVE_COST
	remove_btn.custom_minimum_size = Vector2(260, 50)
	remove_btn.add_theme_font_size_override("font_size", 18)
	remove_btn.pressed.connect(_on_remove_pressed)
	btn_row.add_child(remove_btn)

	var leave_btn = Button.new()
	leave_btn.text = "Leave Shop"
	leave_btn.custom_minimum_size = Vector2(200, 50)
	leave_btn.add_theme_font_size_override("font_size", 18)
	leave_btn.pressed.connect(_on_leave)
	btn_row.add_child(leave_btn)

	# Deck section (hidden by default, shown for card removal)
	deck_section = VBoxContainer.new()
	deck_section.add_theme_constant_override("separation", 10)
	deck_section.visible = false
	vbox.add_child(deck_section)

	_update_gold()


func _update_gold() -> void:
	gold_label.text = "Gold: %d" % RunManager.gold


func _refresh_shop_cards() -> void:
	for child in card_row.get_children():
		child.queue_free()

	for card in shop_cards:
		var price = card_prices[card]
		var panel = _create_shop_card(card, price)
		card_row.add_child(panel)


# ============================================================
# SHOP CARD PANEL
# ============================================================

func _create_shop_card(card: CardData, price: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 280)

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12

	var can_afford = RunManager.gold >= price

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

	if not can_afford:
		panel.modulate = Color(0.5, 0.5, 0.5)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Price tag
	var price_lbl = Label.new()
	price_lbl.text = "%d gold" % price
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.add_theme_font_size_override("font_size", 16)
	if can_afford:
		price_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	else:
		price_lbl.add_theme_color_override("font_color", Color(0.7, 0.3, 0.3))
	vbox.add_child(price_lbl)

	# Energy cost
	var cost_lbl = Label.new()
	cost_lbl.text = str(card.energy_cost)
	cost_lbl.add_theme_font_size_override("font_size", 24)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.3))
	vbox.add_child(cost_lbl)

	# Card name
	var name_lbl = Label.new()
	name_lbl.text = card.card_name
	name_lbl.add_theme_font_size_override("font_size", 18)
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
	type_lbl.add_theme_font_size_override("font_size", 12)
	type_lbl.add_theme_color_override("font_color", rarity_colors[card.rarity])
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_lbl)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = card.get_generated_description()
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	# Exhaust tag
	if card.exhaust:
		var ex_lbl = Label.new()
		ex_lbl.text = "Exhaust"
		ex_lbl.add_theme_font_size_override("font_size", 12)
		ex_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
		ex_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(ex_lbl)

	_ignore_mouse_recursive(vbox)

	panel.gui_input.connect(_on_shop_card_input.bind(card))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if can_afford:
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return panel


# ============================================================
# BUYING CARDS
# ============================================================

func _on_shop_card_input(event: InputEvent, card: CardData) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var price = card_prices.get(card, 0)
	if RunManager.gold < price:
		info_label.text = "Not enough gold!"
		return

	RunManager.add_gold(-price)
	RunManager.add_card_to_deck(card)
	shop_cards.erase(card)
	card_prices.erase(card)
	info_label.text = "Bought %s!" % card.card_name
	AudioManager.play_sfx("shop_buy")
	_update_gold()
	_refresh_shop_cards()


# ============================================================
# BUYING RELICS
# ============================================================

func _refresh_shop_relics() -> void:
	if not relic_row:
		return
	for child in relic_row.get_children():
		child.queue_free()
	for relic in shop_relics:
		var price = relic_prices[relic]
		relic_row.add_child(_create_shop_relic(relic, price))


func _create_shop_relic(relic: RelicData, price: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 140)

	var rarity_colors = {
		RelicData.RelicRarity.COMMON: Color(0.6, 0.6, 0.6),
		RelicData.RelicRarity.UNCOMMON: Color(0.3, 0.7, 0.9),
		RelicData.RelicRarity.RARE: Color(0.95, 0.8, 0.2),
		RelicData.RelicRarity.BOSS: Color(0.9, 0.3, 0.3),
	}
	var border_color = rarity_colors.get(relic.rarity, Color(0.5, 0.5, 0.5))
	var can_afford = RunManager.gold >= price

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.bg_color = Color(0.14, 0.12, 0.18)
	style.border_color = border_color
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	if not can_afford:
		panel.modulate = Color(0.5, 0.5, 0.5)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var price_lbl = Label.new()
	price_lbl.text = "%d gold" % price
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.add_theme_font_size_override("font_size", 16)
	price_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.85, 0.3) if can_afford else Color(0.7, 0.3, 0.3))
	vbox.add_child(price_lbl)

	var name_lbl = Label.new()
	name_lbl.text = relic.relic_name
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", border_color)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = relic.description
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	_ignore_mouse_recursive(vbox)

	panel.gui_input.connect(_on_shop_relic_input.bind(relic))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if can_afford:
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return panel


func _on_shop_relic_input(event: InputEvent, relic: RelicData) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var price = relic_prices.get(relic, 0)
	if RunManager.gold < price:
		info_label.text = "Not enough gold!"
		return

	RunManager.add_gold(-price)
	RunManager.add_relic(relic)
	shop_relics.erase(relic)
	relic_prices.erase(relic)
	info_label.text = "Bought %s!" % relic.relic_name
	AudioManager.play_sfx("shop_buy")
	_update_gold()
	_refresh_shop_relics()


# ============================================================
# REMOVING CARDS
# ============================================================

func _on_remove_pressed() -> void:
	# Always allow closing the deck section
	if deck_visible:
		deck_section.visible = false
		deck_visible = false
		info_label.text = "Click a card to buy it"
		return

	if RunManager.gold < CARD_REMOVE_COST:
		info_label.text = "Not enough gold! (Need %d)" % CARD_REMOVE_COST
		return

	if RunManager.current_deck.size() <= 1:
		info_label.text = "Can't remove your last card!"
		return

	_show_deck_for_removal()


func _show_deck_for_removal() -> void:
	deck_visible = true
	deck_section.visible = true
	info_label.text = "Click a card to remove it (%d gold)" % CARD_REMOVE_COST

	# Clear previous
	for child in deck_section.get_children():
		child.queue_free()

	var header_row = HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 20)
	deck_section.add_child(header_row)

	var header = Label.new()
	header.text = "Your Deck (%d cards)" % RunManager.current_deck.size()
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	header_row.add_child(header)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 36)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_on_cancel_remove)
	header_row.add_child(cancel_btn)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 200
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_section.add_child(scroll)

	var flow = HBoxContainer.new()
	flow.add_theme_constant_override("separation", 8)
	scroll.add_child(flow)

	for i in RunManager.current_deck.size():
		var card = RunManager.current_deck[i]
		var btn = Button.new()
		btn.text = card.card_name
		btn.custom_minimum_size = Vector2(140, 40)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_remove_card.bind(i))
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		# Color by type
		var btn_style = StyleBoxFlat.new()
		btn_style.set_corner_radius_all(6)
		btn_style.content_margin_left = 8
		btn_style.content_margin_right = 8
		btn_style.content_margin_top = 6
		btn_style.content_margin_bottom = 6
		match card.card_type:
			CardData.CardType.ATTACK:
				btn_style.bg_color = Color(0.3, 0.15, 0.15)
				btn_style.border_color = Color(0.6, 0.25, 0.25)
			CardData.CardType.SKILL:
				btn_style.bg_color = Color(0.15, 0.18, 0.3)
				btn_style.border_color = Color(0.25, 0.4, 0.6)
			CardData.CardType.POWER:
				btn_style.bg_color = Color(0.3, 0.27, 0.12)
				btn_style.border_color = Color(0.6, 0.5, 0.15)
		btn_style.set_border_width_all(2)
		btn.add_theme_stylebox_override("normal", btn_style)

		var hover_style = btn_style.duplicate()
		hover_style.bg_color = hover_style.bg_color.lightened(0.2)
		btn.add_theme_stylebox_override("hover", hover_style)

		flow.add_child(btn)


func _on_cancel_remove() -> void:
	deck_section.visible = false
	deck_visible = false
	info_label.text = "Click a card to buy it"


func _on_remove_card(index: int) -> void:
	var card = RunManager.current_deck[index]
	RunManager.add_gold(-CARD_REMOVE_COST)
	RunManager.remove_card_from_deck(index)
	AudioManager.play_sfx("card_exhaust")
	info_label.text = "Removed %s!" % card.card_name
	_update_gold()
	_show_deck_for_removal()


# ============================================================
# LEAVE
# ============================================================

func _on_leave() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")


func _ignore_mouse_recursive(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_ignore_mouse_recursive(child)
