@tool
extends PanelContainer

@onready var tab_container : TabContainer = $VBoxContainer/HBoxContainer/TabContainer
@onready var file_list : VBoxContainer = $VBoxContainer/MainPanel/ScrollContainer/FileList
@onready var new_button : Button = $VBoxContainer/MainPanel/FieldsContainer/ItemFields/HBoxContainer3/NewButton
@onready var save_button : Button = $VBoxContainer/MainPanel/FieldsContainer/ItemFields/HBoxContainer3/SaveButton
@onready var item_fields : GridContainer = $VBoxContainer/MainPanel/FieldsContainer/ItemFields
@onready var consumable_fields : GridContainer = $VBoxContainer/MainPanel/FieldsContainer/ConsumableFields
@onready var equipment_fields : GridContainer = $VBoxContainer/MainPanel/FieldsContainer/EquipmentFields
@onready var key_item_fields : GridContainer = $VBoxContainer/MainPanel/FieldsContainer/KeyItemFields

# Item Fields (default)
@onready var name_field : LineEdit = $VBoxContainer/MainPanel/FieldsContainer/ItemFields/NameLine
@onready var description_field : LineEdit = $VBoxContainer/MainPanel/FieldsContainer/ItemFields/DescriptionLine
@onready var icon_button : TextureButton = $VBoxContainer/MainPanel/FieldsContainer/ItemFields/HBoxContainer2/IconButton
@onready var value_field : SpinBox = $VBoxContainer/MainPanel/FieldsContainer/ItemFields/ValueSpin
@onready var stackable_field : CheckButton = $VBoxContainer/MainPanel/FieldsContainer/ItemFields/HBoxContainer/StackableCheck
@onready var max_stack_field : SpinBox = $VBoxContainer/MainPanel/FieldsContainer/ItemFields/MaxStackSpin

# Consumable Fields
@onready var effect_type_field : OptionButton = $VBoxContainer/MainPanel/FieldsContainer/ConsumableFields/EffectTypeOption
@onready var effect_value_field : SpinBox = $VBoxContainer/MainPanel/FieldsContainer/ConsumableFields/EffectValueSpin
@onready var custom_type_field : OptionButton = $VBoxContainer/MainPanel/FieldsContainer/ConsumableFields/CustomTypesOption
@onready var custom_value_field : SpinBox = $VBoxContainer/MainPanel/FieldsContainer/ConsumableFields/CustomValuesSpin
@onready var add_custom_button : Button = $VBoxContainer/MainPanel/FieldsContainer/ConsumableFields/AddCustomButton
@onready var custom_container : GridContainer = $VBoxContainer/MainPanel/FieldsContainer/ConsumableFields/CustomContainer

# Equipment Fields
@onready var equip_slot_field : OptionButton = $VBoxContainer/MainPanel/FieldsContainer/EquipmentFields/EquipSlotOption
@onready var two_handed_field : CheckButton = $VBoxContainer/MainPanel/FieldsContainer/EquipmentFields/HBoxContainer/TwoHandedCheck
@onready var str_field : SpinBox = $VBoxContainer/MainPanel/FieldsContainer/EquipmentFields/GridContainer/StrContainer/StrSpin
@onready var agi_field : SpinBox = $VBoxContainer/MainPanel/FieldsContainer/EquipmentFields/GridContainer/AgiContainer/AgiSpin
@onready var vit_field : SpinBox = $VBoxContainer/MainPanel/FieldsContainer/EquipmentFields/GridContainer/VitContainer/VitSpin
@onready var int_field : SpinBox = $VBoxContainer/MainPanel/FieldsContainer/EquipmentFields/GridContainer/IntContainer/IntSpin
@onready var wil_field : SpinBox = $VBoxContainer/MainPanel/FieldsContainer/EquipmentFields/GridContainer/WilContainer/WilSpin

# Key Item Fields
@onready var sets_flag_field : LineEdit = $VBoxContainer/MainPanel/FieldsContainer/KeyItemFields/LineEdit

var current_item : ItemResource = ItemResource.new()
var current_path: String = ""
var current_customs = []
var icon_dialog : EditorFileDialog
var populating := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon_dialog = EditorFileDialog.new()
	icon_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	icon_dialog.access =FileDialog.ACCESS_RESOURCES
	icon_dialog.current_dir = "res://art/items/"
	add_child(icon_dialog)
	icon_button.pressed.connect(func(): icon_dialog.popup())
	icon_dialog.file_selected.connect(func(file): icon_button.texture_normal = load(file))
	tab_container.tab_changed.connect(_on_tab_switched)
	new_button.pressed.connect(func(): current_item = ItemResource.new(); current_path = ""; clear_fields())
	save_button.pressed.connect(save_item)
	add_custom_button.pressed.connect(func(): 
		if !(custom_type_field.selected in [-1, 0]):
			#current_customs.append([custom_type_field.selected, custom_value_field.value])
			add_custom_row(custom_type_field.selected, custom_value_field.value)
		)
	_refresh_file_list()

func _on_tab_switched(current_tab):
	item_fields.show()
	if populating:
		return
	current_item = ItemResource.new()
	current_path = ""
	clear_fields()
	if current_tab == 0: # Consumable
		consumable_fields.show()
		equipment_fields.hide()
		key_item_fields.hide()
		_refresh_file_list(0)
	elif current_tab == 1: # Equipment
		consumable_fields.hide()
		equipment_fields.show()
		key_item_fields.hide()
		_refresh_file_list(1)
	elif current_tab == 2: # Key
		consumable_fields.hide()
		equipment_fields.hide()
		key_item_fields.show()
		_refresh_file_list(2)

func _refresh_file_list(type : int = -1):
	for node : Node in file_list.get_children():
		node.queue_free()
	await get_tree().process_frame
	var files = DirAccess.get_files_at("res://data/items/")
	for file : String in files:
		var loaded = load("res://data/items/%s" % file)
		if loaded is ItemResource:
			if type != -1 and loaded.item_type != type:
				continue
			var button = Button.new()
			button.flat = true
			button.text = file.get_basename().replace("_", " ")
			file_list.add_child(button)
			button.pressed.connect(populate_fields.bind(loaded))

func populate_fields(item : ItemResource):
	populating = true
	clear_fields()
	current_path = item.resource_path
	current_item = item
	name_field.text = item.item_name
	description_field.text = item.description
	if item.icon == null:
		icon_button.texture_normal = preload("res://art/NULL.png")
	else:
		icon_button.texture_normal = item.icon
	value_field.value = item.value
	stackable_field.button_pressed = item.stackable
	max_stack_field.value = item.max_stack
	match item.item_type:
		0: # Consumable
			tab_container.current_tab = 0
			effect_type_field.select(item.effect_type)
			effect_value_field.value = item.effect_value
			if item.effect_type == ItemResource.ConsumableEffect.CUSTOM:
				for index in item.custom_effects.size():
					add_custom_row(item.custom_effects[index], item.custom_values[index], index)
		1: # Equipment
			tab_container.current_tab = 1
			equip_slot_field.select(item.equip_slot)
			two_handed_field.button_pressed = item.two_handed
			str_field.value = 0
			agi_field.value = 0
			vit_field.value = 0
			int_field.value = 0
			wil_field.value = 0
			for key in item.stat_modifiers.keys():
				match key:
					"str":
						str_field.value = item.stat_modifiers[key]
					"agi":
						agi_field.value = item.stat_modifiers[key]
					"vit":
						vit_field.value = item.stat_modifiers[key]
					"intelligence":
						int_field.value = item.stat_modifiers[key]
					"wil":
						wil_field.value = item.stat_modifiers[key]
		2: # Key Item
			tab_container.current_tab = 2
			sets_flag_field.text = item.sets_flag
	populating = false

func clear_fields():
	current_item = ItemResource.new()
	#current_path = ""
	current_customs = []
	# Item
	name_field.text = ""
	description_field.text = ""
	icon_button.texture_normal = load("res://art/NULL.png")
	value_field.value = 0
	stackable_field.button_pressed = false
	max_stack_field.value = 0
	
	# Consumables
	effect_type_field.select(0)
	effect_value_field.value = 0
	for node in custom_container.get_children():
		if !(node.name in ["EffectsLabel", "ValuesLabel"]):
			node.queue_free()
	
	# Equipment
	equip_slot_field.select(0)
	two_handed_field.button_pressed = false
	str_field.value = 0
	agi_field.value = 0
	vit_field.value = 0
	int_field.value = 0
	wil_field.value = 0
	
	# Key Item
	sets_flag_field.text = ""

func add_custom_row(effect, value, index = -1):
	var _index
	if index == -1:
		_index = current_customs.size()
	else:
		_index = index
	if _index >= current_customs.size():
		current_customs.append([])
	current_customs[_index] = [effect, value]
	var lbl = Label.new()
	lbl.text = ItemResource.ConsumableEffect.keys()[effect]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.set_meta("category", "effect")
	lbl.set_meta("index", _index)
	custom_container.add_child(lbl)
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.set_meta("index", _index)
	var lbl2 = Label.new()
	lbl2.text = "%s" % value
	lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_container.add_child(hbox)
	hbox.add_child(lbl2)
	var delete_button := Button.new()
	delete_button.text = " x "
	hbox.add_child(delete_button)
	delete_button.pressed.connect(func():
		current_customs.remove_at(_index)
		for node in custom_container.get_children():
			if node.get_meta("index", -1) == _index:
				if node.get_child_count() > 0:
					for nodelette in node.get_children():
						nodelette.queue_free()
				node.queue_free())

func save_item():
	current_item.item_name = name_field.text
	current_item.description = description_field.text
	current_item.icon = icon_button.texture_normal
	current_item.value = value_field.value
	current_item.stackable = stackable_field.button_pressed
	current_item.max_stack = max_stack_field.value
	current_item.item_type = tab_container.current_tab
	match tab_container.current_tab:
		0: # Consumable
			#current_item.item_type = 
			current_item.effect_type = effect_type_field.selected
			current_item.effect_value = effect_value_field.value
			current_item.custom_effects.clear()
			current_item.custom_values.clear()
			for i in current_customs.size():
				current_item.custom_effects.append(current_customs[i][0])
				current_item.custom_values.append(current_customs[i][1])
		1: # Equipment
			current_item.equip_slot = equip_slot_field.selected
			current_item.two_handed = two_handed_field.button_pressed
			current_item.stat_modifiers.clear()
			if str_field.value != 0:
				current_item.stat_modifiers["str"] = str_field.value
			if agi_field.value != 0:
				current_item.stat_modifiers["agi"] = agi_field.value
			if vit_field.value != 0:
				current_item.stat_modifiers["vit"] = vit_field.value
			if int_field.value != 0:
				current_item.stat_modifiers["intelligence"] = int_field.value
			if wil_field.value != 0:
				current_item.stat_modifiers["wil"] = wil_field.value
		2: # Key Item
			current_item.sets_flag = sets_flag_field.text
	if current_path == "":
		current_path = "res://data/items/%s.tres" % name_field.text.to_lower().replace(" ", "_")
	ResourceSaver.save(current_item, current_path)
	_refresh_file_list(tab_container.current_tab)
