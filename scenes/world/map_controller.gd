extends Node
class_name MapController

@export var zone_name := ""
@export var safe_zone_scene := ""
@export var safe_zone_warp_id := ""
@export var camera_bounds = Rect2(Vector2.ZERO, Vector2(640,480))

var player : Player
@onready var warps : Node2D = $"../Warps"
var pending_warp : WarpPoint

func _ready() -> void:
	#print("pending_warp_id: ", GameState.pending_warp_id)
	#print("previous_player_location: ", GameState.previous_player_location)
	if safe_zone_scene != "" and safe_zone_warp_id != "":
		GameState.previous_safe_zone = [safe_zone_scene, safe_zone_warp_id]
	#print(GameState.previous_safe_zone)
	player = get_tree().get_nodes_in_group('player')[0]
	for warp in warps.get_children():
		if warp is WarpPoint and (warp as WarpPoint).warp_id == GameState.pending_warp_id:
			pending_warp = warp
			break
	if pending_warp:
		pending_warp.just_spawned = true
		player.set_camera_limits(camera_bounds)
		player.global_position = pending_warp.global_position
	elif GameState.previous_player_location != Vector2(-1, -1):
		player.set_camera_limits(camera_bounds)
		player.global_position = GameState.previous_player_location
		player.party_member.previous_location = null

#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("ui_accept"):
		#if GameState.shopping:
			#return
		##var group = load("res://data/enemy_groups/Slime_Slime_Slime.tres")
		##GameState.previous_player_location = player.global_position
		##SceneManager.start_combat(group)
