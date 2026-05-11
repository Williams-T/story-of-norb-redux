class_name ItemResource
extends Resource

enum ItemType { CONSUMABLE, EQUIPMENT, KEY_ITEM }
enum ConsumableEffect {NONE, HEAL_HP, HEAL_MP, REVIVE, CURE_STATUS, CUSTOM}
enum EquipSlot {NONE, WEAPON, ARMOR, ACCESSORY}
@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var value: int = 0       # Gold value for shops
@export var stackable: bool = true
@export var max_stack: int = 99
@export var effect_type: ConsumableEffect
@export var effect_value: int
@export var custom_effects: Array[int]
@export var custom_values: Array[int]
@export var equip_slot: EquipSlot
@export var stat_modifiers: Dictionary
