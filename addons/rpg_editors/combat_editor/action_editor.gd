@tool
extends PanelContainer

var current_action : BattleAction = null
var current_status : StatusEffect = null
var current_path : String = ""

@onready var file_list : VBoxContainer = $HBoxContainer/FileList
@onready var new_button : Button = $HBoxContainer/ActionForm/NewButton
@onready var save_button : Button = $HBoxContainer/ActionForm/SaveButton
@onready var name_label : Label = $HBoxContainer/ActionForm/ActionNameLabel
@onready var name_field : LineEdit = $HBoxContainer/ActionForm/ActionNameField
@onready var description_label : Label = $HBoxContainer/ActionForm/DescriptionLabel
@onready var description_field : LineEdit = $HBoxContainer/ActionForm/DescriptionField
@onready var category_label : Label = $HBoxContainer/ActionForm/CategoryLabel
@onready var category_options : OptionButton = $HBoxContainer/ActionForm/CategoryOptions
@onready var damage_type_label : Label = $HBoxContainer/ActionForm/DamageTypeLabel
@onready var damage_type_options : OptionButton = $HBoxContainer/ActionForm/DamageTypeOptions
@onready var target_type_label : Label = $HBoxContainer/ActionForm/TargetTypeLabel
@onready var target_type_options : OptionButton = $HBoxContainer/ActionForm/TargetTypeOptions
@onready var power_label : Label = $HBoxContainer/ActionForm/PowerLabel
@onready var power_spin_box : SpinBox = $HBoxContainer/ActionForm/PowerSpinBox
@onready var mp_cost_label : Label = $HBoxContainer/ActionForm/MPCostLabel
@onready var mp_cost_spin_box : SpinBox = $HBoxContainer/ActionForm/MPSpinBox
@onready var status_chance_label : Label = $HBoxContainer/ActionForm/StatusChanceLabel
@onready var chance_value_label : Label = $HBoxContainer/ActionForm/HBoxContainer2/ChanceValueLabel
@onready var status_chance_slider : HSlider = $HBoxContainer/ActionForm/HBoxContainer2/StatusChanceSlider
@onready var status_to_apply_label : Label = $HBoxContainer/ActionForm/StatusToApplyLabel
@onready var status_field : LineEdit =  $HBoxContainer/ActionForm/HBoxContainer/StatusField
@onready var status_browse_button : Button = $HBoxContainer/ActionForm/HBoxContainer/BrowseButton
@onready var animation_key_label : Label = $HBoxContainer/ActionForm/AnimationKeyLabel
@onready var animation_key_field : LineEdit = $HBoxContainer/ActionForm/AnimationKeyField
var editor_dialog : EditorFileDialog

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	editor_dialog = EditorFileDialog.new()
	editor_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	editor_dialog.access =FileDialog.ACCESS_RESOURCES
	editor_dialog.current_dir = "res://data/statuses/"
	add_child(editor_dialog)
	refresh_file_list()
	category_options.add_item("ATTACK")
	category_options.add_item("MAGIC")
	category_options.add_item("SKILL")
	target_type_options.add_item("SINGLE_ENEMY")
	target_type_options.add_item("ALL_ENEMIES")
	target_type_options.add_item("SINGLE_ALLY")
	target_type_options.add_item("ALL_ALLIES")
	target_type_options.add_item("SELF")
	damage_type_options.add_item("PHYSICAL")
	damage_type_options.add_item("MAGICAL")
	damage_type_options.add_item("HEALING")
	damage_type_options.add_item("NONE")
	status_browse_button.pressed.connect(func(): editor_dialog.popup_file_dialog())
	editor_dialog.file_selected.connect(func(file : String): current_status = load(file); status_field.text = current_status.status_name)
	status_chance_slider.drag_ended.connect(func(value_changed : bool): chance_value_label.text = "%s" % status_chance_slider.value)
	new_button.pressed.connect(reset_fields)
	save_button.pressed.connect(save_action)
	reset_fields()
	
func refresh_file_list():
	for node : Button in file_list.get_children():
		node.queue_free()
	var files = DirAccess.get_files_at("res://data/actions/")
	for file : String in files:
		var button = Button.new()
		button.flat = true
		button.text = file.get_basename().replace("_", " ")
		file_list.add_child(button)
		button.pressed.connect(populate_fields.bind(button, file))

func populate_fields(button : Button, path):
	current_action = load("res://data/actions/"+path)
	current_path = "res://data/actions/"+path
	for _button : Button in file_list.get_children():
		if _button != button:
			_button.add_theme_color_override("font_color", Color.WHITE)
			_button.add_theme_color_override("font_hover_color", Color.WHITE)
		else:
			_button.add_theme_color_override("font_color", Color.GOLD)
			_button.add_theme_color_override("font_hover_color", Color.GOLD)
	name_field.text = current_action.action_name
	description_field.text = current_action.description
	category_options.select(current_action.category)
	damage_type_options.select(current_action.damage_type)
	target_type_options.select(current_action.target_type)
	power_spin_box.value = current_action.power
	mp_cost_spin_box.value = current_action.mp_cost
	status_chance_slider.value = current_action.status_chance
	status_chance_slider.drag_ended.emit(true)
	if current_action.status_to_apply != null:
		status_field.text = current_action.status_to_apply.status_name
		current_status = current_action.status_to_apply
	else:
		status_field.text = ""
		current_status = null

func reset_fields():
	current_action = BattleAction.new()
	current_path = ""
	name_field.text = ""
	description_field.text = ""
	category_options.select(0)
	damage_type_options.select(0)
	target_type_options.select(0)
	power_spin_box.set_value_no_signal(1.0)
	mp_cost_spin_box.set_value_no_signal(0.0)
	status_chance_slider.set_value_no_signal(0.0)
	chance_value_label.text = "0.0"
	status_field.text = ""
	current_status = null
	animation_key_field.text = ""

func save_action():
	current_action.action_name = name_field.text
	current_action.description = description_field.text
	current_action.category = category_options.selected
	current_action.damage_type = damage_type_options.selected
	current_action.target_type = target_type_options.selected
	current_action.power = power_spin_box.value
	current_action.mp_cost = mp_cost_spin_box.value
	current_action.status_chance = status_chance_slider.value
	if current_status:
		current_action.status_to_apply = current_status
	current_action.animation_key = animation_key_field.text
	if current_path == "":
		if "%s.tres" % name_field.text not in DirAccess.get_files_at("res://data/actions/"):
			current_path = "res://data/actions/%s%s" % [name_field.text, ".tres"]
			ResourceSaver.save(current_action, current_path)
		else:
			current_path = "res://data/actions/%s%s%s" % [name_field.text, randi_range(111,999), ".tres"]
			ResourceSaver.save(current_action, current_path)
	else:
		ResourceSaver.save(current_action, "%s" % current_path)
	refresh_file_list()
