#BattleCombatant
class_name BattleCombatant
extends RefCounted

var stats: CharacterStatBlock 
var is_player_controlled: bool
#var active_statuses: Array[Dictionary] = []
var source_resource : EntityResource
var physical_actions: Array[BattleAction] = []
var magic_actions: Array[BattleAction] = []
var healing_actions: Array[BattleAction] = []
var other_actions: Array[BattleAction] = []
#var inventory : Array[ItemResource] = []

func _init(char_stats : CharacterStatBlock) -> void:
	stats = char_stats
	if stats.current_hp == -1:
		stats.current_hp = stats.max_hp()
	if stats.current_mp == -1:
		stats.current_mp = stats.max_mp()

static func create_enemy(character : EnemyResource) -> BattleCombatant:
	var combatant = BattleCombatant.new(character.stats.duplicate(true))
	combatant.is_player_controlled = false
	combatant.source_resource = character.duplicate_deep()
	character.stats.character_name = character.enemy_name
	combatant.create_action_arrays(character.actions)
	return combatant

static func create_party_member(character : PartyMemberResource) -> BattleCombatant:
	var combatant = BattleCombatant.new(character.stats)
	combatant.is_player_controlled = true
	combatant.source_resource = character.duplicate_deep()
	combatant.create_action_arrays(character.actions)
	return combatant

func create_action_arrays(actions : Array[BattleAction]):
	for action : BattleAction in actions:
		match action.damage_type:
			action.DamageType.PHYSICAL:
				physical_actions.append(action)
			action.DamageType.MAGICAL:
				magic_actions.append(action)
			action.DamageType.HEALING:
				healing_actions.append(action)
			action.DamageType.NONE:
				other_actions.append(action)

func return_available_magic_actions() -> Array[BattleAction]:
	var array : Array[BattleAction] = []
	for action : BattleAction in magic_actions:
		if action.mp_cost <= stats.current_mp:
			array.append(action)
	return array

func return_available_healing_actions() -> Array[BattleAction]:
	var array : Array[BattleAction] = []
	for action : BattleAction in healing_actions:
		if action.mp_cost <= stats.current_mp:
			array.append(action)
	return array

#func max_hp() -> int:
	#return 20 + (stats.vit * 8) + (stats.level * 5)
#func max_mp() -> int:
	#return 10 + (stats.wil * 5) + (stats.level * 3)
func is_alive() -> bool: # reads stats.current_hp
	return stats.current_hp > 0
func can_act() -> bool: # checks is_alive() and whether any active status blocks_action
	if is_alive():
		if source_resource.active_statuses.is_empty():
			return true
		else:
			for i in source_resource.active_statuses:
				if i["effect"].blocks_action == true:
					return false
			return true
	else:
		return false
func take_damage(amount: int) -> void: # subtracts from stats.current_hp, clamps to zero
	stats.current_hp = clampi(stats.current_hp - amount, 0, stats.max_hp())
	print("%s HP: %s" % [stats.character_name, stats.current_hp])
func heal(amount: int) -> void: # adds to stats.current_hp, clamps to max_hp()
	stats.current_hp = clampi(stats.current_hp + amount, 0, stats.max_hp())
func apply_status(status: StatusEffect) -> bool: # appends to active_statuses, but only if not already present
	var new = true
	for i in source_resource.active_statuses:
		if i["effect"] == status:
			new = false
	if new == true:
		source_resource.active_statuses.append({"effect" = status, "turns_remaining" = status.duration_turns})
	return new
func tick_statuses() -> void: #decrements duration_turns on each status, removes expired ones, applies damage_per_turn for POISON
	var statuses = source_resource.active_statuses.duplicate()
	for status in statuses:
		status["turns_remaining"] -= 1
		if status["effect"].damage_per_turn > 0.0:
			take_damage(status["effect"].damage_per_turn)
			if !is_alive():
				EventBus.combatant_died.emit(self)
				return
			EventBus.combatant_damaged.emit(self, roundi(status["effect"].damage_per_turn))
			EventBus.combat_log_updated.emit("%s damaged by %s" % [stats.character_name, status["effect"].status_name])
		if status["turns_remaining"] <= 0:
			source_resource.active_statuses.erase(status)
		print("%s is %s with %s turns left." % [stats.character_name, status["effect"].status_name, status["turns_remaining"]])
func effective_stat(stat : String) -> float:
	var base_stat = source_resource.stats.get(stat)
	var stat_mod = source_resource.stat_mods.get(stat, 0.0)
	var stat_bonus = source_resource.get_bonus(stat)
	if base_stat != null:
		return base_stat + stat_mod + stat_bonus
	else:
		push_error("effective stat typo: %s" % stat)
		return stat_mod + stat_bonus
