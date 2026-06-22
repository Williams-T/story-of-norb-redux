#Shop Editor
@tool
extends Control

@onready var shops_list : VBoxContainer = $VBoxContainer/HBoxContainer/ShopList
@onready var new_button : Button = $VBoxContainer/HBoxContainer/MainFields/HBoxContainer3/NewButton
@onready var save_button : Button = $VBoxContainer/HBoxContainer/MainFields/HBoxContainer3/SaveButton
@onready var shop_name : LineEdit = $VBoxContainer/HBoxContainer/MainFields/NameEdit
@onready var bg_button : TextureButton = $VBoxContainer/HBoxContainer/MainFields/HBoxContainer/VBoxContainer3/BGButton
@onready var fg_closed_button : TextureButton = $VBoxContainer/HBoxContainer/MainFields/HBoxContainer/VBoxContainer/FGClosedButton
@onready var fg_open_button : TextureButton = $VBoxContainer/HBoxContainer/MainFields/HBoxContainer/VBoxContainer2/FGOpenButton
@onready var buy_mod_spin : SpinBox = $VBoxContainer/HBoxContainer/MainFields/HBoxContainer2/BuyModSpin
@onready var sell_mod_spin : SpinBox = $VBoxContainer/HBoxContainer/MainFields/HBoxContainer2/SellModSpin
@onready var welcome_edit : LineEdit = $VBoxContainer/HBoxContainer/MainFields/VBoxContainer/WelcomeEdit
@onready var buy_edit : LineEdit = $VBoxContainer/HBoxContainer/MainFields/VBoxContainer/BuyEdit
@onready var sell_edit : LineEdit = $VBoxContainer/HBoxContainer/MainFields/VBoxContainer/SellEdit
@onready var return_edit : LineEdit = $VBoxContainer/HBoxContainer/MainFields/VBoxContainer/ReturnEdit
@onready var exit_edit : LineEdit = $VBoxContainer/HBoxContainer/MainFields/VBoxContainer/ExitEdit
@onready var stock_container : VBoxContainer = $VBoxContainer/HBoxContainer/ScrollContainer/StockContainer
#@onready var add_item_row : ShopEditAddItemRow = $VBoxContainer/HBoxContainer/ScrollContainer/StockContainer/AddItemRow
var _item_row = load("res://addons/rpg_editors/shop_editor/item_row.tscn")
var _add_item_row = load("res://addons/rpg_editors/shop_editor/add_item_row.tscn")
var add_item_row : ShopEditAddItemRow
var item_row : ShopEditItemRow

var current_shop_id: String # used as the cache key in GameState
var current_shop_name: String
var current_stock: Array[ItemResource]
var current_buy_modifier: float = 1.0
var current_sell_modifier: float = 0.8
var current_item_quantities: Dictionary = {}
var current_path = ""

# dialogue
var intro_text = "Welcome to the shop\nHow can I help you?"
var bought_item_text = "Would you like to buy anything else?"
var sold_item_text = "Would you like to sell anything else?"
var main_menu_text = "Anything else I can help you with?"
var exit_text = "Alright, see you next time!"

var current_shop : ShopResource
var texture_popup : EditorFileDialog
var current_texture_button : NodePath

func _ready() -> void:
	texture_popup = EditorFileDialog.new()
	texture_popup.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	texture_popup.access =FileDialog.ACCESS_RESOURCES
	texture_popup.current_dir = "res://art/shops/"
	add_child(texture_popup)
	bg_button.pressed.connect(popup_texture.bind(bg_button))
	fg_closed_button.pressed.connect(popup_texture.bind(fg_closed_button))
	fg_open_button.pressed.connect(popup_texture.bind(fg_open_button))
	texture_popup.file_selected.connect(_on_texture_selected)
	new_button.pressed.connect(new_shop)
	save_button.pressed.connect(save_shop)
	new_shop()
	refresh_shops()
	#refresh_fields()

func refresh_shops() -> void:
	for child in shops_list.get_children():
		if child.name != "ShopsLabel":
			child.queue_free()
	var shops = DirAccess.get_files_at("res://data/shops/")
	for file : String in shops:
		var loaded = load("res://data/shops/%s" % file)
		if loaded is ShopResource:
			var button := Button.new()
			button.text = loaded.shop_name
			button.pressed.connect(func():refresh_fields(loaded); current_path = loaded.resource_path)
			shops_list.add_child(button)

func refresh_fields(shop : ShopResource = null):
	if shop != null:
		current_shop = shop
		current_stock = current_shop.stock
		shop_name.text = current_shop.shop_name
		if current_shop.bg_texture != null:
			bg_button.texture_normal = current_shop.bg_texture
		if current_shop.fg_closed_texture != null:
			fg_closed_button.texture_normal = current_shop.fg_closed_texture
		if current_shop.fg_open_texture != null:
			fg_open_button.texture_normal = current_shop.fg_open_texture
		buy_mod_spin.value = current_shop.buy_modifier
		sell_mod_spin.value = current_shop.sell_modifier
		welcome_edit.text = current_shop.intro_text
		buy_edit.text = current_shop.bought_item_text
		sell_edit.text = current_shop.sold_item_text
		return_edit.text = current_shop.main_menu_text
		exit_edit.text = current_shop.exit_text
		for node in stock_container.get_children():
			if !node.name in ["StockLabel"]:
				node.queue_free()
		for item : ItemResource in current_stock:
			var quantity = 1
			if item.item_name in current_shop.item_quantities.keys():
				quantity = current_shop.item_quantities[item.item_name]
			else:
				current_shop.item_quantities[item.item_name] = 1
			add_item(item, quantity)
	add_item_row = _add_item_row.instantiate()
	stock_container.add_child(add_item_row)
	add_item_row.item_added.connect(add_item)

func add_item(item : ItemResource, quantity):
	item_row = _item_row.instantiate()
	stock_container.add_child(item_row)
	item_row.label.text = item.item_name
	item_row.quantity_spin.value = quantity
	if item.item_name in current_shop.item_quantities.keys():
		item_row.quantity_spin.value = current_shop.item_quantities[item.item_name]
	item_row.delete_button.pressed.connect(func():item_row.queue_free())
	item_row.set_meta("item", item)
	stock_container.move_child(add_item_row, -1)
	add_item_row.cancel_button.pressed.emit()

func new_shop():
	current_shop = ShopResource.new()
	shop_name.clear()
	bg_button.texture_normal = preload("res://art/NULL.png")
	fg_closed_button.texture_normal = preload("res://art/NULL.png")
	fg_open_button.texture_normal = preload("res://art/NULL.png")
	buy_mod_spin.value = 1.0
	sell_mod_spin.value = 1.0
	welcome_edit.clear()
	buy_edit.clear()
	sell_edit.clear()
	return_edit.clear()
	exit_edit.clear()
	for child in stock_container.get_children():
		if child.name != "StockLabel":
			child.queue_free()
	refresh_fields()

func save_shop():
	
	current_shop.shop_name = shop_name.text
	current_shop.bg_texture = bg_button.texture_normal
	current_shop.fg_closed_texture = fg_closed_button.texture_normal
	current_shop.fg_open_texture = fg_open_button.texture_normal
	current_shop.buy_modifier = buy_mod_spin.value
	current_shop.sell_modifier = sell_mod_spin.value
	if welcome_edit.text != "":
		current_shop.intro_text = welcome_edit.text
	else:
		current_shop.intro_text = intro_text
	if buy_edit.text != "":
		current_shop.bought_item_text = buy_edit.text
	else:
		current_shop.bought_item_text = bought_item_text
	if sell_edit.text != "":
		current_shop.sold_item_text = sell_edit.text
	else:
		current_shop.sold_item_text = sold_item_text
	if return_edit.text != "":
		current_shop.main_menu_text = return_edit.text
	else:
		current_shop.main_menu_text = main_menu_text
	if exit_edit.text != "":
		current_shop.exit_text = exit_edit.text
	else:
		current_shop.exit_text = exit_text
	current_shop.stock.clear()
	current_shop.item_quantities.clear()
	for row in stock_container.get_children():
		if row is ShopEditItemRow:
			var item : ItemResource = row.get_meta("item")
			current_shop.stock.append(item)
			current_shop.item_quantities[item.item_name] = row.quantity_spin.value
	current_shop.shop_id = current_shop.shop_name.replace(" ", "_")
	if current_path == "":
		current_path = "res://data/shops/%s.tres" % current_shop.shop_id
	ResourceSaver.save(current_shop, current_path)
	refresh_shops()

func popup_texture(current_node : Node):
	current_texture_button = current_node.get_path()
	texture_popup.popup()

func _on_texture_selected(file_path):
	var button : TextureButton = get_node(current_texture_button)
	var texture : Texture = load(file_path)
	button.texture_normal = texture
