extends Node
## Global signal bus. All cross-system communication goes through here.
## Systems emit signals; other systems connect and react.

# -- Card events --
signal card_played(card_data: CardData, target)
signal card_drawn(card_data: CardData)
signal card_discarded(card_data: CardData)
signal card_exhausted(card_data: CardData)

# -- Combat events --
signal combat_started()
signal combat_won()
signal combat_lost()
signal player_turn_started()
signal enemy_turn_started()
signal turn_ended()
signal player_damaged(amount: int, new_hp: int)
signal enemy_damaged(enemy, amount: int, new_hp: int)
signal enemy_died(enemy)
signal block_gained(target, amount: int)

# -- Passion events --
signal passion_changed(old_value: int, new_value: int)
signal passion_tier_changed(old_tier: int, new_tier: int)

# -- Status effect events --
signal status_applied(target, effect: StatusEffectData, stacks: int)
signal status_removed(target, effect: StatusEffectData)

# -- Navigation events --
signal map_node_selected(node_data)
signal scene_transition_requested(scene_path: String)

# -- Story / VN events --
signal vn_choice_made(choice_data)

# -- Realm events --
signal realm_configured(realm_data)

# -- Run lifecycle events --
signal run_started(character: CharacterData)
signal run_ended(victory: bool)
signal act_started(act_number: int)
signal act_ended(act_number: int)

# -- Perk events --
signal perk_selected(perk: PerkData)

# -- Item events --
signal relic_acquired(relic: RelicData)
signal equipment_changed(slot, old_equipment, new_equipment)
