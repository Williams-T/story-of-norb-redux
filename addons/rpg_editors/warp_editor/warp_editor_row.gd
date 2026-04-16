@tool
extends PanelContainer
class_name WarpRow

#signal field_changed(warp, field: String, value: String)

var warp_point : WarpPoint
@onready var warp_id_field := $VFlowContainer/WarpIdEdit
@onready var target_scene_field := $VFlowContainer/TargetSceneEdit
@onready var target_warp_id_field := $VFlowContainer/TargetWarpIdEdit

func _on_warp_id_edit_text_set() -> void:
	if warp_point:
		#field_changed.emit(warp_point, 'warp_id', warp_id_field.text)
		warp_point.warp_id = warp_id_field.text


func _on_target_scene_edit_text_set() -> void:
	if warp_point:
		#field_changed.emit(warp_point, 'target_scene', target_scene_field.text)
		warp_point.warp_definition.target_scene = target_scene_field.text


func _on_target_warp_id_edit_text_set() -> void:
	if warp_point:
		#field_changed.emit(warp_point, 'target_warp_id', target_warp_id_field.text)
		warp_point.warp_definition.target_warp_id = target_warp_id_field.text


func _on_mouse_entered() -> void:
	var interface = EditorInterface
	var selection = interface.get_selection()
	selection.clear()
	selection.add_node(warp_point)
