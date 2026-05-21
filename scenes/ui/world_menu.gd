extends CanvasLayer


var current_party_member : PartyMemberResource = null

# Items Nodes
@onready var name_label : Label = $Panel/TabContainer/Items/HBoxContainer/HBoxContainer/Stats/NameLabel
@onready var stats_label : Label = $Panel/TabContainer/Items/HBoxContainer/HBoxContainer/Stats/StatsLabel
@onready var inventory_container := $Panel/TabContainer/Items/HBoxContainer/HBoxContainer/VBoxContainer/TabContainer
@onready var item_label : Label = $Panel/TabContainer/Items/HBoxContainer/HBoxContainer/VBoxContainer/Label
@onready var member_picker = $Panel/TabContainer/Items/HBoxContainer/HBoxContainer/VBoxContainer/MemberPicker
@onready var member_buttons = $Panel/TabContainer/Items/HBoxContainer/HBoxContainer/VBoxContainer/MemberPicker/VBoxContainer

# Equipment Nodes

@onready var equip_panel : VBoxContainer = $Panel/TabContainer/Equipment/TabContainer/Main/VBoxContainer
@onready var main_equipped_icon : TextureRect = $Panel/TabContainer/Equipment/TabContainer/Main/VBoxContainer/PanelContainer/HBoxContainer/TextureRect
@onready var main_equipped_label : Label = $Panel/TabContainer/Equipment/TabContainer/Main/VBoxContainer/PanelContainer/HBoxContainer/Label
@onready var main_equipment_list : VBoxContainer = $Panel/TabContainer/Equipment/TabContainer/Main/VBoxContainer/ScrollContainer/VBoxContainer
@onready var ring_equipped_icon : TextureRect = $Panel/TabContainer/Equipment/TabContainer/Rings/VBoxContainer/PanelContainer/HBoxContainer/TextureRect
@onready var ring_equipped_label : Label = $Panel/TabContainer/Equipment/TabContainer/Rings/VBoxContainer/PanelContainer/HBoxContainer/Label
@onready var ring_equipment_list : VBoxContainer = $Panel/TabContainer/Equipment/TabContainer/Rings/VBoxContainer/ScrollContainer/VBoxContainer

# Buttons

@onready var Head : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Main/TextureRect/Head
@onready var Torso : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Main/TextureRect/Torso
@onready var LeftHand : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Main/TextureRect/LeftHand
@onready var RightHand : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Main/TextureRect/RightHand
@onready var Legs : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Main/TextureRect/Legs
@onready var LeftFoot : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Main/TextureRect/LeftFoot
@onready var RightFoot : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Main/TextureRect/RightFoot
@onready var Ring1 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/Ring1
@onready var Ring2 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/Ring2
@onready var Ring3 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/Ring3
@onready var Ring4 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/Ring4
@onready var Ring5 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/Ring5
@onready var Ring6 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/Ring6
@onready var Ring7 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/Ring7
@onready var Ring8 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/Ring8
@onready var Ring9 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/Ring9
@onready var Ring10 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/Ring10
@onready var ToeRing1 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/ToeRing1
@onready var ToeRing2 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/ToeRing2
@onready var ToeRing3 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/ToeRing3
@onready var ToeRing4 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/ToeRing4
@onready var ToeRing5 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/ToeRing5
@onready var ToeRing6 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/ToeRing6
@onready var ToeRing7 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/ToeRing7
@onready var ToeRing8 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/ToeRing8
@onready var ToeRing9 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/ToeRing9
@onready var ToeRing10 : TextureButton = $Panel/TabContainer/Equipment/TabContainer/Rings/TextureRect/ToeRing10

var button_dict = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_party_member = get_active_player()
	refresh_item_list()
	button_dict = {
		Head : ["head", -1],
		Torso : ["torso", -1],
		LeftHand : ["hand", 0],
		RightHand : ["hand", 1],
		Legs : ["legs", -1],
		LeftFoot : ["foot", 0],
		RightFoot : ["foot", 1],
		Ring1 : ["ring", 0],
		Ring2 : ["ring", 1],
		Ring3 : ["ring", 2],
		Ring4 : ["ring", 3],
		Ring5 : ["ring", 4],
		Ring6 : ["ring", 5],
		Ring7 : ["ring", 6],
		Ring8 : ["ring", 7],
		Ring9 : ["ring", 8],
		Ring10 : ["ring", 9],
		ToeRing1 : ["toe_ring", 0],
		ToeRing2 : ["toe_ring", 1],
		ToeRing3 : ["toe_ring", 2],
		ToeRing4 : ["toe_ring", 3],
		ToeRing5 : ["toe_ring", 4],
		ToeRing6 : ["toe_ring", 5],
		ToeRing7 : ["toe_ring", 6],
		ToeRing8 : ["toe_ring", 7],
		ToeRing9 : ["toe_ring", 8],
		ToeRing10 : ["toe_ring", 9],
	}

	for button : TextureButton in button_dict.keys():
		var values : Array = button_dict[button]
		button.pressed.connect(_on_slot_pressed.bind(values[0], values[1]))

func _on_slot_pressed(slot_key : String, index : int):
	_update_equipped_display(slot_key, index)
	var main = ["head", "torso", "hand", "legs", "foot"]
	var _list
	if slot_key in main:
		_list = main_equipment_list
	else:
		_list = ring_equipment_list
	for node in _list.get_children():
		node.queue_free()
	await get_tree().process_frame
	var current_inventory
	if !current_party_member.is_player:
		current_inventory = current_party_member.inventory.duplicate()
	else:
		current_inventory = GameState.inventory.duplicate()
	for item : ItemResource in current_inventory:
		if current_party_member.locate_equip_slot(item) == slot_key:
			var item_button := Button.new()
			item_button.text = "%s  |  %s" % [item.item_name, item.stats_to_text()]
			item_button.icon = item.icon
			item_button.custom_minimum_size = Vector2(0, 128)
			item_button.pressed.connect(func(): 
				current_party_member.equip_item(item)
				if current_party_member.is_player:
					GameState.inventory.erase(item)
				else:
					current_party_member.inventory.erase(item)
				_on_slot_pressed(slot_key, index)
				)
			_list.add_child(item_button)

func _update_equipped_display(slot_key: String, index: int) -> void:
	var main_keys = ["head", "torso", "hand", "legs", "foot"]
	var _icon = main_equipped_icon if slot_key in main_keys else ring_equipped_icon
	var _label = main_equipped_label if slot_key in main_keys else ring_equipped_label
	var current_equip
	if index == -1:
		current_equip = current_party_member.equipped[slot_key]
	else:
		current_equip = current_party_member.equipped[slot_key][index]
	
	if current_equip is ItemResource:
		_icon.texture = current_equip.icon
		_label.text = "%s\n%s" % [current_equip.item_name, current_equip.stats_to_text()]
	elif current_equip == EntityResource.BLOCKED_SLOT:
		_icon.texture = null
		_label.text = "Two-handed"
	else:
		_icon.texture = null
		_label.text = "Empty"

func get_active_player():
	for entity : EntityResource in GameState.party:
		if entity.is_player:
			return entity
	return null

func _input(event: InputEvent) -> void:
	if GameState.in_combat == true:
		return
	if event.is_action_pressed("open_menu"):
		if !visible:
			current_party_member = get_active_player()
			show()
			EventBus.world_menu_opened.emit()
			refresh_item_list()
		else:
			hide()
			EventBus.world_menu_closed.emit()

func refresh_item_list():
	if current_party_member.stats.current_hp == -1:
		current_party_member.stats.current_hp = current_party_member.stats.max_hp()
	if current_party_member.stats.current_mp == -1:
		current_party_member.stats.current_mp = current_party_member.stats.max_mp()
	name_label.text = current_party_member.stats.character_name
	var stats_output := "Level %s\nHP: %s / %s\nMP: %s / %s\nSTR: %s\nAGI: %s\nVIT: %s\nINT: %s\nWIL: %s" % [
		current_party_member.stats.level, 
		current_party_member.stats.current_hp, 
		current_party_member.stats.max_hp(),
		current_party_member.stats.current_mp,
		current_party_member.stats.max_mp(),
		current_party_member.stats.str,
		current_party_member.stats.agi,
		current_party_member.stats.vit,
		current_party_member.stats.intelligence,
		current_party_member.stats.wil
		]
	if current_party_member.active_statuses.size() > 0:
		stats_output += "\n Statuses:"
	for i in current_party_member.active_statuses:
		var status : StatusEffect = i["effect"] 
		stats_output += "\n%s" % status.status_name
	stats_label.text = stats_output
	for node in inventory_container.get_children(false):
		node.queue_free()
	await get_tree().process_frame
	for entity : EntityResource in GameState.party:
		var item_container := HBoxContainer.new()
		item_container.size_flags_horizontal = Control.SIZE_EXPAND
		item_container.size_flags_vertical = Control.SIZE_EXPAND
		item_container.name = entity.stats.character_name
		inventory_container.add_child(item_container)
		var item_list := ItemList.new()
		item_list.custom_minimum_size = Vector2(400, 400)
		item_list.size_flags_horizontal = Control.SIZE_EXPAND
		item_list.size_flags_vertical = Control.SIZE_EXPAND
		item_container.add_child(item_list)
		if entity.is_player:
			for item : ItemResource in GameState.inventory:
				if item.item_type != ItemResource.ItemType.EQUIPMENT:
					item_list.add_item(item.item_name + " | " + item.stats_to_text())
					item_list.set_item_metadata(item_list.item_count - 1, item)
		else:
			for item : ItemResource in entity.inventory:
				if item.item_type != ItemResource.ItemType.EQUIPMENT:
					item_list.add_item(item.item_name)
					item_list.set_item_metadata(item_list.item_count - 1, item)
		item_list.item_selected.connect(_on_item_selected.bind(item_list))
		

func _on_item_selected(index : int, item_list : ItemList):
	var item : ItemResource = item_list.get_item_metadata(index)
	item_label.text = "%s\n%s\n%s" % [item.item_name, item.description, item.stats_to_text()]
	if item.item_type == ItemResource.ItemType.CONSUMABLE:
		member_picker.show()
		_populate_member_picker(item, index, item_list)
	elif item.item_type == ItemResource.ItemType.KEY_ITEM:
		member_picker.hide()

func _populate_member_picker(item : ItemResource, index : int, item_list : ItemList):
	for button in member_buttons.get_children():
		button.queue_free()
	for member : EntityResource in GameState.party:
		var member_button := Button.new()
		member_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		member_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if member == current_party_member:
			member_button.text = "Self"
		else:
			member_button.text = member.stats.character_name
		member_button.pressed.connect(func(): 
			if item.apply_to(member.stats) == true:
				#item_list.remove_item(index)
				item.quantity -= 1
				if item.quantity <= 0:
					if current_party_member.is_player:
						GameState.inventory.erase(item)
					else:
						current_party_member.inventory.erase(item)
				refresh_item_list()
			member_picker.hide()
			)
		member_buttons.add_child(member_button)
