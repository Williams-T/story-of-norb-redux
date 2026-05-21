@tool
extends PanelContainer

var current_enemy : EnemyResource = null
var current_stats : CharacterStatBlock = null
var current_frames : SpriteFrames = null
var current_path = ""

var pending_actions : Array[BattleAction] = []
var pending_items : Array[ItemResource] = []

@onready var file_list : VBoxContainer = $HBoxContainer/FileLlist
@onready var new_button : Button = $HBoxContainer/EnemyForm/NewButton
@onready var save_button : Button = $HBoxContainer/EnemyForm/SaveButton
@onready var enemy_name : LineEdit = $HBoxContainer/EnemyForm/EnemyNameField
@onready var behavior_options : OptionButton = $HBoxContainer/EnemyForm/BehaviorOptions
@onready var frames_field : LineEdit = $HBoxContainer/EnemyForm/HBoxContainer/SpriteFramesField
@onready var browse_frames_button : Button = $HBoxContainer/EnemyForm/HBoxContainer/FramesButton
@onready var str_spin_box : SpinBox = $HBoxContainer/EnemyForm/StatsGrid/StrSpinBox
@onready var agi_spin_box : SpinBox = $HBoxContainer/EnemyForm/StatsGrid/AgiSpinBox
@onready var vit_spin_box : SpinBox = $HBoxContainer/EnemyForm/StatsGrid/VitSpinBox
@onready var int_spin_box : SpinBox = $HBoxContainer/EnemyForm/StatsGrid/IntSpinBox
@onready var wil_spin_box : SpinBox = $HBoxContainer/EnemyForm/StatsGrid/WilSpinBox
@onready var level_spin_box : SpinBox = $HBoxContainer/EnemyForm/LevelSpinBox
@onready var exp_spin_box : SpinBox = $HBoxContainer/EnemyForm/ExpSpinBox
@onready var gold_spin_box : SpinBox = $HBoxContainer/EnemyForm/GoldSpinBox
@onready var action_add_button : Button = $HBoxContainer/EnemyForm/HBoxContainer2/Add
@onready var action_remove_button : Button =$HBoxContainer/EnemyForm/HBoxContainer2/Remove
@onready var drop_table_add_button : Button = $HBoxContainer/EnemyForm/HBoxContainer3/Add
@onready var drop_table_remove_button : Button = $HBoxContainer/EnemyForm/HBoxContainer3/Remove
@onready var action_list : ItemList = $HBoxContainer/EnemyForm/ScrollContainer/ActionsList
@onready var drop_table_list : ItemList = $HBoxContainer/EnemyForm/ScrollContainer2/DropTableList
var frames_dialog : EditorFileDialog
var actions_dialog : EditorFileDialog
var drop_dialog : EditorFileDialog

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refresh_files()
	frames_dialog = EditorFileDialog.new()
	frames_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	frames_dialog.access =FileDialog.ACCESS_RESOURCES
	frames_dialog.current_dir = "res://art/characters/enemies/"
	add_child(frames_dialog)
	actions_dialog = EditorFileDialog.new()
	actions_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	actions_dialog.access =FileDialog.ACCESS_RESOURCES
	actions_dialog.current_dir = "res://data/actions/"
	add_child(actions_dialog)
	drop_dialog = EditorFileDialog.new()
	drop_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	drop_dialog.access =FileDialog.ACCESS_RESOURCES
	drop_dialog.current_dir = "res://data/items/"
	add_child(drop_dialog)
	new_button.pressed.connect(reset_form)
	save_button.pressed.connect(save_form)
	behavior_options.clear()
	behavior_options.add_item("RANDOM")
	behavior_options.add_item("AGGRESSIVE")
	behavior_options.add_item("DEFENSIVE")
	behavior_options.add_item("HEALER")
	behavior_options.add_item("BERSERKER")
	browse_frames_button.pressed.connect(func():frames_dialog.popup())
	action_add_button.pressed.connect(func():actions_dialog.popup())
	action_remove_button.pressed.connect(func():if action_list.is_anything_selected(): 
		var index = action_list.get_selected_items()[0]
		action_list.remove_item(index)
		pending_actions.remove_at(index)
		)
	drop_table_add_button.pressed.connect(func():drop_dialog.popup())
	drop_table_remove_button.pressed.connect(func():if drop_table_list.is_anything_selected():
		var index = drop_table_list.get_selected_items()[0]
		drop_table_list.remove_item(index)
		pending_items.remove_at(index)
		)
	frames_dialog.file_selected.connect(func(file : String): var frames : SpriteFrames = load(file);current_frames = frames;frames_field.text = file)
	actions_dialog.file_selected.connect(func(file : String): var action : BattleAction = load(file);action_list.add_item(action.action_name); pending_actions.append(action))
	drop_dialog.file_selected.connect(func(file : String): var drop : ItemResource = load(file);drop_table_list.add_item(drop.item_name);pending_items.append(drop))

func refresh_files():
	for child in file_list.get_children():
		file_list.remove_child(child)
		child.queue_free()
	var files = DirAccess.get_files_at("res://data/enemies/")
	for file : String in files:
		var loaded = load("res://data/enemies/%s" % file)
		if loaded is EnemyResource:
			var button = Button.new()
			button.flat = true
			button.text = file.get_basename().replace("_", " ")
			file_list.add_child(button)
			button.pressed.connect(populate_fields.bind(loaded))

func populate_fields(enemy : EnemyResource):
	reset_form()
	current_path = enemy.resource_path
	current_enemy = enemy
	if enemy.stats != null:
		current_stats = enemy.stats
	else:
		enemy.stats = CharacterStatBlock.new()
		current_stats = enemy.stats
	if enemy.sprite_frames != null:
		current_frames = enemy.sprite_frames
	else:
		enemy.sprite_frames = SpriteFrames.new()
		current_frames = enemy.sprite_frames
	enemy_name.text = enemy.enemy_name
	behavior_options.select(enemy.behavior)
	frames_field.text = enemy.sprite_frames.resource_path
	str_spin_box.value = current_stats.str
	agi_spin_box.value = current_stats.agi
	vit_spin_box.value = current_stats.vit
	int_spin_box.value = current_stats.intelligence
	wil_spin_box.value = current_stats.wil
	level_spin_box.value = current_stats.level
	exp_spin_box.value = enemy.experience_reward
	gold_spin_box.value = enemy.gold_reward
	for action in enemy.actions:
		action_list.add_item(action.action_name)
		pending_actions.append(action)
	for drop in enemy.drop_table:
		drop_table_list.add_item(drop.item_name)
		pending_items.append(drop)
func reset_form():
	current_enemy = EnemyResource.new()
	current_stats = CharacterStatBlock.new()
	current_frames = SpriteFrames.new()
	current_path = ""
	pending_actions = []
	pending_items = []
	enemy_name.text = ""
	behavior_options.select(0)
	frames_field.text = ""
	str_spin_box.value = 0
	agi_spin_box.value = 0
	vit_spin_box.value = 0
	int_spin_box.value = 0
	wil_spin_box.value = 0
	level_spin_box.value = 1
	exp_spin_box.value = 0
	gold_spin_box.value = 0
	action_list.clear()
	drop_table_list.clear()
func save_form():
	current_enemy.enemy_name = enemy_name.text
	current_enemy.behavior = behavior_options.selected
	current_enemy.sprite_frames = current_frames
	current_enemy.stats = current_stats
	current_enemy.stats.str = str_spin_box.value
	current_enemy.stats.agi = agi_spin_box.value
	current_enemy.stats.vit = vit_spin_box.value
	current_enemy.stats.intelligence = int_spin_box.value
	current_enemy.stats.wil = wil_spin_box.value
	current_enemy.stats.level = level_spin_box.value
	current_enemy.experience_reward = exp_spin_box.value
	current_enemy.gold_reward = gold_spin_box.value
	current_enemy.actions = pending_actions
	current_enemy.drop_table = pending_items
	if current_path == "":
		current_path = "res://data/enemies/%s.tres" % current_enemy.enemy_name
	ResourceSaver.save(current_enemy, current_path)
	refresh_files()
