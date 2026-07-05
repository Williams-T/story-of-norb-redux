@tool
class_name DungeonResourceEditor extends PanelContainer

@onready var list : VBoxContainer = $VBoxContainer/HBoxContainer/VBoxContainer/DungeonResourceList
@onready var new_button : Button = $VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/HBoxContainer4/NewButton
@onready var save_button : Button = $VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/HBoxContainer4/SaveButton
@onready var floor_name_edit : LineEdit = $VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/HBoxContainer/FloorNameEdit
@onready var encounter_rate_spinbox : SpinBox = $VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/EncounterRateSpinbox
@onready var encounter_music_edit : LineEdit = $VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/HBoxContainer3/EncounterMusicEdit
@onready var encounter_music_browse : Button = $VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/HBoxContainer3/MusicBrowse
@onready var encounter_browse : Button = $VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/HBoxContainer2/EncounterBrowse
@onready var encounters_container : VBoxContainer = $VBoxContainer/HBoxContainer/ScrollContainer/EncountersContainer

var current_dungeon_resource : DungeonResource
var dungeon_directory = "res://data/dungeons/"
var current_path = ""
var music_dialog : EditorFileDialog
var encounter_dialog : EditorFileDialog

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_button.pressed.connect(clear_details)
	save_button.pressed.connect(save_resource)
	music_dialog = EditorFileDialog.new()
	music_dialog.current_dir = "res://audio/music/"
	music_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	add_child(music_dialog)
	encounter_dialog = EditorFileDialog.new()
	encounter_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	encounter_dialog.current_dir = "res://data/enemy_groups/"
	add_child(encounter_dialog)
	encounter_music_browse.pressed.connect(music_dialog.popup)
	encounter_browse.pressed.connect(encounter_dialog.popup)
	music_dialog.file_selected.connect(func(file): encounter_music_edit.text = file)
	encounter_dialog.file_selected.connect(func(file): add_encounter(file))
	scan_files()
	clear_details()

func scan_files():
	for i in list.get_children():
		i.queue_free()
	for file in DirAccess.get_files_at(dungeon_directory):
		var loaded = load("%s%s" % [dungeon_directory, file])
		if loaded is DungeonResource:
			var button := Button.new()
			button.text = file.trim_suffix(".tres").replace("_", " ")
			button.pressed.connect(load_details.bind(loaded))
			list.add_child(button)

func load_details(dungeon : DungeonResource):
	current_path = dungeon.resource_path
	current_dungeon_resource = dungeon.duplicate(true)
	floor_name_edit.text = current_dungeon_resource.floor_name.replace("_", " ")
	encounter_rate_spinbox.value = current_dungeon_resource.encounter_rate
	encounter_music_edit.text = current_dungeon_resource.encounter_music
	refresh_encounters(current_dungeon_resource)

func refresh_encounters(dungeon : DungeonResource):
	for node in encounters_container.get_children():
		node.queue_free()
	for i in dungeon.encounter_groups.size():
		var hbox := HBoxContainer.new()
		var group_name := LineEdit.new()
		var current_group : EnemyGroupResource = dungeon.encounter_groups[i]
		group_name.text = current_group.resource_path.replace("res://data/enemy_groups/", "")
		group_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group_name.editable = false
		var weight_spin := SpinBox.new()
		weight_spin.min_value = 0.0
		weight_spin.max_value = 1.0
		weight_spin.step = 0.01
		weight_spin.value = dungeon.encounter_weights[i]
		weight_spin.value_changed.connect(func(value): dungeon.encounter_weights[i] = value)
		var delete_button := Button.new()
		delete_button.text = "x"
		delete_button.pressed.connect(delete_encounter.bind(i))
		hbox.add_child(group_name)
		hbox.add_child(weight_spin)
		hbox.add_child(delete_button)
		hbox.name = "hbox%s"%i
		encounters_container.add_child(hbox)

func add_encounter(group_path : String, group_weight : float = 0.5):
	current_dungeon_resource.encounter_groups.append(load(group_path))
	current_dungeon_resource.encounter_weights.append(group_weight)
	refresh_encounters(current_dungeon_resource)

func delete_encounter(index):
	current_dungeon_resource.encounter_groups.remove_at(index)
	current_dungeon_resource.encounter_weights.remove_at(index)
	refresh_encounters(current_dungeon_resource)

func clear_details():
	current_path = ""
	current_dungeon_resource = DungeonResource.new()
	floor_name_edit.clear()
	floor_name_edit.placeholder_text = ""
	encounter_rate_spinbox.value = 0.0
	encounter_music_edit.clear()
	for i in encounters_container.get_children():
		i.queue_free()

func save_resource():
	if floor_name_edit.text == "":
		floor_name_edit.placeholder_text = "Floor name needed"
		floor_name_edit.add_theme_color_override("font_placeholder_color", Color.INDIAN_RED)
		return
	current_dungeon_resource.floor_name = floor_name_edit.text.replace(" ", "_")
	current_dungeon_resource.encounter_rate = encounter_rate_spinbox.value
	current_dungeon_resource.encounter_music = encounter_music_edit.text
	if current_path == "":
		current_path = "res://data/dungeons/%s.tres" % current_dungeon_resource.floor_name
	ResourceSaver.save(current_dungeon_resource, current_path)
	scan_files()
