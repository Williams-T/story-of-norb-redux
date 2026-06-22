extends CanvasLayer
class_name ShopUI

@onready var category_tabs : HBoxContainer = $VBoxContainer/MarginContainer/HBoxContainer/TopLeft/CategoryTabs
@onready var consumables_button : Button = $VBoxContainer/MarginContainer/HBoxContainer/TopLeft/CategoryTabs/ConsumablesButton
@onready var equipment_button : Button = $VBoxContainer/MarginContainer/HBoxContainer/TopLeft/CategoryTabs/EquipmentButton
@onready var key_item_button : Button = $VBoxContainer/MarginContainer/HBoxContainer/TopLeft/CategoryTabs/KeyItemButton
@onready var services_button : Button = $VBoxContainer/MarginContainer/HBoxContainer/TopLeft/CategoryTabs/ServicesButton
#@onready var top_layout : HBoxContainer = $VBoxContainer/MarginContainer/HBoxContainer
@onready var topleft_layout : VBoxContainer = $VBoxContainer/MarginContainer/HBoxContainer/TopLeft
@onready var item_container : VBoxContainer = $VBoxContainer/MarginContainer/HBoxContainer/TopLeft/ScrollContainer/ItemContainer
@onready var bg_texture : TextureRect = $VBoxContainer/MarginContainer/HBoxContainer/MarginContainer4/BGTexture
@onready var fg_texture : TextureRect = $VBoxContainer/MarginContainer/HBoxContainer/MarginContainer4/FGTexture
@onready var dialogue_popup : PanelContainer = $PopupPanel
@onready var dialogue_label : Label = $PopupPanel/Label
@onready var buttons_container : GridContainer = $VBoxContainer/MarginContainer2/VBoxContainer/ButtonsContainer
@onready var buy_button : Button = $VBoxContainer/MarginContainer2/VBoxContainer/ButtonsContainer/BuyButton
@onready var sell_button : Button = $VBoxContainer/MarginContainer2/VBoxContainer/ButtonsContainer/SellButton
@onready var exit_button : Button = $VBoxContainer/MarginContainer/ExitButton
@onready var gold_label : Label = $VBoxContainer/MarginContainer2/VBoxContainer/GoldLabel

# dialogues
var intro_text = "Welcome to the shop\nHow can I help you?"
var bought_item_text = "Would you like to buy anything else?"
var sold_item_text = "Would you like to sell anything else?"
var main_menu_text = "Anything else I can help you with?"
var exit_text = "Alright, see you next time!"


var current_shop : ShopResource
var current_item : ItemResource
var inventory : Array[ItemResource] = []
var selling := false

var current_array = []
var consumables_array : Array[ItemResource] = []
var equipment_array : Array[ItemResource] = []
var key_item_array : Array[ItemResource] = []
var services_array : Array[ItemResource] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#for i in item_container.get_children():
		#i.queue_free()
	#hide()
	#tween_out()
	topleft_layout.offset_transform_position_ratio = Vector2(-1.5, 0)
	buttons_container.offset_transform_position_ratio = Vector2(0, 1.5)
	EventBus.shop_opened.connect(open_shop)
	exit_button.pressed.connect(func():dialogue(exit_text); await get_tree().create_timer(1.0).timeout; ShopManager.close_shop())
	button_mode()
	refresh_gold()

func refresh_gold():
	gold_label.text = "Gold: %s" % GameState.gold

func refresh_inventory():
	inventory = GameState.inventory

func open_shop(shop : ShopResource):
	current_shop = shop
	bg_texture.texture = shop.bg_texture
	fg_texture.texture = shop.fg_closed_texture
	intro_text = shop.intro_text
	bought_item_text = shop.bought_item_text
	sold_item_text = shop.sold_item_text
	main_menu_text = shop.main_menu_text
	exit_text = shop.exit_text
	#buy_button.pressed.connect(func():repopulate_arrays(current_shop.stock); selling = false; button_mode("buy"))
	#sell_button.pressed.connect(func():refresh_inventory(); repopulate_arrays(inventory); selling = true; button_mode("sell"))
	button_mode()
	tween_in()
	topleft_layout.hide()
	topleft_layout.offset_transform_position_ratio = Vector2(-1.5, 0)
	dialogue(intro_text, Vector2(-0.38,0))
	#repopulate_arrays(shop.stock)

func close_shop():
	#buy_button.pressed.disconnect(func():repopulate_arrays(current_shop.stock); selling = false; button_mode("buy"))
	for i in buy_button.get_signal_connection_list("pressed"):
		buy_button.pressed.disconnect(i.callable)
	#sell_button.pressed.disconnect(func():repopulate_arrays(GameState.inventory); selling = true; button_mode("sell"))
	for ii in sell_button.get_signal_connection_list("pressed"):
		sell_button.pressed.disconnect(ii.callable)

func repopulate_arrays(stock : Array[ItemResource]):
	consumables_array.clear()
	equipment_array.clear()
	key_item_array.clear()
	services_array.clear()
	for i in stock:
		match i.item_type:
			ItemResource.ItemType.CONSUMABLE:
				consumables_array.append(i)
			ItemResource.ItemType.EQUIPMENT:
				equipment_array.append(i)
			ItemResource.ItemType.KEY_ITEM:
				key_item_array.append(i)
			ItemResource.ItemType.SERVICE:
				services_array.append(i)
	if consumables_array.size() > 0:
		consumables_button.show()
		if consumables_button.pressed.is_connected(repopulate_list):
			consumables_button.pressed.disconnect(repopulate_list)
		consumables_button.pressed.connect(repopulate_list.bind(consumables_array))
	else:
		consumables_button.hide()
	if equipment_array.size() > 0:
		equipment_button.show()
		if equipment_button.pressed.is_connected(repopulate_list):
			equipment_button.pressed.disconnect(repopulate_list)
		equipment_button.pressed.connect(repopulate_list.bind(equipment_array))
	else:
		equipment_button.hide()
	if key_item_array.size() > 0:
		key_item_button.show()
		if key_item_button.pressed.is_connected(repopulate_list):
			key_item_button.pressed.disconnect(repopulate_list)
		key_item_button.pressed.connect(repopulate_list.bind(key_item_array))
	else:
		key_item_button.hide()
	if services_array.size() > 0:
		services_button.show()
		if services_button.pressed.is_connected(repopulate_list):
			services_button.pressed.disconnect(repopulate_list)
		services_button.pressed.connect(repopulate_list.bind(services_array))
	else:
		services_button.hide()
	repopulate_list(consumables_array)

func repopulate_list(items : Array):
	current_array = items
	var names_array = []
	for i in item_container.get_children(true):
		item_container.remove_child(i)
		i.queue_free()
	for item : ItemResource in items:
		if (!selling and GameState.shop_states[current_shop.shop_id][item.item_name] <= 0) or item.item_name in names_array:
			continue
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 65)
		#button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.text = item.item_name
		button.pressed.connect(select_item.bind(item))
		item_container.add_child(button)
		names_array.append(item.item_name)
	if !topleft_layout.visible:
		topleft_layout.offset_transform_position_ratio = Vector2(-1.5, 0)
		topleft_layout.show()
	tween_in("left")
		
func intro_dialogue(text : String):
	dialogue_label.text = text
	dialogue_popup.show()
	await get_tree().create_timer(2.0).timeout
	dialogue_popup.hide()
	tween_in()

func dialogue(text : String = "", shift : Vector2 = Vector2(-0.01, 0)):
	dialogue_popup.hide()
	var tween = create_tween()
	#await get_tree().create_timer(0.5).timeout
	tween.tween_property(dialogue_popup, "offset_transform_position_ratio", shift, 0.5)
	#dialogue_popup.offset_transform_position_ratio = shift
	if text != "":
		dialogue_label.text = text
		dialogue_popup.show()

func select_item(item : ItemResource):
	current_item = item
	var cost
	if !selling:
		cost = roundi(current_item.value * current_shop.buy_modifier)
		print("Gold: %s, Cost: %s" % [GameState.gold, cost])
		if cost > GameState.gold:
			buy_button.disabled = true
		else:
			buy_button.disabled = false
	else:
		cost = roundi(current_item.value * current_shop.sell_modifier)
	var output = "%s: %s \n$%s" % [item.item_name, item.description, cost]
	dialogue(output)

func tween_in(which = "both"):
	if which in ["left", "both"]:
		var tween = create_tween()
		if !topleft_layout.visible:
			topleft_layout.show()
		tween.tween_property(topleft_layout, "offset_transform_position_ratio", Vector2(0,0), 0.5)
		tween.tween_property(topleft_layout, "offset_transform_scale", Vector2(1,1), 0.5)
	if which in ["bottom", "both"]: 
		var tween2 = create_tween()
		tween2.tween_property(buttons_container, "offset_transform_position_ratio", Vector2(0,0), 0.5)

func tween_out(which = "both"):
	if which in ["left", "both"]:
		var tween = create_tween()
		tween.tween_property(topleft_layout, "offset_transform_position_ratio", Vector2(-1.5,0), 0.5)
		tween.tween_property(topleft_layout, "offset_transform_scale", Vector2(0,1), 0.5)
		tween.finished.connect(func(): topleft_layout.hide())
	if which in ["bottom", "both"]: 
		var tween2 = create_tween()
		tween2.tween_property(buttons_container, "offset_transform_position_ratio", Vector2(0, 1.5), 0.5)

func button_mode(mode = "main"):
	buy_button.disabled = false
	sell_button.disabled = false
	for x in buy_button.pressed.get_connections():
		buy_button.pressed.disconnect(x.callable)
	for y in sell_button.pressed.get_connections():
		sell_button.pressed.disconnect(y.callable)
	match mode:
		"main":
			selling = false
			buy_button.text = "BUY"
			sell_button.text = "SELL"
			buy_button.pressed.connect(func():
				selling = false
				repopulate_arrays(current_shop.stock)
				button_mode("buy")
				dialogue()
				)
			sell_button.pressed.connect(func():
				selling = true
				repopulate_arrays(GameState.inventory)
				button_mode("sell")
				dialogue()
				)
		"buy":
			selling = false
			buy_button.text = "BUY"
			sell_button.text = "BACK"
			buy_button.pressed.connect(func(): 
				ShopManager.purchase_item(current_item)
				dialogue(bought_item_text)
				)
			sell_button.pressed.connect(func():
				button_mode("main")
				tween_out("left")
				dialogue(main_menu_text, Vector2(-0.38,0))
				)
		"sell":
			selling = true
			buy_button.text = "SELL"
			sell_button.text = "BACK"
			buy_button.pressed.connect(func():
				ShopManager.sell_item(current_item)
				repopulate_arrays(GameState.inventory)
				
				dialogue(sold_item_text)
				)
			sell_button.pressed.connect(func():
				button_mode("main")
				tween_out("left")
				dialogue(main_menu_text, Vector2(-0.38,0))
				)
