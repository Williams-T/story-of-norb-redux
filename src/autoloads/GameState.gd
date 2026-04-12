extends Node

# World flags — anything that "happened": doors opened, quests advanced,
# NPCs talked to. Key is a string, value is bool/int/String.
var flags: Dictionary = {}

# Economy
var gold: int = 0

# Party
var party: Array = []

# Tracking
var current_map_path: String = ""
var save_slot: int = 0


func set_flag(flag_name: String, value: Variant) -> void:
	flags[flag_name] = value
	EventBus.flag_changed.emit(flag_name, value)


func get_flag(flag_name: String, default: Variant = false) -> Variant:
	return flags.get(flag_name, default)


func add_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	EventBus.gold_changed.emit(gold)
	return true
