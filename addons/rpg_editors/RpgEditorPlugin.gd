@tool
extends EditorPlugin

var _sprite_importer_dock
var _warp_editor_dock
var _dialogue_panel
func _enter_tree() -> void:
	scene_changed.connect(_on_scene_changed)
	# Called when the plugin is enabled.
	# Future editors will add their docks and panels here.
	_sprite_importer_dock = preload("res://addons/rpg_editors/sprite_importer/SpriteImporterDock.tscn").instantiate()
	_warp_editor_dock = preload("res://addons/rpg_editors/warp_editor/warp_editor.tscn").instantiate()
	_dialogue_panel =  preload("res://addons/rpg_editors/dialogue_editor/dialogue_editor_panel.tscn").instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, _sprite_importer_dock)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, _warp_editor_dock)
	add_control_to_bottom_panel(_dialogue_panel, "Dialogue Editor")
	_dialogue_panel.plugin = self
	
	print("RPG Editors: loaded")

func _exit_tree() -> void:
	# Called when the plugin is disabled or the project closes.
	# Everything added in _enter_tree must be removed here.
	remove_control_from_bottom_panel(_sprite_importer_dock)
	remove_control_from_bottom_panel(_warp_editor_dock)
	remove_control_from_bottom_panel(_dialogue_panel)
	_dialogue_panel.queue_free()
	_sprite_importer_dock.queue_free()
	_warp_editor_dock.queue_free()
	
	print("RPG Editors: unloaded")

func _handles(object: Object) -> bool:
	if object is DialogueSequence or WarpPoint:
		return true
	return false

func _edit(object: Object) -> void:
	if object is DialogueSequence:
		_dialogue_panel.refresh(object)

func save_dialogue(sequence : DialogueSequence):
	var path = sequence.resource_path
	if path.is_empty():
		path = "res://data/dialogue/%s.tres" % sequence.sequence_id
	ResourceSaver.save(sequence, path)

func _on_scene_changed(root):
	_warp_editor_dock.refresh(root)
