extends CanvasLayer

@onready var tab_container : TabContainer = $PanelContainer/VBoxContainer/TabContainer
@onready var start_combat : DebugStartCombat = $"PanelContainer/VBoxContainer/TabContainer/Start Combat"
@onready var edit_combat : DebugEditCombat = $"PanelContainer/VBoxContainer/TabContainer/Edit Combat"
@onready var edit_items : DebugItems = $PanelContainer/VBoxContainer/TabContainer/Items
func _ready() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		if visible:
			EventBus.player_movement_unlocked.emit()
			hide()
		else:
			EventBus.player_movement_locked.emit()
			if GameState.in_combat:
				tab_container.set_tab_disabled(1, false)
				tab_container.current_tab = 1
				edit_combat.refresh_combatants(get_parent().get_node("/root/Battle"))
				edit_items.refresh_fields(get_parent().get_node("/root/Battle"))
			else:
				tab_container.current_tab = 0
				tab_container.set_tab_disabled(1, true)
				edit_items.refresh_fields()
			show()
	else:
		if visible:
			get_viewport().set_input_as_handled()
