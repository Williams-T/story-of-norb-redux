extends Control
class_name Indicator

@onready var hp_bar : TextureProgressBar = $PanelContainer/VBoxContainer/HPBar
@onready var mp_bar : TextureProgressBar = $PanelContainer/VBoxContainer/MPBar
@onready var panel : PanelContainer = $PanelContainer
@onready var status_label : RichTextLabel = $PanelContainer/VBoxContainer/StatusLabel
@onready var label : Label = $PanelContainer/Label
var color : Color = Color(0.145, 0.145, 0.145)
var stylebox = preload("res://art/ui/indicator_stylebox.tres")

func _ready() -> void:
	hp_bar.min_value = 0
	mp_bar.min_value = 0
	hp_bar.max_value = 100
	mp_bar.max_value = 100
	change_text("")

func visibility(is_true : bool):
	#visible = is_visible
	var tween = create_tween()
	if is_true:
		if !visible:
			visible = true
		tween.tween_property(self, "modulate", Color(1,1,1,1), 0.2)
	else:
		tween.tween_property(self, "modulate", Color(1,1,1,0), 0.6)

func change_color(_color : Color):
	#var color_mod : Color = Color(color.r, color.g, color.b, 0.1)
	#var new_stylebox : StyleBoxFlat = stylebox.duplicate()
	#new_stylebox.bg_color = color_mod
	#panel.remove_theme_stylebox_override("panel")
	#panel.add_theme_stylebox_override('panel', new_stylebox)
	label.modulate = _color

func update_hp(new_value : int):
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", new_value, 0.3)

func update_mp(new_value : int):
	var tween = create_tween()
	tween.tween_property(mp_bar, "value", new_value, 0.3)

func change_text(text : String):
	status_label.text = text
	if text == "":
		status_label.hide()
	else:
		status_label.show()
