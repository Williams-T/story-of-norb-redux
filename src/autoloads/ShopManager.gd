# shop_manager.gd
extends Node
@warning_ignore_start("unused_variable")
@warning_ignore_start("unused_parameter")
@warning_ignore_start("narrowing_conversion")

const SHOP_UI_SCENE = preload("res://scenes/ui/ShopUI.tscn")
var _shop_ui : ShopUI
var current_shop : ShopResource

func _ready() -> void:
	EventBus.shop_interaction_requested.connect(open_shop)
	_shop_ui = SHOP_UI_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(_shop_ui)
	_shop_ui.hide()

func open_shop(shop : ShopResource):
	if !_shop_ui.visible:
		_shop_ui.show()
	current_shop = shop
	EventBus.player_movement_locked.emit()
	var stock = GameState.get_shop_stock(shop)
	EventBus.shop_opened.emit(shop)

func close_shop():
	EventBus.shop_closed.emit()
	_shop_ui.hide()
	_shop_ui.close_shop()
	EventBus.player_movement_unlocked.emit()

func purchase_item(item : ItemResource, quantity : int = 1):
	if GameState.spend_gold(roundi((item.value * quantity)*current_shop.buy_modifier)):
		_shop_ui.refresh_gold()
		if item.item_type != ItemResource.ItemType.SERVICE:
			for i in quantity:
				GameState.give_item(item.duplicate(true))
				if item.item_name in GameState.shop_states[current_shop.shop_id].keys():
					GameState.shop_states[current_shop.shop_id][item.item_name] -= 1
			EventBus.item_purchased.emit(item, quantity)
			GameState.inventory_transfer()
			#GameState.rescan_quantities()
			_shop_ui.refresh_inventory()
			_shop_ui.repopulate_list(_shop_ui.current_array)
		else:
			pass # TODO: Implement service logic in purchase_service
		#print(GameState.shop_states[current_shop.shop_id])
		#print(_shop_ui.inventory)

func sell_item(item : ItemResource, quantity : int = 1):
	EventBus.item_sold.emit(item, quantity)
	for i in quantity:
		var _item : ItemResource = search_for_item(item)
		if _item == null:
			continue
		#_item.quantity -= 1
		#if _item.quantity <= 0:
		#GameState.inventory.erase(_item)
		GameState.remove_item(_item)
		#GameState.rescan_quantities()
		GameState.add_gold(roundi(item.value * current_shop.sell_modifier))
		_shop_ui.refresh_gold()
		if item.item_name in GameState.shop_states[current_shop.shop_id].keys():
			GameState.shop_states[current_shop.shop_id][item.item_name] += 1
		else:
			GameState.shop_states[current_shop.shop_id][item.item_name] = 1
			current_shop.stock.append(item)
	#print(GameState.shop_states[current_shop.shop_id])

func search_for_item(item : ItemResource):
	for i : ItemResource in GameState.inventory:
		if i.item_name == item.item_name:
			return i
	return null

func test_shop():
	var new_shop := load("res://data/shops/demo.tres")
	open_shop(new_shop)
	#current_shop = new_shop
	#EventBus.shop_opened.emit(new_shop)
