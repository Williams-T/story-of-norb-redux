extends CanvasLayer

@onready var panel := $Panel
@onready var portrait := $Panel/HBoxContainer/Portrait
@onready var line_container := $Panel/HBoxContainer/LineContainer
@onready var name_label := $Panel/HBoxContainer/LineContainer/Name
@onready var dialogue_label := $Panel/HBoxContainer/LineContainer/Dialogue
@onready var choice_scroller := $Panel/HBoxContainer/ScrollContainer
@onready var choice_container := $Panel/HBoxContainer/ScrollContainer/ChoiceContainer

func _ready() -> void:
	EventBus.dialogue_started.connect(start_dialogue)
	EventBus.dialogue_line_advanced.connect(line_advanced)
	EventBus.dialogue_choices_available.connect(choice_display)
	EventBus.dialogue_finished.connect(end_dialogue)


func start_dialogue(sequence : DialogueSequence):
	if !panel.visible:
		panel.show()

func line_advanced(line : DialogueLine):
	if !line_container.visible:
		line_container.show()
	if choice_scroller.visible:
		choice_scroller.hide()
	dialogue_label.text = line.text
	name_label.text = line.speaker_name
	if !line.portrait:
		portrait.hide()
	else:
		portrait.show()
		portrait.texture = line.portrait

func choice_display(choices : Array[DialogueChoice]):
	if !choice_scroller.visible:
		choice_scroller.show()
	if line_container.visible:
		line_container.hide()
	for child in choice_container.get_children():
		choice_container.remove_child(child)
		child.queue_free()
	for choice in choices:
		if choice.flag_required != "":
			if GameState.get_flag(choice.flag_required) != choice.required_value:
				continue
		var choice_button = Button.new()
		choice_container.add_child(choice_button)
		choice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		choice_button.text = choice.label
		choice_button.pressed.connect(choice_selected.bind(choice))

func end_dialogue():
	panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if panel.visible and line_container.visible:
		if event.is_action_pressed("interact"):
			DialogueManager.advance_dialogue()
			get_viewport().set_input_as_handled()

func choice_selected(choice : DialogueChoice):
	DialogueManager.choice_selected(choice)
