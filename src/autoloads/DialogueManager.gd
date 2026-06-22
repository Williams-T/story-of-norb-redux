extends Node

const DIALOGUE_UI_SCENE = preload("res://scenes/ui/DialogueUI.tscn")
var _dialogue_ui: CanvasLayer

var _current_sequence : DialogueSequence
var _current_lines : Array[DialogueLine]
var _current_index : int
var _awaiting_choices : bool = false

var parse_dict

func _ready() -> void:
	parse_dict = {
	"SceneManager" : get_node("/root/SceneManager"),
	"GameState" : get_node("/root/GameState"),
	"ShopManager" : get_node("/root/ShopManager"),
}
	EventBus.dialogue_choice_selected.connect(choice_selected)
	EventBus.advance_dialogue_requested.connect(advance_dialogue)
	_dialogue_ui = DIALOGUE_UI_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(_dialogue_ui)

func start_dialogue(dialogue : DialogueSequence):
	if _current_sequence != null:
		return
	EventBus.player_movement_locked.emit()
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
		if current_line.function != "":
			if current_line.arguments.is_empty():
				var function : Callable = parse_function(current_line.function)
				function.call()
			else:
				var function : Callable = parse_function(current_line.function)
				function.callv(parse_arguments(current_line.arguments))
			end_dialogue()
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
	EventBus.player_movement_unlocked.emit()
	EventBus.dialogue_finished.emit()

func parse_function(function_string : String):
	var tokens = function_string.split(".")
	var _object
	var _function
	if tokens.size() > 1:
		if tokens[0] in parse_dict.keys():
			_object = parse_dict[tokens[0]]
			_function = Callable(_object, tokens[1])
			print("%s, %s" % [tokens[0], tokens[1]])
	else:
		_function = Callable(tokens[0])
		print(tokens[0])
	if _function:
		return _function

func parse_arguments(arguments_string : String, ):
	var _args = []
	var tokens = arguments_string.replace(" ", "").split(",")
	#print(arguments_string)
	#print(tokens)
	for i : String in tokens:
		var arg
		if i.is_valid_int():
			arg = i.to_int()
		elif i.is_valid_float():
			arg = i.to_float()
		elif i.contains("res://"):
			arg = load(i)
		else:
			arg = i
		_args.append(arg)
	#print(_args)
	return _args
