@tool
extends EditorPlugin

var _sprite_importer_dock
var _warp_editor_dock

func _enter_tree() -> void:
	scene_changed.connect(_on_scene_changed)
	# Called when the plugin is enabled.
	# Future editors will add their docks and panels here.
	_sprite_importer_dock = preload("res://addons/rpg_editors/sprite_importer/SpriteImporterDock.tscn").instantiate()
	_warp_editor_dock = preload("res://addons/rpg_editors/warp_editor/warp_editor.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_BOTTOM, _sprite_importer_dock)
	add_control_to_dock(DOCK_SLOT_BOTTOM, _warp_editor_dock)
	
	print("RPG Editors: loaded")


func _exit_tree() -> void:
	# Called when the plugin is disabled or the project closes.
	# Everything added in _enter_tree must be removed here.
	remove_control_from_docks(_sprite_importer_dock)
	remove_control_from_docks(_warp_editor_dock)
	_sprite_importer_dock.free()
	_warp_editor_dock.free()
	
	print("RPG Editors: unloaded")

func _on_scene_changed(root):
	_warp_editor_dock.refresh(root)
