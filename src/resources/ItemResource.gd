class_name ItemResource
extends Resource

enum ItemType { CONSUMABLE, EQUIPMENT, KEY_ITEM, SERVICE }
enum ConsumableEffect {NONE, HEAL_HP, HEAL_MP, REVIVE, CURE_STATUS, CUSTOM}
enum EquipSlot {NONE, HEAD, TORSO, LEGS, HAND, FOOT, RING, TOE_RING}

@export_group("Item")
@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var value: int = 0       # Gold value for shops
@export var stackable: bool = true
@export var max_stack: int = 99
#@export var quantity: int = 1
@export_group("Consumable Effect")
@export var effect_type: ConsumableEffect = ConsumableEffect.NONE
@export var effect_value: int
@export var custom_effects: Array[int] # Only in use for custom ConsumableEffects. CUSTOM is not allowed here
@export var custom_values: Array[int] # Only in use for custom ConsumableEffects, must have same number of entries as Custom Effects, valuless effects use 0
@export_group("Equipment")
@export var equip_slot: EquipSlot = EquipSlot.NONE
@export var two_handed : bool = false
@export var stat_modifiers: Dictionary # Must match statblock keys EXACTLY "str", "agi", "vit", "intelligence", "wil"
@export_group("Key Item")
@export var sets_flag: String = ""
func apply_to(stats : CharacterStatBlock) -> bool:
	match effect_type:
		ItemResource.ConsumableEffect.HEAL_HP:
			if stats.current_hp == stats.max_hp():
				return false
			stats.current_hp = clampi(stats.current_hp + effect_value, 0, stats.max_hp())
		ItemResource.ConsumableEffect.HEAL_MP:
			if stats.current_mp == stats.max_mp():
				return false
			stats.current_mp = clampi(stats.current_mp + effect_value, 0, stats.max_mp())
		ItemResource.ConsumableEffect.REVIVE:
			if stats.current_hp <= 0:
				stats.current_hp = 10
			else:
				return false
		ItemResource.ConsumableEffect.CURE_STATUS:
			pass # handled via combatmanager
			#if combatant.active_statuses.size() > 0:
				#combatant.active_statuses = []
		ItemResource.ConsumableEffect.CUSTOM:
			var is_true = false
			for i in custom_effects.size():
				match custom_effects[i]:
					ItemResource.ConsumableEffect.HEAL_HP:
						if stats.current_hp != stats.max_hp():
							is_true = true
						stats.current_hp = clampi(stats.current_hp + custom_values[i], 0, stats.max_hp())
					ItemResource.ConsumableEffect.HEAL_MP:
						if stats.current_mp != stats.max_mp():
							is_true = true
						stats.current_mp = clampi(stats.current_mp + custom_values[i], 0, stats.max_mp())
					ItemResource.ConsumableEffect.REVIVE:
						if stats.current_hp <= 0:
							is_true = true
							stats.current_hp = 10
					ItemResource.ConsumableEffect.CURE_STATUS:
						pass # handled via combatmanager
						#if combatant.active_statuses.size() > 0:
							#combatant.active_statuses = []
			return is_true
		ItemResource.ConsumableEffect.NONE:
			pass
	return true

func stats_to_text() -> String:
	var output = ""
	for i in stat_modifiers.keys().size():
		output += "%s: " % stat_modifiers.keys()[i]
		if stat_modifiers[stat_modifiers.keys()[i]] > 0:
			output += "+"
		output += "%s" % stat_modifiers[stat_modifiers.keys()[i]]
		if i < stat_modifiers.keys().size() -1:
			output += ", "
	if !(effect_type == ConsumableEffect.NONE):
		if output != "":
			output += " | "
		if effect_type != ConsumableEffect.CUSTOM:
			output += "%s " % ItemResource.ConsumableEffect.keys()[effect_type]
			if effect_value > 0:
				output += "+"
			output += "%s" % effect_value
		else:
			for i in custom_effects.size():
				output += "%s " % ItemResource.ConsumableEffect.keys()[custom_effects[i]]
				if custom_values[i] > 0:
					output += "+"
				output += "%s" % custom_values[i]
				if i < custom_effects.size()-1:
					output += ", "
	return output
