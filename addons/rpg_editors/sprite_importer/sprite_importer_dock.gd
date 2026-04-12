@tool
extends PanelContainer

@onready var folder_path := $VBoxContainer/FolderPath
@onready var browse_button := $VBoxContainer/BrowseButton
@onready var import_button := $VBoxContainer/ImportButton
@onready var status_label := $VBoxContainer/StatusLabel
@onready var animation_selector := $VBoxContainer/AnimationSelector
@onready var frame_display := $VBoxContainer/FrameDisplay
@onready var prev_button := $VBoxContainer/HBoxContainer/PrevButton
@onready var frame_counter := $VBoxContainer/HBoxContainer/FrameCounter
@onready var next_button := $VBoxContainer/HBoxContainer/NextButton
@onready var play_button := $VBoxContainer/PlayButton
@onready var play_timer := $Timer
var browse_dialog : EditorFileDialog

const DEFAULT_FPS = 4.0

var current_animation = ""
var current_frame_index = -1
var playing = false
var _loaded_sprite_frames: SpriteFrames = null

func _ready() -> void:
	browse_dialog = EditorFileDialog.new()
	browse_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	browse_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	add_child(browse_dialog)
	browse_dialog.dir_selected.connect(_on_browse_dialog_dir_selected)
	play_timer.timeout.connect(_on_play_timer_timeout)
	play_timer.one_shot = false
	prev_button.disabled = true
	next_button.disabled = true
	play_button.disabled = true


# --- Importer ---

func _on_browse_button_pressed() -> void:
	browse_dialog.popup_file_dialog()


func _on_browse_dialog_dir_selected(dir: String) -> void:
	folder_path.text = dir


func _on_import_button_pressed() -> void:
	var path : String = folder_path.text
	if path == "":
		status_label.text = "No folder selected"
		return
	elif DirAccess.get_directories_at(path).size() == 0:
		status_label.text = "No subfolders in directory"
	else:
		_build_sprite_frames(path)
		if _loaded_sprite_frames != null:
			animation_selector.clear()
			for anim in _loaded_sprite_frames.get_animation_names():
				animation_selector.add_item(anim)
			current_animation = _loaded_sprite_frames.get_animation_names()[0]
			current_frame_index = 0
			_update_frame_display()


func _build_sprite_frames(character_folder: String) -> void:
	var folder_name = character_folder.split("/")[-1]
	var folders : PackedStringArray = DirAccess.get_directories_at(character_folder)
	var sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")
	#print(character_folder)
	#print(folders)
	for folder in folders:
		var subdir = "%s/%s"%[character_folder, folder]
		sprite_frames.add_animation(folder)
		sprite_frames.set_animation_speed(folder, DEFAULT_FPS)
		sprite_frames.set_animation_loop(folder, true)
		var files : PackedStringArray = DirAccess.get_files_at(subdir)
		for file in files:
			if file.get_extension() == "png":
				var texture = load("%s/%s" % [subdir, file])
				sprite_frames.add_frame(folder, texture)
	var resource_path = "%s/%s.tres" % [character_folder, folder_name]
	if sprite_frames.get_animation_names().size() == 0:
		status_label.text = "Something went wrong, check directories."
		return
	ResourceSaver.save(sprite_frames, resource_path)
	EditorInterface.get_resource_filesystem().scan()
	_loaded_sprite_frames = sprite_frames
	prev_button.disabled = false
	next_button.disabled = false
	play_button.disabled = false
	status_label.text = "%s imported successfully" % folder_name

# --- Preview ---

func _on_animation_selector_item_selected(index: int) -> void:
	current_animation = _loaded_sprite_frames.get_animation_names()[index]
	current_frame_index = 0
	_update_frame_display()


func _on_prev_button_pressed() -> void:
	if playing:
		_on_play_button_pressed()
	current_frame_index = wrapi(current_frame_index - 1, 0, _loaded_sprite_frames.get_frame_count(current_animation))
	_update_frame_display()

func _on_next_button_pressed() -> void:
	if playing:
		_on_play_button_pressed()
	current_frame_index = wrapi(current_frame_index + 1, 0, _loaded_sprite_frames.get_frame_count(current_animation))
	_update_frame_display()

func _on_play_button_pressed() -> void:
	if !playing:
		play_timer.start(1.0 / DEFAULT_FPS)
		playing = true
		play_button.text = "Stop"
	else:
		play_timer.stop()
		playing = false
		play_button.text = "Play"


func _on_play_timer_timeout() -> void:
	current_frame_index = wrapi(current_frame_index + 1, 0, _loaded_sprite_frames.get_frame_count(current_animation))
	_update_frame_display()


func _update_frame_display() -> void:
	frame_display.texture = _loaded_sprite_frames.get_frame_texture(current_animation, current_frame_index)
	frame_counter.text = "%s / %s" % [current_frame_index + 1, _loaded_sprite_frames.get_frame_count(current_animation)]
