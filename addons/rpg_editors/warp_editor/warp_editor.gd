@tool
extends PanelContainer

var row = preload("res://addons/rpg_editors/warp_editor/warp_editor_row.tscn")
@onready var warp_container = $VBoxContainer/WarpContainer
@onready var error_label = $VBoxContainer/WarpContainer/ErrorLabel
# Called when the node enters the scene tree for the first time.
func refresh(scene_root : Node):
	for i in warp_container.get_children():
		if i.name != 'ErrorLabel':
			warp_container.remove_child(i)
			i.queue_free()
	if scene_root.has_node('Warps') and scene_root.get_node('Warps').get_child_count() > 0:
		error_label.hide()
		for warp in scene_root.get_node('Warps').get_children():
			if warp is WarpPoint:
				var new_row = row.instantiate()
				warp_container.add_child(new_row)
				new_row.warp_point = warp
				new_row.warp_id_field.text = warp.warp_id
				new_row.target_scene_field.text = warp.warp_definition.target_scene
				new_row.target_warp_id_field.text = warp.warp_definition.target_warp_id
				#new_row.field_changed.connect(_on_field_changed)
	else:
		error_label.show()
#func _on_field_changed(warp, field: String, value: String):
	
	
