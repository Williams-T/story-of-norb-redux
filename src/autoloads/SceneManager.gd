extends Node

var _is_transitioning: bool = false


func travel_to(scene_path: String, warp_id : String = "", transition: String = "fade") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	EventBus.scene_transition_requested.emit(scene_path, transition)
	# Transition animation plays, then calls _do_scene_change()
	# For now, skip the animation and swap directly
	GameState.pending_warp_id = warp_id
	_do_scene_change(scene_path)


func _do_scene_change(scene_path: String) -> void:
	get_tree().call_deferred('change_scene_to_file',scene_path)
	_is_transitioning = false
	EventBus.scene_transition_finished.emit()


func start_combat(enemy_group: Resource) -> void:
	# Store the return scene so we can come back after combat
	GameState.current_map_path = get_tree().current_scene.scene_file_path
	EventBus.combat_started.emit(enemy_group)
	travel_to("res://scenes/battle/Battle.tscn", "", "flash")


func end_combat(result: String) -> void:
	EventBus.combat_ended.emit(result)
	travel_to(GameState.current_map_path, "", "fade")
