class_name DialogueLine
extends Resource

@export var speaker_name: String = ""
@export var portrait: Texture2D  # null = no portrait shown
@export var text: String = ""

# Empty array = linear advance. Populated = show choice menu.
@export var choices: Array[DialogueChoice] = []
