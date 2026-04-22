extends Node

const DIALOGUE_UI_SCENE = preload("res://scenes/ui/DialogueUI.tscn")
var _dialogue_ui: CanvasLayer

var _current_sequence : DialogueSequence
var _current_lines : Array[DialogueLine]
var _current_index : int
var _awaiting_choices : bool = false

func _ready() -> void:
	EventBus.dialogue_choice_selected.connect(choice_selected)
	_dialogue_ui = DIALOGUE_UI_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(_dialogue_ui)

func start_dialogue(dialogue : DialogueSequence):
	if _current_sequence != null:
		return
	_current_sequence = dialogue
	_current_lines = dialogue.lines
	_current_index = 0
	EventBus.dialogue_started.emit(_current_sequence)
	advance_dialogue()

func advance_dialogue():
	if _current_index >= _current_lines.size():
		end_dialogue()
	else:
		var current_line : DialogueLine = _current_lines[_current_index]
		if current_line.choices.is_empty():
			EventBus.dialogue_line_advanced.emit(current_line)
			_current_index += 1
		else:
			if _awaiting_choices == false:
				EventBus.dialogue_line_advanced.emit(current_line)
				_awaiting_choices = true
			else:
				EventBus.dialogue_choices_available.emit(current_line.choices)
				_awaiting_choices = false

func choice_selected(choice : DialogueChoice):
	if choice.sets_flag != "":
		GameState.set_flag(choice.sets_flag, choice.sets_value)
	if choice.next_lines.is_empty():
		if choice.next_sequence_id != "":
			var sequence_path = "res://data/dialogue/%s.tres" % choice.next_sequence_id
			if FileAccess.file_exists(sequence_path):
				var next = load(sequence_path)
				if next is DialogueSequence:
					_current_lines = next.lines
					_current_index = 0
					advance_dialogue()
				else:
					end_dialogue()
			else:
				end_dialogue()
		else:
			end_dialogue()
	else:
		_current_lines = choice.next_lines
		_current_index = 0
		advance_dialogue()

func end_dialogue():
	_current_sequence = null
	_current_lines = []
	_current_index = 0
	_awaiting_choices = false
	EventBus.dialogue_finished.emit()
