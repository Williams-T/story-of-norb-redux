extends Node

# Scene/world signals
signal scene_transition_requested(scene_path: String, transition: String)
signal scene_transition_finished()

# Combat signals
signal combat_started(enemy_group: Resource)
signal combat_ended(result: String)   # "victory", "defeat", "fled"

# Dialogue signals
signal dialogue_started(dialogue_path: String)
signal dialogue_finished()

# Inventory signals
signal item_acquired(item: Resource)
signal item_used(item: Resource)
signal item_dropped(item: Resource)

# Game state signals
signal flag_changed(flag_name: String, value: Variant)
signal gold_changed(new_amount: int)

# Audio signals
signal music_change_requested(track_path: String, transition: String)
signal sfx_requested(sfx_path: String)
