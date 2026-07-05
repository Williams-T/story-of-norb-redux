extends Node

@warning_ignore_start("unused_signal")

# Utility Signals
signal player_movement_locked()
signal player_movement_unlocked()

# Scene/world signals
signal scene_transition_requested(scene_path: String, transition: String)
signal scene_transition_finished()

# Combat signals
signal combat_started(enemy_group: Resource)
signal combat_ended(result: String)   # "victory", "defeat", "fled"
signal combat_queued(queue: Array[BattleCombatant])
signal combat_visuals_ready()
signal combat_animations_finished()
signal combat_action_resolving()
signal combat_events_committed()
signal combat_log_updated(text: String) # anything that happens in battle gets narrated here: "Norb attacks!", "Slime is poisoned!", "Norb takes 14 damage!"
signal turn_started(combatant: BattleCombatant) # fired when a new combatant's turn begins, UI uses this to highlight whose turn it is
signal combatant_damaged(combatant: BattleCombatant, amount: int) # fired after damage is applied, HP bar animates in response
signal combatant_healed(combatant: BattleCombatant, amount: int) # same pattern for healing
signal combatant_status_applied(combatant: BattleCombatant, status: StatusEffect) # UI shows the status icon
signal combatant_status_expired(combatant: BattleCombatant, status: StatusEffect) # UI removes the status icon
signal combatant_died(combatant: BattleCombatant) # UI plays death state, CombatManager checks victory/defeat condition
signal player_turn_started()
signal player_action_selected(action: BattleAction)
signal player_targets_selected(targets: Array[BattleCombatant])
signal player_item_selected(item : ItemResource)
signal player_flee_attempted()
signal target_select_requested(targets: Array[BattleCombatant])
signal all_targets()

# Dungeon signals
signal encounter_triggered(group: EnemyGroupResource)

# Dialogue signals
signal dialogue_started(sequence: DialogueSequence)
signal advance_dialogue_requested()
signal dialogue_line_advanced(line : DialogueLine)
signal dialogue_choices_available(choices: Array[DialogueChoice])
signal dialogue_choice_selected(choice : DialogueChoice)
signal dialogue_finished()

# Inventory signals
signal item_acquired(item: Resource)
signal item_used(item: Resource)
signal item_dropped(item: Resource)

# Shop signals
signal shop_interaction_requested(shop: ShopResource)
signal shop_opened(shop: ShopResource)
signal shop_closed()
signal item_purchased(item: ItemResource, quantity: int)
signal item_sold(item: ItemResource, quantity: int)

# Game state signals
signal flag_changed(flag_name: String, value: Variant)
signal gold_changed(new_amount: int)

# Progression signals
signal level_increased(character : PartyMemberResource, new_value : int)
signal stat_increased(character : PartyMemberResource, stat : String, new_value : int)

# Audio signals
signal music_change_requested(track_path: String, transition: String)
signal sfx_requested(sfx_path: String)

# Manipulation signals
signal interact_pressed
signal world_menu_opened
signal world_menu_closed
