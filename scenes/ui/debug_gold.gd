extends HBoxContainer
class_name DebugGold

@onready var gold_spin : SpinBox = $VBoxContainer/HBoxContainer/SpinBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gold_spin.value = GameState.gold
	gold_spin.changed.connect(func(value):GameState.gold = value)
