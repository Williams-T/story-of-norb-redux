class_name EntityResource
extends Resource

@export var stats: CharacterStatBlock
@export var actions: Array[BattleAction]
@export var inventory: Array[ItemResource]
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
	if !(current_equip is Array):
		if current_equip == null:
			equipped[slot_key] = item
			return true
		else:
			unequip_item(current_equip)
			equipped[slot_key] = item
			return true
	else:
		var index = 0
		for i : int in current_equip.size():
			index = i
			if current_equip[index] == null:
				equipped[slot_key][index] = item
				return true
		unequip_item(current_equip[-1])
		(current_equip as Array).remove_at(-1)
		(current_equip as Array).insert(0, item)
		if item.two_handed:
			current_equip[0] = item
			if current_equip[1] is ItemResource:
				unequip_item(current_equip[1])
			equipped[slot_key][1] = BLOCKED_SLOT
		return true

func unequip_item(item:ItemResource):
	var _inventory
	if is_player:
		_inventory = GameState.inventory.duplicate()
	else:
		_inventory = inventory.duplicate()
	var slot = locate_equip_slot(item)
	var current_equip = equipped[slot]
	if current_equip is Array:
		if current_equip.has(item):
			_inventory.append(item)
			equipped[slot][current_equip.find(item)] = null
			#return true
		#else:
			#return false
	else:
		if current_equip == item:
			_inventory.append(current_equip)
			equipped[slot] = null
			#return true
		#else:
			#return false
	if is_player:
		GameState.inventory = _inventory
	else:
		inventory = _inventory

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
