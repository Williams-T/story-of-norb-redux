@tool
extends EditorPlugin

var _sprite_importer_dock

func _enter_tree() -> void:
	# Called when the plugin is enabled.
	# Future editors will add their docks and panels here.
	_sprite_importer_dock = preload("res://addons/rpg_editors/sprite_importer/SpriteImporterDock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, _sprite_importer_dock)
	
	print("RPG Editors: loaded")


func _exit_tree() -> void:
	# Called when the plugin is disabled or the project closes.
	# Everything added in _enter_tree must be removed here.
	remove_control_from_docks(_sprite_importer_dock)
	_sprite_importer_dock.free()
	
	print("RPG Editors: unloaded")
