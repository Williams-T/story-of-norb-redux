extends Node

# World flags — anything that "happened": doors opened, quests advanced,
# NPCs talked to. Key is a string, value is bool/int/String.
var flags: Dictionary = {}

# Economy
var gold: int = 0
var pending_inventory: Array[ItemResource] = []
var inventory: Array[ItemResource] = []

# Party
var party: Array[PartyMemberResource] = []

# Tracking
var current_map_path: String = ""
var save_slot: int = 0
var pending_warp_id : String = "test_town_entrance"

var pending_enemy_group : EnemyGroupResource = null

func _ready() -> void:
	party.append(load("res://data/characters/norb_party_member.tres"))

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

func inventory_drop(drop_table : Array[ItemResource]):
	if drop_table.is_empty():
		return
	var dropped_items = randi_range(0, drop_table.size())
	for i in dropped_items:
		pending_inventory.append(drop_table[i])
		EventBus.item_dropped.emit(i)

func inventory_transfer():
	for i in pending_inventory:
		inventory.append(i)
		EventBus.item_acquired.emit(i)
	pending_inventory = []
