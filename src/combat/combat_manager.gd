extends Node
class_name CombatManager

@warning_ignore_start("integer_division")

enum State {
	IDLE          , # waiting for something to happen (brief, between states)
	PLAYER_INPUT  , # player is choosing an action
	TARGET_SELECT , # player is choosing a target
	RESOLVING     , # an action is executing (damage applied, log updated)
	# STATUS_TICK   , # status effects proc at start/end of turn
	ENEMY_TURN    , # AI is selecting and executing an action
	VICTORY       , # all enemies dead, award EXP/gold
	DEFEAT        , # all party members dead
	FLED          , # ran successfully
}

var _turn_queue: Array[BattleCombatant] = []
var _current_turn_index: int = -1
var current_combatant : BattleCombatant = null
var _state: State = State.IDLE
var _pending_action: BattleAction = null
var _pending_targets: Array[BattleCombatant] = []
var _pending_item: ItemResource = null
var _enemy_group: EnemyGroupResource = null
var _party_members: Array[PartyMemberResource] = []
var _enemy_combatants : Array[BattleCombatant] = []
var _party_combatants: Array[BattleCombatant] = []

func _ready() -> void:
	#EventBus.combat_started.connect(start_battle)
	EventBus.player_action_selected.connect(_on_player_action_selected)
	EventBus.player_item_selected.connect(_on_player_item_selected)
	EventBus.player_targets_selected.connect(_on_player_targets_selected)
	EventBus.player_flee_attempted.connect(_on_player_flee_attempted)
	EventBus.combat_visuals_ready.connect(start_next_turn)
	if GameState.pending_enemy_group != null:
		start_battle(GameState.pending_enemy_group)
		GameState.pending_enemy_group = null

func start_battle(enemy_group : EnemyGroupResource):
	_enemy_group = enemy_group
	_party_members = GameState.party
	for entity in _party_members + _enemy_group.enemies:
		var combatant : BattleCombatant
		if entity is PartyMemberResource:
			combatant = BattleCombatant.create_party_member(entity)
			_party_combatants.append(combatant)
		elif entity is EnemyResource:
			entity.stats.character_name = entity.enemy_name
			combatant = BattleCombatant.create_enemy(entity)
			_enemy_combatants.append(combatant)
		_turn_queue.append(combatant)
	_turn_queue.sort_custom(func(a : BattleCombatant, b : BattleCombatant): return a.effective_stat("agi") > b.effective_stat("agi"))
	EventBus.combat_queued.emit(_turn_queue)
	#start_next_turn()

func start_next_turn():
	await get_tree().create_timer(0.3).timeout
	_state = State.IDLE
	advance_index()
	if !any_alive(true): # handle failure
		_handle_defeat()
		return
	if !any_alive(false): # handle victory
		_handle_victory()
		return
	current_combatant = _turn_queue[_current_turn_index]
	while not current_combatant.is_alive():
		advance_index()
		current_combatant = _turn_queue[_current_turn_index]
	EventBus.turn_started.emit(current_combatant)
	if current_combatant.is_player_controlled:
		_state = State.PLAYER_INPUT
		EventBus.player_turn_started.emit()
	else:
		_state = State.ENEMY_TURN
		_run_enemy_turn()

func _handle_defeat():
	_state = State.DEFEAT
	#EventBus.combat_ended.emit("defeat")
	_process_party_progression()
	var player : PartyMemberResource
	for i : PartyMemberResource in _party_members:
		if i.is_player:
			i.stats.current_hp = i.stats.max_hp()/2
	SceneManager.end_combat("defeat")

func _handle_victory():
	_state = State.VICTORY
	for i in _enemy_group.enemies:
		GameState.add_gold(i.gold_reward)
		for ii : PartyMemberResource in _party_members:
			ii.pending_xp += i.experience_reward 
		GameState.inventory_drop(i.drop_table)
		for equipment : ItemResource in i.get_all_equipped_items():
			if randf() < i.equip_drop_chance:
				GameState.give_item(equipment)
		#for equipment in i.equipped.keys():
			#if !(i.equipped[equipment] is Array):
				#if i.equipped[equipment] != null:
					#var item : ItemResource = i.equipped[equipment]
					#if randf() < i.equip_drop_chance:
						#GameState.give_item(item)
			#else:
				#for item in i.equipped[equipment]:
					#if item is ItemResource:
						#if randf() < i.equip_drop_chance:
							#GameState.give_item(item)
	GameState.inventory_transfer()
	_process_party_progression()
	SceneManager.end_combat("victory")

func _run_enemy_turn():
	if !current_combatant.can_act():
		var log_string = "%s is " % current_combatant.stats.character_name
		for status in current_combatant.source_resource.active_statuses:
			if status["effect"].status_type == StatusEffect.StatusType.SLEEP:
				log_string += "asleep"
				current_combatant.tick_statuses()
				break
			elif status["effect"].status_type == StatusEffect.StatusType.STUN:
				log_string += "stunned"
				current_combatant.tick_statuses()
				break
		EventBus.combat_log_updated.emit(log_string)
		start_next_turn()
	else:
		var enemy_data = current_combatant.source_resource as EnemyResource
		var party = living_entities(_party_combatants)
		party.sort_custom(func(a : BattleCombatant, b : BattleCombatant): return a.stats.current_hp>b.stats.current_hp)
		var enemies = living_entities(_enemy_combatants)
		enemies.sort_custom(func(a : BattleCombatant, b : BattleCombatant): return a.stats.current_hp>b.stats.current_hp)
		var targets : Array[BattleCombatant] = []
		var action : BattleAction
		match enemy_data.behavior:
			EnemyResource.AIBehavior.RANDOM: 
				targets.append(party.pick_random())
				action = (current_combatant.physical_actions + current_combatant.return_available_magic_actions()).pick_random()
			EnemyResource.AIBehavior.AGGRESSIVE:
				targets.append(party[0])
				action = (current_combatant.physical_actions + current_combatant.return_available_magic_actions()).pick_random()
			EnemyResource.AIBehavior.DEFENSIVE:
				targets.append(party[-1])
				action = (current_combatant.physical_actions + current_combatant.return_available_magic_actions()).pick_random()
			EnemyResource.AIBehavior.HEALER:
				targets.append(enemies[-1])
				action = current_combatant.return_available_healing_actions().pick_random()
			EnemyResource.AIBehavior.BERSERKER:
				targets.append(party[0])
				action = (current_combatant.physical_actions + current_combatant.return_available_magic_actions()).pick_random()
		if action == null:
			EventBus.combat_log_updated.emit("%s does nothing" % current_combatant.stats.character_name)
			start_next_turn()
			return
		_resolve_action(current_combatant, targets, action)

func living_entities(array : Array[BattleCombatant]) -> Array[BattleCombatant]:
	var new_array = array.duplicate()
	for i in array:
		if !i.is_alive():
			new_array.erase(i)
	return new_array

func _resolve_action(attacker : BattleCombatant, targets : Array[BattleCombatant], action : BattleAction):
	EventBus.combat_action_resolving.emit()
	_state = State.RESOLVING
	var healing = action.damage_type == BattleAction.DamageType.HEALING
	if action.category == BattleAction.ActionCategory.MAGIC:
		attacker.stats.current_mp -= action.mp_cost
	for target in targets:
		if action.category == BattleAction.ActionCategory.ATTACK:
			_resolve_attack(attacker, target, action)
			#EventBus.combat_log_updated.emit("%s attacks %s" % [attacker.stats.character_name, target.stats.character_name])
			#var damage = (attacker.effective_stat("str") * action.power) / maxf(1.0, target.effective_stat("vit"))
			#if accuracy_check(attacker):
				#if attacker.is_player_controlled:
					#(attacker.source_resource as PartyMemberResource).accumulate("str", target.effective_stat("vit"))
					#(attacker.source_resource as PartyMemberResource).accumulate("agi", target.effective_stat("agi"))
				#elif target.is_player_controlled:
					#(target.source_resource as PartyMemberResource).accumulate("vit", damage)
					#(target.source_resource as PartyMemberResource).accumulate("agi", attacker.effective_stat("agi"))
				#target.take_damage(roundi(damage))
				#EventBus.combatant_damaged.emit(target, roundi(damage))
			#else:
				#EventBus.combat_log_updated.emit("%s missed" % attacker.stats.character_name)
		elif action.category == BattleAction.ActionCategory.MAGIC:
			_resolve_magic(attacker, target, action, healing)
			#if !healing:
				#var damage = (attacker.effective_stat("intelligence") * action.power) / maxf(1.0, target.effective_stat("wil"))
				#EventBus.combat_log_updated.emit("%s casts %s" % [attacker.stats.character_name, action.action_name])
				#if accuracy_check(attacker):
					#if attacker.is_player_controlled:
						#(attacker.source_resource as PartyMemberResource).accumulate("intelligence", target.effective_stat("wil"))
					#target.take_damage(roundi(damage))
					#EventBus.combatant_damaged.emit(target, roundi(damage))
				#else:
					#EventBus.combat_log_updated.emit("%s missed" % attacker.stats.character_name)
			#else:
				#var amount = (attacker.effective_stat("intelligence") * action.power)
				#EventBus.combat_log_updated.emit("%s casts %s" % [attacker.stats.character_name, action.action_name])
				#if attacker.is_player_controlled:
					#(attacker.source_resource as PartyMemberResource).accumulate("wil", amount)
					#(attacker.source_resource as PartyMemberResource).accumulate("intelligence", amount * 0.5)
				#target.heal(roundi(amount))
				#EventBus.combatant_healed.emit(target, roundi(amount))
		elif action.category == BattleAction.ActionCategory.SKILL:
			EventBus.combat_log_updated.emit("%s uses %s" % [attacker.stats.character_name, action.action_name])
		if action.status_to_apply != null:
			if randf()<action.status_chance:
				if target.apply_status(action.status_to_apply):
					EventBus.combatant_status_applied.emit(target, action.status_to_apply)
		if !target.is_alive():
			EventBus.combatant_died.emit(target)
			
	attacker.tick_statuses()
	#start_next_turn.call_deferred()
	EventBus.combat_animations_finished.connect(start_next_turn, CONNECT_ONE_SHOT)
	_pending_action = null

func _resolve_attack(attacker, target, action):
	EventBus.combat_log_updated.emit("%s attacks %s" % [attacker.stats.character_name, target.stats.character_name])
	var damage = (attacker.effective_stat("str") * action.power) / maxf(1.0, target.effective_stat("vit"))
	if accuracy_check(attacker):
		if attacker.is_player_controlled:
			(attacker.source_resource as PartyMemberResource).accumulate("str", target.effective_stat("vit"))
			(attacker.source_resource as PartyMemberResource).accumulate("agi", target.effective_stat("agi"))
		elif target.is_player_controlled:
			(target.source_resource as PartyMemberResource).accumulate("vit", damage)
			(target.source_resource as PartyMemberResource).accumulate("agi", attacker.effective_stat("agi"))
		target.take_damage(roundi(damage))
		EventBus.combatant_damaged.emit(target, roundi(damage))
	else:
		EventBus.combat_log_updated.emit("%s missed" % attacker.stats.character_name)

func _resolve_magic(attacker, target, action, healing):
	if !healing:
		var damage = (attacker.effective_stat("intelligence") * action.power) / maxf(1.0, target.effective_stat("wil"))
		EventBus.combat_log_updated.emit("%s casts %s" % [attacker.stats.character_name, action.action_name])
		if accuracy_check(attacker):
			if attacker.is_player_controlled:
				(attacker.source_resource as PartyMemberResource).accumulate("intelligence", target.effective_stat("wil"))
			target.take_damage(roundi(damage))
			EventBus.combatant_damaged.emit(target, roundi(damage))
		else:
			EventBus.combat_log_updated.emit("%s missed" % attacker.stats.character_name)
	else:
		var amount = (attacker.effective_stat("intelligence") * action.power)
		EventBus.combat_log_updated.emit("%s casts %s" % [attacker.stats.character_name, action.action_name])
		if attacker.is_player_controlled:
			(attacker.source_resource as PartyMemberResource).accumulate("wil", amount)
			(attacker.source_resource as PartyMemberResource).accumulate("intelligence", amount * 0.5)
		target.heal(roundi(amount))
		EventBus.combatant_healed.emit(target, roundi(amount))

func _resolve_healing():
	pass

func _resolve_item(attacker : BattleCombatant, targets : Array[BattleCombatant], item : ItemResource):
	EventBus.combat_action_resolving.emit()
	_state = State.RESOLVING
	var item_used : bool = false
	for combatant : BattleCombatant in targets:
		var hp_before = combatant.stats.current_hp
		item_used = item.apply_to(combatant.stats)
		if item_used:
			if combatant.stats.current_hp > hp_before:
				EventBus.combatant_healed.emit(combatant, combatant.stats.current_hp - hp_before)
			if item.effect_type == ItemResource.ConsumableEffect.CURE_STATUS:
				if combatant.source_resource.active_statuses.size() > 0:
					combatant.source_resource.active_statuses = []
			elif item.effect_type == ItemResource.ConsumableEffect.CUSTOM:
					for i in item.custom_effects.size():
						if item.custom_effects[i] == ItemResource.ConsumableEffect.CURE_STATUS:
							if combatant.source_resource.active_statuses.size() > 0:
								combatant.source_resource.active_statuses = []
	if item_used:
		item.quantity -= 1
		if item.quantity <= 0:
			if attacker.is_player_controlled:
				GameState.inventory.erase(item)
			else:
				attacker.source_resource.inventory.erase(item)
		EventBus.item_used.emit(item)
	attacker.tick_statuses()
	EventBus.combat_animations_finished.connect(start_next_turn, CONNECT_ONE_SHOT)
	_pending_item = null

func _on_player_action_selected(action: BattleAction):
	if _state == State.PLAYER_INPUT:
		_pending_action = action
		_state = State.TARGET_SELECT
		if action.target_type == BattleAction.TargetType.ALL_ENEMIES or action.target_type == BattleAction.TargetType.ALL_ALLIES:
			EventBus.all_targets.emit()
		var valid_targets = get_targets(action.target_type)
		EventBus.target_select_requested.emit(valid_targets)

func _on_player_item_selected(item: ItemResource):
	if _state == State.PLAYER_INPUT:
		_pending_item = item
		_state = State.TARGET_SELECT
		var valid_targets = get_targets(BattleAction.TargetType.SINGLE_ALLY)
		EventBus.target_select_requested.emit(valid_targets)

func get_targets(target_type : BattleAction.TargetType):
	if target_type == BattleAction.TargetType.SINGLE_ENEMY or target_type == BattleAction.TargetType.ALL_ENEMIES:
		if current_combatant.is_player_controlled:
			return living_entities(_enemy_combatants)
		else:
			return living_entities(_party_combatants)
	elif target_type == BattleAction.TargetType.SINGLE_ALLY or target_type == BattleAction.TargetType.ALL_ALLIES:
		if current_combatant.is_player_controlled:
			return living_entities(_party_combatants)
		else:
			return living_entities(_enemy_combatants)
	elif target_type == BattleAction.TargetType.SELF:
		return [current_combatant]

func _on_player_targets_selected(targets: Array[BattleCombatant]):
	if _state == State.TARGET_SELECT:
		_pending_targets = targets
		if _pending_action != null:
			_resolve_action(current_combatant, _pending_targets, _pending_action)
		elif _pending_item != null:
			_resolve_item(current_combatant, _pending_targets, _pending_item)
	
func _on_player_flee_attempted():
	if _state == State.PLAYER_INPUT:
		var player_agi = 0
		var player_count = 0
		var enemy_agi = 0
		var enemy_count = 0
		for i : BattleCombatant in _turn_queue:
			if i.is_alive():
				if i.is_player_controlled:
					player_agi += i.effective_stat("agi")
					player_count += 1
				else:
					enemy_agi += i.effective_stat("agi")
					enemy_count += 1
		for i : BattleCombatant in _turn_queue:
			if i.is_alive() and i.is_player_controlled:
				(i.source_resource as PartyMemberResource).accumulate("agi", enemy_agi / enemy_count)
		EventBus.combat_log_updated.emit("%s attempted to flee" % current_combatant.stats.character_name)
		if float(player_agi) / float(player_count) > (float(enemy_agi) / float(enemy_count) * 0.8):
			_state = State.FLED
			EventBus.combat_log_updated.emit("%s fled" % current_combatant.stats.character_name)
			#EventBus.combat_ended.emit("fled")
			_process_party_progression()
			SceneManager.end_combat("fled")
		else:
			EventBus.combat_log_updated.emit("%s failed to escape" % current_combatant.stats.character_name)
			start_next_turn()

func _process_party_progression():
	for i : BattleCombatant in _turn_queue:
		if i.is_player_controlled:
			(i.source_resource as PartyMemberResource).process_progression()

func accuracy_check(attacker : BattleCombatant) -> bool:
	var hit_roll = randf()
	var accuracy = 1.0
	# apply accuracy modifier from any BLIND status on attacker
	for status in attacker.source_resource.active_statuses:
		accuracy *= status["effect"].accuracy_modifier
	return hit_roll <= accuracy

func advance_index() -> void:
	_current_turn_index = (_current_turn_index + 1) % _turn_queue.size()

func any_alive(player_controlled : bool) -> bool:
	for i : BattleCombatant in _turn_queue:
		if i.is_player_controlled == player_controlled and i.is_alive():
			return true
	return false
