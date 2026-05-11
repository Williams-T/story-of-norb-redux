extends Node

@export var camera_bounds = Rect2(Vector2.ZERO, Vector2(640,480))

var player : Player
@onready var warps : Node2D = $"../Warps"
var pending_warp : WarpPoint

func _ready() -> void:
	player = get_tree().get_nodes_in_group('player')[0]
	for warp in warps.get_children():
		if warp is WarpPoint and (warp as WarpPoint).warp_id == GameState.pending_warp_id:
			pending_warp = warp
			break
	if pending_warp:
		pending_warp.just_spawned = true
		player.set_camera_limits(camera_bounds)
		player.global_position = pending_warp.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var group = load("res://data/enemies/slime_group.tres")
		SceneManager.start_combat(group)
