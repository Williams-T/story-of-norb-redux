@tool
extends EditorPlugin

var _sprite_importer_dock
var _warp_editor_dock
var _dialogue_panel
var _combat_editor_dock
var _item_editor_dock
var _shop_editor_dock
var _dungeon_resource_dock
func _enter_tree() -> void:
	scene_changed.connect(_on_scene_changed)
	# Called when the plugin is enabled.
	# Future editors will add their docks and panels here.
	_sprite_importer_dock = preload("res://addons/rpg_editors/sprite_importer/SpriteImporterDock.tscn").instantiate()
	_warp_editor_dock = preload("res://addons/rpg_editors/warp_editor/warp_editor.tscn").instantiate()
	_dialogue_panel =  preload("res://addons/rpg_editors/dialogue_editor/dialogue_editor_panel.tscn").instantiate()
	_combat_editor_dock = preload("res://addons/rpg_editors/combat_editor/combat_editor.tscn").instantiate()
	_item_editor_dock = preload("res://addons/rpg_editors/item_editor/item_editor.tscn").instantiate()
	_shop_editor_dock = preload("res://addons/rpg_editors/shop_editor/shop_editor.tscn").instantiate()
	_dungeon_resource_dock = preload("res://addons/rpg_editors/dungeon_resource_editor/DungeonResourceEditor.tscn").instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, _sprite_importer_dock)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, _warp_editor_dock)
	add_control_to_bottom_panel(_dialogue_panel, "Dialogue Editor")
	add_control_to_bottom_panel(_combat_editor_dock, "Combat Editor")
	add_control_to_bottom_panel(_item_editor_dock, "Item Editor")
	add_control_to_bottom_panel(_shop_editor_dock, "Shop Editor")
	add_control_to_bottom_panel(_dungeon_resource_dock, "Dungeon Resource Editor")
	_dialogue_panel.plugin = self
	
	print("RPG Editors: loaded")

func _exit_tree() -> void:
	# Called when the plugin is disabled or the project closes.
	# Everything added in _enter_tree must be removed here.
	remove_control_from_docks(_sprite_importer_dock)
	remove_control_from_docks(_warp_editor_dock)
	remove_control_from_bottom_panel(_dialogue_panel)
	remove_control_from_bottom_panel(_combat_editor_dock)
	remove_control_from_bottom_panel(_item_editor_dock)
	remove_control_from_bottom_panel(_shop_editor_dock)
	remove_control_from_bottom_panel(_dungeon_resource_dock)
	_dialogue_panel.queue_free()
	_sprite_importer_dock.queue_free()
	_warp_editor_dock.queue_free()
	_combat_editor_dock.queue_free()
	_item_editor_dock.queue_free()
	_shop_editor_dock.queue_free()
	_dungeon_resource_dock.queue_free()
	print("RPG Editors: unloaded")

func _handles(object: Object) -> bool:
	if object is DialogueSequence or object is WarpPoint:
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
