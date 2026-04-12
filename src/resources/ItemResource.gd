class_name ItemResource
extends Resource

enum ItemType { CONSUMABLE, EQUIPMENT, KEY_ITEM }

@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var value: int = 0       # Gold value for shops
@export var stackable: bool = true
@export var max_stack: int = 99
