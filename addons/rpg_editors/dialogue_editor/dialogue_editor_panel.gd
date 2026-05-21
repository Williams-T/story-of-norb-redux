@tool
extends PanelContainer

@onready var sequence_name_label := $VBoxContainer/FileBar/SequenceNameLabel
@onready var new_button := $VBoxContainer/FileBar/NewButton
@onready var save_button := $VBoxContainer/FileBar/SaveButton
@onready var line_container := $VBoxContainer/MainContent/LineList/ScrollContainer/LineContainer
@onready var speaker_edit := $VBoxContainer/MainContent/LineDetail/MarginContainer/VBoxContainer/HBoxContainer/SpeakerEdit
@onready var text_edit := $VBoxContainer/MainContent/LineDetail/MarginContainer/VBoxContainer/HBoxContainer2/TextEdit
@onready var portrait_button := $VBoxContainer/MainContent/LineDetail/MarginContainer/VBoxContainer/HBoxContainer3/PortraitButton
@onready var choices_container := $VBoxContainer/MainContent/LineDetail/MarginContainer/VBoxContainer/HBoxContainer4/ChoicesContainer
@onready var add_choice_button := $VBoxContainer/MainContent/LineDetail/MarginContainer/VBoxContainer/HBoxContainer4/ChoicesContainer/AddChoiceButton
@onready var add_line_button := $VBoxContainer/MainContent/LineList/ScrollContainer/LineContainer/AddLineButton

# Choice Details
@onready var required_flag_field := $VBoxContainer/MainContent/LineDetail/MarginContainer/VBoxContainer/HBoxContainer4/ChoiceAdvanced/FlagRequiredField
@onready var required_value_field := $VBoxContainer/MainContent/LineDetail/MarginContainer/VBoxContainer/HBoxContainer4/ChoiceAdvanced/ValueRequiredField
@onready var sets_flag_field := $VBoxContainer/MainContent/LineDetail/MarginContainer/VBoxContainer/HBoxContainer4/ChoiceAdvanced/SetsFlagField
@onready var sets_value_field := $VBoxContainer/MainContent/LineDetail/MarginContainer/VBoxContainer/HBoxContainer4/ChoiceAdvanced/SetsValueField
@onready var next_sequence_id_field := $VBoxContainer/MainContent/LineDetail/MarginContainer/VBoxContainer/HBoxContainer4/ChoiceAdvanced/NextSequenceID

var current_sequence : DialogueSequence
var current_choice_index : int = -1
var selected_choice_node : LineEdit
var plugin : EditorPlugin
var _portrait_dialog : EditorFileDialog
var _confirmation_dialog : ConfirmationDialog
var sequence_edit : LineEdit

func _enter_tree() -> void:
	_portrait_dialog = EditorFileDialog.new()
	_portrait_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_portrait_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_portrait_dialog.add_filter("*.png,*.jpg,*.webp", "Images")
	add_child(_portrait_dialog)
	_confirmation_dialog = ConfirmationDialog.new()
	_confirmation_dialog.dialog_text = "Input Sequence ID:"
	add_child(_confirmation_dialog)
	sequence_edit = LineEdit.new()
	sequence_edit.placeholder_text = "Sequence ID"
	_confirmation_dialog.add_child(sequence_edit)
	_confirmation_dialog.confirmed.connect(save_dialogue)
	#portrait_button.pressed.connect(change_portrait)
	#add_choice_button.pressed.connect(add_choice)

func _ready() -> void:
	new_button.pressed.connect(new_dialogue)
	save_button.pressed.connect(save_prompt)
	add_line_button.pressed.connect(add_line)
	sequence_name_label.text_changed.connect(update_sequence_id)
	new_dialogue()

func refresh(sequence : DialogueSequence):
	clear_details()
	current_sequence = sequence
	sequence_name_label.text = current_sequence.sequence_id
	for child in line_container.get_children():
		if child.name != "AddLineButton":
			line_container.remove_child(child)
			child.queue_free()
	if !sequence.lines.is_empty():
		for i in sequence.lines.size():
			var current_line : DialogueLine = current_sequence.lines[i]
			var hbox = HBoxContainer.new()
			var button = Button.new()
			var delete_button = Button.new()
			button.text = current_line.text
			button.pressed.connect(refresh_detail.bind(i))
			delete_button.pressed.connect(delete_line.bind(i))
			delete_button.text = "x"
			line_container.add_child(hbox)
			hbox.add_child(button)
			hbox.add_child(delete_button)
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size = Vector2(0.0, 31.0)
		line_container.move_child(add_line_button, -1)

func update_sequence_id(text : String):
	current_sequence.sequence_id = text

func add_line():
	if !current_sequence:
		current_sequence = DialogueSequence.new()
	var lines = current_sequence.lines.duplicate()
	lines.append(DialogueLine.new())
	current_sequence.lines = lines
	refresh(current_sequence)

func delete_line(index : int):
	var lines = current_sequence.lines.duplicate()
	lines.remove_at(index)
	current_sequence.lines = lines
	refresh(current_sequence)

func refresh_detail(index : int):
	clear_details()
	var line : DialogueLine = current_sequence.lines[index]
	speaker_edit.text = line.speaker_name
	if speaker_edit.text_changed.is_connected(change_speaker):
		speaker_edit.text_changed.disconnect(change_speaker)
	speaker_edit.text_changed.connect(change_speaker.bind(index))
	text_edit.text = line.text
	if text_edit.text_changed.is_connected(text_changed):
		text_edit.text_changed.disconnect(text_changed)
	text_edit.text_changed.connect(text_changed.bind(index))
	if line.portrait != null:
		portrait_button.texture_normal = line.portrait
	else:
		portrait_button.texture_normal = preload("res://art/NULL.png")
	if portrait_button.pressed.is_connected(change_portrait):
		portrait_button.pressed.disconnect(change_portrait)
	portrait_button.pressed.connect(change_portrait.bind(index))
	for child in choices_container.get_children():
		if child.name != "AddChoiceButton":
			choices_container.remove_child(child)
			child.queue_free()
	if !line.choices.is_empty():
		for choice_index in line.choices.size():
			var choice : DialogueChoice = line.choices[choice_index]
			var choice_field = LineEdit.new()
			var delete_button = Button.new()
			var hbox = HBoxContainer.new()
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			choice_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			delete_button.pressed.connect(delete_choice.bind(index, choice_index))
			choice_field.text = choice.label
			delete_button.text = "[ x ]"
			choice_field.text_changed.connect(text_changed.bind(index, choice_index))
			choice_field.editing_toggled.connect(choice_selected.bind(index, choice_index, choice_field))
			choices_container.add_child(hbox)
			hbox.add_child(choice_field)
			hbox.add_child(delete_button)
		choices_container.move_child(add_choice_button, -1)
	if add_choice_button.pressed.is_connected(add_choice):
		add_choice_button.pressed.disconnect(add_choice)
	add_choice_button.pressed.connect(add_choice.bind(index))

func new_dialogue():
	current_sequence = DialogueSequence.new()
	refresh(current_sequence)

func save_prompt():
	if !current_sequence:
		return
	if current_sequence.sequence_id == "" or current_sequence.sequence_id == null:
		_confirmation_dialog.popup_centered()
	else:
		save_dialogue()

func save_dialogue():
	if current_sequence.sequence_id == "":
		if sequence_edit.text != "":
			current_sequence.sequence_id = sequence_edit.text
		else:
			current_sequence.sequence_id = "New_Dialogue_%s" % randi_range(1000, 9999)
	plugin.save_dialogue(current_sequence)

func change_portrait(line_index: int) -> void:
	if _portrait_dialog.file_selected.is_connected(_on_portrait_selected):
		_portrait_dialog.file_selected.disconnect(_on_portrait_selected)
	_portrait_dialog.file_selected.connect(_on_portrait_selected.bind(line_index))
	_portrait_dialog.filters = ["*.png"]
	_portrait_dialog.popup_file_dialog()

func _on_portrait_selected(path: String, line_index: int) -> void:
	var texture = load(path)
	current_sequence.lines[line_index].portrait = texture
	portrait_button.texture_normal = texture

func add_choice(line_index : int):
	var choices = current_sequence.lines[line_index].choices.duplicate()
	choices.append(DialogueChoice.new())
	current_sequence.lines[line_index].choices = choices
	refresh_detail(line_index)

func choice_selected(_toggled : bool, line_index : int, choice_index : int, choice_node : Node):
	current_choice_index = choice_index
	if selected_choice_node != null:
		selected_choice_node.remove_theme_color_override("font_color")
	selected_choice_node = choice_node
	selected_choice_node.add_theme_color_override("font_color", Color.YELLOW)
	refresh_choice_details(line_index, choice_index)

func delete_choice(line_index: int, choice_index: int) -> void:
	var choices = current_sequence.lines[line_index].choices.duplicate()
	choices.remove_at(choice_index)
	current_sequence.lines[line_index].choices = choices
	refresh_detail(line_index)

func refresh_choice_details(line_index : int, choice_index : int):
	var current_choice : DialogueChoice = current_sequence.lines[line_index].choices[choice_index]
	if required_flag_field.text_changed.is_connected(update_choice):
		required_flag_field.text_changed.disconnect(update_choice)
	if required_value_field.text_changed.is_connected(update_choice):
		required_value_field.text_changed.disconnect(update_choice)
	if sets_flag_field.text_changed.is_connected(update_choice):
		sets_flag_field.text_changed.disconnect(update_choice)
	if sets_value_field.text_changed.is_connected(update_choice):
		sets_value_field.text_changed.disconnect(update_choice)
	if next_sequence_id_field.text_changed.is_connected(update_choice):
		next_sequence_id_field.text_changed.disconnect(update_choice)
	if current_choice.flag_required != null:
		required_flag_field.text = "%s" % current_choice.flag_required
	if current_choice.required_value != null:
		required_value_field.text = "%s" % current_choice.required_value
	if current_choice.sets_flag != null:
		sets_flag_field.text = "%s" % current_choice.sets_flag
	if current_choice.sets_value != null:
		sets_value_field.text = "%s" % current_choice.sets_value
	if current_choice.next_sequence_id != null:
		next_sequence_id_field.text = "%s" % current_choice.next_sequence_id
	required_flag_field.text_changed.connect(update_choice.bind(line_index, choice_index, "required_flag"))
	required_value_field.text_changed.connect(update_choice.bind(line_index, choice_index, "required_value"))
	sets_flag_field.text_changed.connect(update_choice.bind(line_index, choice_index, "sets_flag"))
	sets_value_field.text_changed.connect(update_choice.bind(line_index, choice_index, "sets_value"))
	next_sequence_id_field.text_changed.connect(update_choice.bind(line_index, choice_index, "next_id"))

func clear_details():
	speaker_edit.text = ""
	text_edit.text = ""
	portrait_button.texture_normal = preload("res://art/NULL.png")
	for child in choices_container.get_children():
		if child.name != "AddChoiceButton":
			choices_container.remove_child(child)
			child.queue_free()
	required_flag_field.text = ""
	required_value_field.text = ""
	sets_flag_field.text = ""
	sets_value_field.text = ""
	next_sequence_id_field.text = ""

func update_choice(field_value : String, line_index:int, choice_index: int, field_name : String):
	var current_choice = current_sequence.lines[line_index].choices[choice_index]
	match field_name:
		"required_flag":
			current_choice.flag_required = field_value
		"required_value":
			current_choice.required_value = field_value
		"sets_flag":
			current_choice.sets_flag = field_value
		"sets_value":
			current_choice.sets_value = field_value
		"next_id":
			current_choice.next_sequence_id = field_value

func text_changed(text : String, line_index : int, choice_index : int = -1):
	if choice_index != -1:
		current_sequence.lines[line_index].choices[choice_index].label = text
	else:
		current_sequence.lines[line_index].text = text
		line_container.get_child(line_index).get_child(0).text = text

func change_speaker(text : String, line_index : int):
	current_sequence.lines[line_index].speaker_name = text
