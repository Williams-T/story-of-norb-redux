class_name CharacterStatBlock
extends Resource

@export var character_name: String = ""
@export var level: int = 1
@export var base_move_speed: float = 150.0

@export_group("Primary Stats")
@export var str: int = 10   # Physical attack, carry weight
@export var agi: int = 10   # Turn order, evasion, accuracy
@export var vit: int = 10   # Max HP, physical defense
@export var intelligence: int = 10  # Magic attack, item effectiveness
@export var wil: int = 10   # Max MP, magic resist, status resist
