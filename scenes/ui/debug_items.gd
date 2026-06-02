extends HBoxContainer
class_name DebugItems

@onready var item_list : ItemList = $Items/ItemList
@onready var character_container : VBoxContainer = $Characters
@onready var inventory : ItemList = $Inventory/ItemList
@onready var add_item_button : Button = $Buttons/AddItem
@onready var remove_item_button : Button = $Buttons/RemoveItem
@onready var clear_inventory_button : Button = $Buttons/ClearInventory
@onready var random_loadout_button : Button = $Buttons/RandomLoadout

var current_entity : EntityResource

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_list.item_selected.connect(func(idx : int): inventory.deselect_all(); remove_item_button.disabled = true; add_item_button.disabled = false)
	inventory.item_selected.connect(func(idx : int): item_list.deselect_all(); remove_item_button.disabled = false; add_item_button.disabled = true)
	add_item_button.pressed.connect(add_item)
	remove_item_button.pressed.connect(remove_item)
	clear_inventory_button.pressed.connect(clear_inventory)
	random_loadout_button.pressed.connect(random_loadout)

func refresh_fields(root : CombatManager = null) -> void:
	item_list.clear()
	var files = DirAccess.get_files_at("res://data/items/")
	for file : String in files:
		var loaded : ItemResource = load("res://data/items/%s" % file)
		item_list.add_item(loaded.item_name)
		item_list.set_item_metadata(item_list.item_count -1, loaded)
	for child in character_container.get_children():
		if child.name != "Label":
			child.queue_free()
	for entity : EntityResource in GameState.party:
		var button = Button.new()
		button.text = entity.stats.character_name
		button.pressed.connect(func(): current_entity = entity; refresh_inventory(entity))
		character_container.add_child(button)
	if root != null:
		for entity : EntityResource in root._enemy_group.enemies:
			var button = Button.new()
			button.text = entity.stats.character_name
			button.pressed.connect(func(): current_entity = entity; refresh_inventory(entity))
			character_container.add_child(button)

func refresh_inventory(entity : EntityResource):
	inventory.clear()
	var current_inv
	if current_entity.is_player:
		current_inv = GameState.inventory
	else:
		current_inv = current_entity.inventory
	for item : ItemResource in current_inv:
		if item == null:
			continue
		inventory.add_item(item.item_name)
		inventory.set_item_metadata(inventory.item_count - 1, item)

func add_item():
	var item : ItemResource = item_list.get_item_metadata(item_list.get_selected_items()[0])
	if current_entity.is_player:
		GameState.inventory.append(item)
	else:
		current_entity.inventory.append(item)
	refresh_inventory(current_entity)

func remove_item():
	if current_entity.is_player:
		GameState.inventory.erase(inventory.get_item_metadata(inventory.get_selected_items()[0]))
	else:
		current_entity.inventory.erase(inventory.get_item_metadata(inventory.get_selected_items()[0]))
	refresh_inventory(current_entity)

func clear_inventory():
	if current_entity.is_player:
		GameState.inventory.clear()
	else:
		current_entity.inventory.clear()

func random_loadout():
	clear_inventory()
	var current_inv
	if current_entity.is_player:
		current_inv = GameState.inventory
	else:
		current_inv = current_entity.inventory
	var items := DirAccess.get_files_at("res://data/items/")
	var consumables = []
	var equipment = []
	var key_items = []
	for i in items:
		var loaded : ItemResource = load("res://data/items/%s" % i)
		match loaded.item_type:
			ItemResource.ItemType.CONSUMABLE:
				consumables.append(loaded)
			ItemResource.ItemType.EQUIPMENT:
				equipment.append(loaded)
			ItemResource.ItemType.KEY_ITEM:
				key_items.append(loaded)
	current_inv.append(consumables.pop_at(randi_range(0, consumables.size()-1)))
	current_inv.append(consumables.pop_at(randi_range(0, consumables.size()-1)))
	current_inv.append(consumables.pop_at(randi_range(0, consumables.size()-1)))
	current_inv.append(consumables.pop_at(randi_range(0, consumables.size()-1)))
	current_inv.append(equipment.pop_at(randi_range(0, equipment.size()-1)))
	current_inv.append(equipment.pop_at(randi_range(0, equipment.size()-1)))
	current_inv.append(equipment.pop_at(randi_range(0, equipment.size()-1)))
	current_inv.append(key_items.pop_at(randi_range(0, key_items.size()-1)))
	refresh_inventory(current_entity)
