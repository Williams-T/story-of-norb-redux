# Add Item Row
@tool
extends GridContainer
class_name ShopEditAddItemRow

signal item_added(item : ItemResource, quantity)
#signal items_selected(items : PackedStringArray)

var current_item : ItemResource
@onready var item_picker_button : Button =  $ItemPickerButton
@onready var quantity_spin : SpinBox = $QuantitySpin
@onready var add_button : Button = $AddItemButton
@onready var cancel_button : Button = $CancelItemButton
var item_popup : EditorFileDialog

func _ready() -> void:
	item_popup = EditorFileDialog.new()
	item_popup.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	item_popup.access =FileDialog.ACCESS_RESOURCES
	item_popup.current_dir = "res://data/items/"
	add_child(item_popup)
	item_picker_button.pressed.connect(func():item_popup.popup())
	item_popup.file_selected.connect(item_selected)
	item_popup.files_selected.connect(func(items : PackedStringArray): for i in items: item_added.emit(load(i), 1))
	add_button.pressed.connect(func():item_added.emit(current_item, quantity_spin.value))
	cancel_button.pressed.connect(func(): add_button.disabled = true; item_picker_button.text = "Pick Item")

func item_selected(file : String):
	var loaded = load(file)
	if loaded is ItemResource:
		current_item = loaded
		item_picker_button.text = loaded.item_name
		add_button.disabled = false
