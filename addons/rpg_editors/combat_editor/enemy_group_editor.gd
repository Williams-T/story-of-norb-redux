@tool
extends PanelContainer

var current_enemy_group : EnemyGroupResource
var pending_enemies : Array[EnemyResource] = []
var encounter_music_path : String = ""
var current_path : String = ""

@onready var file_list : VBoxContainer = $HBoxContainer/FileList
@onready var new_button : Button =$HBoxContainer/GridContainer/NewButton
@onready var save_button : Button =$HBoxContainer/GridContainer/SaveButton
@onready var music_field : LineEdit =$HBoxContainer/GridContainer/HBoxContainer/LineEdit
@onready var music_button : Button =$HBoxContainer/GridContainer/HBoxContainer/Button
@onready var add_enemy_button : Button =$HBoxContainer/GridContainer/HBoxContainer2/Button
@onready var remove_enemy_button : Button =$HBoxContainer/GridContainer/HBoxContainer2/Button2
@onready var enemy_list : ItemList =$HBoxContainer/GridContainer/ItemList
var music_dialog : EditorFileDialog
var enemy_dialog : EditorFileDialog

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_dialog = EditorFileDialog.new()
	music_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	music_dialog.access =FileDialog.ACCESS_RESOURCES
	music_dialog.current_dir = "res://audio/music/"
	enemy_dialog = EditorFileDialog.new()
	enemy_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	enemy_dialog.access =FileDialog.ACCESS_RESOURCES
	enemy_dialog.current_dir = "res://data/enemies/"
	add_child(music_dialog)
	add_child(enemy_dialog)
	new_button.pressed.connect(reset_form)
	save_button.pressed.connect(save_group)
	music_button.pressed.connect(music_dialog.popup)
	music_dialog.file_selected.connect(func(file_path): encounter_music_path = file_path; music_field.text = file_path)
	add_enemy_button.pressed.connect(enemy_dialog.popup)
	enemy_dialog.file_selected.connect(add_enemy)
	remove_enemy_button.pressed.connect(func(): if enemy_list.is_anything_selected(): var idx = enemy_list.get_selected_items()[0]; enemy_list.remove_item(idx); pending_enemies.remove_at(idx))
	refresh_file_list()
	reset_form()

func populate_fields(group : EnemyGroupResource):
	reset_form()
	current_enemy_group = group
	current_path = group.resource_path
	encounter_music_path = group.encounter_music
	music_field.text = encounter_music_path
	pending_enemies = group.enemies.duplicate()
	if pending_enemies.size() > 0:
		for enemy : EnemyResource in pending_enemies:
			enemy_list.add_item(enemy.enemy_name)

func reset_form():
	current_enemy_group = EnemyGroupResource.new()
	pending_enemies.clear()
	encounter_music_path = ""
	current_path = ""
	music_field.text = ""
	enemy_list.clear()

func add_enemy(file_path):
	var enemy : EnemyResource = load(file_path)
	if enemy is EnemyResource:
		enemy_list.add_item(enemy.enemy_name)
		pending_enemies.append(enemy)

func save_group():
	var group_name := ""
	if !pending_enemies.is_empty():
		for enemy : EnemyResource in pending_enemies:
			group_name += "_%s" % enemy.enemy_name
		group_name = group_name.replace(" ", "")
		if group_name[0] == "_":
			group_name = group_name.erase(0, 1)
	else:
		group_name = "empty_group%s" % randi_range(111,999)
	group_name += ".tres"
	current_path = "res://data/enemy_groups/%s" % group_name
	current_enemy_group.encounter_music = encounter_music_path
	current_enemy_group.enemies = pending_enemies.duplicate()
	ResourceSaver.save(current_enemy_group, current_path)
	refresh_file_list()

func refresh_file_list():
	for child in file_list.get_children():
		file_list.remove_child(child)
		child.queue_free()
	var files = DirAccess.get_files_at("res://data/enemy_groups/")
	for file : String in files:
		var loaded = load("res://data/enemy_groups/%s" % file)
		if loaded is EnemyGroupResource:
			var button = Button.new()
			button.flat = true
			button.text = file.get_basename().replace("_", " ")
			file_list.add_child(button)
			button.pressed.connect(populate_fields.bind(loaded))
