class_name DialogueChoice
extends Resource

@export var label: String = ""  # What the player sees in the menu

# Condition — leave flag_required empty for always-available choices
@export var flag_required: String = ""
@export var required_value: Variant = null

# Consequence
@export var sets_flag: String = ""
@export var sets_value: Variant = null

# Where this choice leads
@export var next_lines: Array[DialogueLine] = []
@export var next_sequence_id : String = ""
