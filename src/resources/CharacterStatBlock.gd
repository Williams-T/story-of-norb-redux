class_name CharacterStatBlock
extends Resource

@warning_ignore_start("shadowed_global_identifier")

@export var character_name: String = ""
@export var level: int = 1
@export var base_move_speed: float = 150.0

@export_group("Primary Stats")
@export var str: int = 10   # Physical attack, carry weight
@export var agi: int = 10   # Turn order, evasion, accuracy
@export var vit: int = 10   # Max HP, physical defense
@export var intelligence: int = 10  # Magic attack, item effectiveness
@export var wil: int = 10   # Max MP, magic resist, status resist

@export_group("Runtime State")
@export var current_hp : int = -1
@export var current_mp : int = -1

func max_hp() -> int:
	return 20 + (vit * 8) + (level * 5)
func max_mp() -> int:
	return 10 + (wil * 5) + (level * 3)
