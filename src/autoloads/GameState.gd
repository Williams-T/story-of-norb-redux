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
var previous_player_location : Vector2 = Vector2(-1, -1)

var pending_enemy_group : EnemyGroupResource = null
var in_combat := false

func _ready() -> void:
	EventBus.combat_started.connect(func(enemy_group):in_combat=true)
	EventBus.combat_ended.connect(func(result):in_combat=false)
	party.append(load("res://data/characters/norb_party_member.tres").duplicate(true))
	party.append(load("res://data/characters/dog_party_member.tres").duplicate(true))
	inventory.append_array([load("res://data/items/elixer.tres"), load("res://data/items/magicrestore.tres"), load("res://data/items/potion.tres"), load("res://data/items/sword.tres")])

func set_flag(flag_name: String, value: Variant) -> void:
	flags[flag_name] = value
	EventBus.flag_changed.emit(flag_name, value)


func get_flag(flag_name: String, default: Variant = null) -> Variant:
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
	var dropped_items = randi_range(0, drop_table.size()-1)
	for i in dropped_items:
		give_item(drop_table[i])

func give_item(item : ItemResource):
	pending_inventory.append(item)
	EventBus.item_dropped.emit(item)

func inventory_transfer():
	for i in pending_inventory:
		inventory.append(i)
		EventBus.item_acquired.emit(i)
	pending_inventory = []
