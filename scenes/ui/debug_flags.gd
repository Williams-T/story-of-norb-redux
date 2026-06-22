extends HBoxContainer
class_name DebugFlag

@onready var flag_container : VBoxContainer = $Container/FlagsContainer
@onready var key_field : LineEdit = $VBoxContainer/KeyLine
@onready var value_field : LineEdit = $VBoxContainer/ValueLine
@onready var add_flag_button : Button = $VBoxContainer/AddFlagButton
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refresh_flags()
	add_flag_button.pressed.connect(new_flag)

func refresh_flags() -> void:
	for child in flag_container.get_children():
		child.queue_free()
	for flag in GameState.flags.keys():
		load_flag(flag, GameState.flags[flag])

func load_flag(key : String, value : Variant):
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = key
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.set_meta("key", key)
	hbox.set_meta("value", value)
	flag_container.add_child(hbox)
	hbox.add_child(label)
	match typeof(value):
		TYPE_STRING:
			var line_edit := LineEdit.new()
			line_edit.text = "%s" % value
			line_edit.text_changed.connect(func(text): GameState.flags[key] = text)
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			#line_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
			hbox.add_child(line_edit)
		TYPE_BOOL:
			var check_box := CheckButton.new()
			check_box.button_pressed = value
			check_box.toggled.connect(func(val): GameState.flags[key] = val)
			check_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			#check_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
			hbox.add_child(check_box)
		TYPE_INT:
			var spin_box := SpinBox.new()
			spin_box.max_value = 999999
			spin_box.min_value = -999999
			spin_box.value = value
			spin_box.changed.connect(func(val): GameState.flags[key] = val)
			spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			#spin_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
			hbox.add_child(spin_box)
	#hbox.add_spacer(false)
	var delete_button := Button.new()
	delete_button.text = " x "
	delete_button.pressed.connect(func(): GameState.flags.erase(key); refresh_flags())
	delete_button.add_theme_color_override("font_color", Color.RED)
	hbox.add_child(delete_button)

func new_flag():
	if key_field.text == "":
		return
	var val
	if value_field.text == "true": 
		val = true
	elif value_field.text == "false":
		val = false
	elif value_field.text.is_valid_int():
		val = (value_field.text as int)
	else:
		val = value_field.text
	GameState.flags[key_field.text] = val
	key_field.clear()
	value_field.clear()
	refresh_flags()
