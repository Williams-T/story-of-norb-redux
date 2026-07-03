extends Node

@warning_ignore_start("unused_variable")
@warning_ignore_start("unused_parameter")
@warning_ignore_start("narrowing_conversion")

# World flags — anything that "happened": doors opened, quests advanced,
# NPCs talked to. Key is a string, value is bool/int/String.
var flags: Dictionary = {}

# Economy
var gold: int = 0
var pending_inventory: Array[ItemResource] = []
var inventory: Array[ItemResource] = []
var item_quantities := {}

# Party
var party: Array[PartyMemberResource] = []

# Tracking
var current_map_path: String = ""
var save_slot: int = 0
var pending_warp_id : String = "test_town_entrance"
var previous_player_location : Vector2 = Vector2(-1, -1)
var previous_safe_zone : Array = [] # Scene, Warp_ID

var current_shop_id : String = ""
var shop_stock_cache: Dictionary = {}
var shopping = false
const MAX_RECENT_SHOPS := 2
var recent_shops: Array[String] = []
var shop_states: Dictionary = {}

var pending_enemy_group : EnemyGroupResource = null
var in_combat := false
var movement_locks := 0

func _ready() -> void:
	EventBus.combat_started.connect(func(enemy_group):in_combat=true)
	EventBus.combat_ended.connect(func(result):in_combat=false)
	EventBus.shop_opened.connect(func(_shop): shopping = true)
	EventBus.shop_closed.connect(func(): shopping = false)
	party.append(load("res://data/characters/norb_party_member.tres").duplicate(true))
	party.append(load("res://data/characters/dog_party_member.tres").duplicate(true))
	pending_inventory.append_array([load("res://data/items/elixer.tres").duplicate(true), load("res://data/items/magicrestore.tres").duplicate(true), load("res://data/items/potion.tres").duplicate(true), load("res://data/items/sword.tres").duplicate(true)])
	inventory_transfer()
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
	print("Item dropped: %s" % item.item_name)

func remove_item(item : ItemResource):
	if !(item_quantities.has(item.item_name)):
		return
	if item_quantities[item.item_name] > 1:
		item_quantities[item.item_name] -= 1
	else:
		for i : ItemResource in inventory:
			if i.item_name == item.item_name:
				inventory.erase(i)
				break
		item_quantities.erase(item.item_name)

func inventory_transfer():
	for i : ItemResource in pending_inventory:
		if item_quantities.has(i.item_name):
			item_quantities[i.item_name] += 1
		else:
			inventory.append(i)
			item_quantities[i.item_name] = 1
		EventBus.item_acquired.emit(i)
		print("Item aquired: %s" % i.item_name)
	pending_inventory = []

func get_shop_stock(shop: ShopResource) -> Dictionary:
	#if !(shop.shop_id in shop_stock_cache.keys()):
		#shop_stock_cache[shop.shop_id] = shop.stock
	#return shop_stock_cache[shop.shop_id]
	if (!shop.shop_id in shop_states.keys()):
		shop_states[shop.shop_id] = shop.item_quantities.duplicate()
	if shop.shop_id in recent_shops:
		recent_shops.erase(shop.shop_id)
	recent_shops.insert(0, shop.shop_id)
	if recent_shops.size() > MAX_RECENT_SHOPS:
		var shop_id = recent_shops.pop_back()
		var _shop : ShopResource = load("res://data/shops/%s.tres" % shop_id)
		shop_states[shop_id] = _shop.item_quantities.duplicate()
	return shop_states[shop.shop_id]
