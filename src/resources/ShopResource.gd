class_name ShopResource
extends Resource

@export var shop_id: String # used as the cache key in GameState
@export var shop_name: String
@export var stock: Array[ItemResource]
@export var buy_modifier: float = 1.0
@export var sell_modifier: float = 0.8
@export var item_quantities: Dictionary = {}
@export var bg_texture : Texture
@export var fg_closed_texture : Texture
@export var fg_open_texture : Texture
@export var intro_text = "Welcome to the shop\nHow can I help you?"
@export var bought_item_text = "Would you like to buy anything else?"
@export var sold_item_text = "Would you like to sell anything else?"
@export var main_menu_text = "Anything else I can help you with?"
@export var exit_text = "Alright, see you next time!"
