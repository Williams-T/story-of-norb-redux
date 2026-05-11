extends Area2D
class_name  WarpPoint

@export var warp_id := ""
@export var warp_definition : WarpDefinition
@export var require_interact := false

var just_spawned := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.interact_pressed.connect(try_interact)

func _on_body_entered(body: Node2D) -> void:
	if just_spawned:
		return
	if require_interact == false and body.is_in_group('player'):
		_execute_warp()

func try_interact():
	if not require_interact:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group('player'):
			_execute_warp()
			return

func _execute_warp():
	SceneManager.travel_to(warp_definition.target_scene, warp_definition.target_warp_id, warp_definition.transition)


func _on_body_exited(_body: Node2D) -> void:
	if just_spawned:
		just_spawned = false
	pass # Replace with function body.
