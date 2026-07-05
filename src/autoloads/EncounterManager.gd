extends Node

var current_dungeon : DungeonResource = null
var player_distance : int = 0
var last_player_position := Vector2(-99999, -99999)
var player_positions := []
var player_node : Player
var delta_bank := 0.0
const TICK_RATE := 1.0
const DISTANCE_THRESHOLD := 1000
const ENCOUNTER_COOLDOWN := 10
const NEW_FLOOR_COOLDOWN := 5
var cooldown : int = 0 # measured in seconds
var returned_from_combat = false
var pre_combat_position = null

func _ready() -> void:
	set_physics_process(true)
	player_positions.clear()
	EventBus.combat_started.connect(func(_group):set_physics_process(false))
	EventBus.combat_ended.connect(func(_result):
		#print(result)
		if current_dungeon != null:
			set_physics_process(true)
			cooldown = ENCOUNTER_COOLDOWN)

func register_floor(res: DungeonResource, player: Node) -> void:
	set_physics_process(true)
	last_player_position = Vector2(-99999, -99999)
	if returned_from_combat:
		cooldown = ENCOUNTER_COOLDOWN
		#returned_from_combat = false
	else:
		cooldown = NEW_FLOOR_COOLDOWN
	current_dungeon = res
	player_node = player

func deregister_floor() -> void:
	set_physics_process(false)
	current_dungeon = null

func start_encounter(group: EnemyGroupResource, ignore_cooldown = false) -> void:
	if !GameState.in_combat: # guard if already encountering / in cooldown
		if cooldown <= 0 or ignore_cooldown == true:
			returned_from_combat = true
			EventBus.encounter_triggered.emit(group)   # for audio sting, UI flash, etc.
			SceneManager.start_combat(group)            # foundational API, allowed

func _physics_process(delta: float) -> void:
	delta_bank += delta
	if delta_bank >= TICK_RATE:
		delta_bank = 0.0
		poll_position()

func poll_position():
	if player_node != null and current_dungeon != null:
		if cooldown > 0:
			print(cooldown)
			cooldown -= 1
		if last_player_position == Vector2(-99999, -99999):
			last_player_position = player_node.global_position
			player_distance = 0
			return
		player_distance += roundi(last_player_position.distance_to(player_node.global_position))
		if player_node.global_position != last_player_position:
			last_player_position = player_node.global_position
			player_positions.append(last_player_position)
			if player_positions.size() > 3:
				player_positions.remove_at(0)
			#print(player_positions)
		if player_distance > DISTANCE_THRESHOLD and cooldown <= 0:
			roll_encounter()

func roll_encounter() -> void:
	player_distance = 0
	var roll = randf()
	print(roll, " rate: ", current_dungeon.encounter_rate)
	if roll < current_dungeon.encounter_rate:
		var group : EnemyGroupResource = choose_weighted_group()
		if group == null:
			push_warning("null group")
		else:
			start_encounter(group)

func choose_weighted_group() -> EnemyGroupResource:
	if current_dungeon.encounter_groups.is_empty() or current_dungeon.encounter_groups.size() != current_dungeon.encounter_weights.size():
		push_warning("groups empty or mismatched with weights\nGroups: %s, Weights: %s" % [current_dungeon.encounter_groups.size(), current_dungeon.encounter_weights.size()])
		return null
	var total : float = 0.0
	for w in current_dungeon.encounter_weights:
		total += w
	var roll = randf() * total
	for idx in current_dungeon.encounter_weights.size():
		roll -= current_dungeon.encounter_weights[idx]
		if roll <= 0.0:
			return current_dungeon.encounter_groups[idx]
	return current_dungeon.encounter_groups[-1]

func consume_player_position():
	if !player_positions.is_empty():
		return player_positions[0]
	else:
		return null
