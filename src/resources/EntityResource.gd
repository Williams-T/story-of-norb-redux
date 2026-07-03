class_name EntityResource
extends Resource

@export var stats: CharacterStatBlock
@export var actions: Array[BattleAction]
@export var inventory: Array[ItemResource]
@export var item_quantities := {}
@export var is_player := false
var active_statuses: Array[Dictionary] = []
var equipped: Dictionary
var stat_mods = {
	"str": 0.0,
	"agi": 0.0,
	"vit": 0.0,
	"intelligence": 0.0,
	"wil": 0.0,
}

const BLOCKED_SLOT = "blocked"

func _init() -> void:
	equipped = {
		"head": null,
		"torso": null,
		"legs": null,
		"hand": [null, null],
		"foot": [null, null],
		"ring": [null, null, null, null, null, null, null, null, null, null],
		"toe_ring": [null, null, null, null, null, null, null, null, null, null],
	}

func scan_quantities():
	if !is_player and item_quantities.keys().is_empty():
		item_quantities.clear()
		var temp_inventory = inventory.duplicate(true)
		for i : ItemResource in inventory:
			if i.item_name in item_quantities.keys():
				temp_inventory.erase(i)
				item_quantities[i.item_name] += 1
			else:
				item_quantities[i.item_name] = 1
		inventory = temp_inventory

func get_bonus(stat_name: String) -> int:
	var amount = 0
	for key in equipped.keys():
		if equipped[key] is Array:
			for value in equipped[key]:
				if value is ItemResource:
					var item : ItemResource = value
					amount += item.stat_modifiers.get(stat_name, 0)
		else:
			if equipped[key] is ItemResource:
				var item : ItemResource = equipped[key]
				amount += item.stat_modifiers.get(stat_name, 0)
	return amount

func equip_item(item:ItemResource) -> bool:
	if item.item_type != ItemResource.ItemType.EQUIPMENT:
		return false
	var slot_key : String = locate_equip_slot(item)
	if slot_key == "":
		return false
	if slot_key not in equipped.keys():
		return false
	var current_equip = equipped[slot_key]
	if not (current_equip is Array): # (Head / Torso / Legs)
		if current_equip is ItemResource:
			unequip_item(current_equip)
		equipped[slot_key] = item
		return true
	else: # Array
		if item.two_handed:
			if current_equip[0] is ItemResource:
				unequip_item(current_equip[0])
			if current_equip[1] is ItemResource:
				unequip_item(current_equip[1])
			current_equip[0] = item
			current_equip[1] = BLOCKED_SLOT
			return true
		for i in current_equip.size():
			if current_equip[i] == null:
				current_equip[i] = item
				return true
		if current_equip[0] is ItemResource and current_equip[0].two_handed:
			unequip_item(current_equip[0])
			current_equip[0] = item
			return true
		unequip_item(current_equip[-1])
		current_equip[-1] = item
		return true

func unequip_item(item: ItemResource) -> void:
	var _inventory
	var _quantities
	if is_player:
		_inventory = GameState.inventory.duplicate()
		_quantities = GameState.item_quantities.duplicate()
	else:
		_inventory = inventory.duplicate()
		_quantities = item_quantities.duplicate()
	var slot = locate_equip_slot(item)
	var current_equip = equipped[slot]
	if current_equip is Array:
		if current_equip.has(item):
			if item.item_name in _quantities.keys():
				_quantities[item.item_name] += 1
			else:
				_inventory.append(item)
				_quantities[item.item_name] = 1
			current_equip[current_equip.find(item)] = null
			if item.two_handed:
				if current_equip[1] == BLOCKED_SLOT:
					current_equip[1] = null
	else:
		if current_equip == item:
			if item.item_name in _quantities.keys():
				_quantities[item.item_name] += 1
			else:
				_inventory.append(current_equip)
				_quantities[item.item_name] = 1
			equipped[slot] = null
	if is_player:
		GameState.inventory = _inventory
		GameState.item_quantities = _quantities
	else:
		inventory = _inventory
		item_quantities = _quantities

func add_item(item : ItemResource):
	if is_player:
		if !(GameState.item_quantities.has(item.item_name)):
			GameState.inventory.append(item)
			GameState.item_quantities[item.item_name] = 1
		else:
			GameState.item_quantities[item.item_name] += 1
	else:
		if !(item_quantities.has(item.item_name)):
			inventory.append(item)
			item_quantities[item.item_name] = 1
		else:
			item_quantities[item.item_name] += 1

func remove_item(item : ItemResource):
	if is_player:
		if !(GameState.item_quantities.has(item.item_name)):
			return
		if GameState.item_quantities[item.item_name] > 1:
			GameState.item_quantities[item.item_name] -= 1
		else:
			for i : ItemResource in GameState.inventory:
				if i.item_name == item.item_name:
					GameState.inventory.erase(i)
					break
			GameState.item_quantities.erase(item.item_name)
	else:
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

func locate_equip_slot(item : ItemResource) -> String:
	if item.item_type != ItemResource.ItemType.EQUIPMENT:
		return ""
	return (ItemResource.EquipSlot.keys()[item.equip_slot] as String).to_lower()

func get_all_equipped_items() -> Array[ItemResource]:
	var items : Array[ItemResource]= []
	for equipment in equipped.keys():
		if !(equipped[equipment] is Array):
			if equipped[equipment] is ItemResource:
				var item : ItemResource = equipped[equipment]
				items.append(item)
		else:
			for item in equipped[equipment]:
				if item is ItemResource:
					items.append(item)
	return items
