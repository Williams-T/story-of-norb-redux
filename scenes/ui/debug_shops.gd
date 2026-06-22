extends HBoxContainer
class_name DebugShops

@onready var shops_container : VBoxContainer = $VBoxContainer/ScrollContainer/ShopsContainer
@onready var open_button : Button = $OpenButton

var current_shop : ShopResource
var parent 

func _ready() -> void:
	refresh_shops()
	open_button.pressed.connect(open_shop)

func refresh_shops():
	for i in shops_container.get_children():
		shops_container.remove_child(i)
		i.queue_free()
	var shops = DirAccess.get_files_at("res://data/shops/")
	for shop in shops:
		var loaded : ShopResource = load("res://data/shops/%s" % shop)
		var button := Button.new()
		button.text = shop
		button.pressed.connect(func(): current_shop = loaded; shop_selected(button))
		shops_container.add_child(button)

func shop_selected(button : Button):
	for i : Button in shops_container.get_children():
		i.remove_theme_color_override("font_color")
	button.add_theme_color_override("font_color", Color.GOLD)
	if open_button.disabled:
		open_button.disabled = false

func open_shop():
	ShopManager.open_shop(current_shop)
	parent.hide()
	
