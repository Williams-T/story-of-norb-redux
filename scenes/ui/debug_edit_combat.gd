extends HBoxContainer
class_name DebugEditCombat

@warning_ignore_start("unused_variable")
@warning_ignore_start("unused_parameter")
@warning_ignore_start("narrowing_conversion")

var current_combatant : BattleCombatant

@onready var combatants_container : VBoxContainer = $Combatants
@onready var stats : GridContainer = $Stats
@onready var buttons : GridContainer = $Options
@onready var hp_field : Label = $Stats/HP_field
@onready var mp_field : Label = $Stats/MP_field
@onready var status_field : Label = $Stats/Statuses_field
@onready var hp_button : Button = $Options/Button
@onready var mp_button : Button = $Options/Button2
@onready var add_status_button : Button = $Options/Button3
@onready var remove_status_button : Button = $Options/Button4
@onready var force_victory_button : Button = $Options/Button5
@onready var force_defeat_button : Button = $Options/Button6
@onready var hp_mp_popup : Popup = $HP_MP_Popup
@onready var hp_mp_label : Label = $HP_MP_Popup/VBoxContainer/Label
@onready var hp_mp_spinbox : SpinBox = $HP_MP_Popup/VBoxContainer/SpinBox
@onready var hp_mp_confirm_button : Button = $HP_MP_Popup/VBoxContainer/HBoxContainer/Button
@onready var hp_mp_cancel_button : Button = $HP_MP_Popup/VBoxContainer/HBoxContainer/Button2
@onready var status_popup : Popup = $Status_Popup
@onready var status_label : Label = $Status_Popup/VBoxContainer/Label
@onready var status_list : ItemList = $Status_Popup/VBoxContainer/ItemList
@onready var status_confirm_button : Button = $Status_Popup/VBoxContainer/HBoxContainer/Button
@onready var status_cancel_button : Button = $Status_Popup/VBoxContainer/HBoxContainer/Button2

var combatants : Array[BattleCombatant] = []
var combat_manager : CombatManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hp_button.pressed.connect(popup_hp_mp.bind("hp"))
	mp_button.pressed.connect(popup_hp_mp.bind("mp"))
	hp_mp_cancel_button.pressed.connect(func():hp_mp_popup.hide())
	add_status_button.pressed.connect(popup_status.bind("add"))
	remove_status_button.pressed.connect(popup_status.bind("remove"))
	status_cancel_button.pressed.connect(func():status_popup.hide())

func refresh_combatants(root : CombatManager):
	combat_manager = root
	for node in combatants_container.get_children():
		node.queue_free()
	for i : BattleCombatant in combat_manager._turn_queue:
		#combatants.append(i)
		var button : Button = Button.new()
		button.text = i.source_resource.stats.character_name
		button.pressed.connect(func(): refresh_stats(i))
		combatants_container.add_child(button)
		print(i.source_resource.stats.character_name)

func refresh_stats(bc : BattleCombatant):
	current_combatant = bc
	hp_field.text = "%s / %s" % [bc.stats.current_hp, bc.stats.max_hp()]
	mp_field.text = "%s / %s" % [bc.stats.current_mp, bc.stats.max_mp()]
	var status_output = ""
	for i in bc.source_resource.active_statuses:
		status_output += "%s, " % i["effect"].status_name
	status_field.text = status_output

func popup_hp_mp(mode : String):
	if hp_mp_confirm_button.pressed.is_connected(send_hp_mp):
		hp_mp_confirm_button.pressed.disconnect(send_hp_mp)
	if mode == "hp":
		hp_mp_label.text = "Set HP"
		hp_mp_spinbox.max_value = current_combatant.stats.max_hp()
		hp_mp_confirm_button.pressed.connect(send_hp_mp.bind("hp"))
	elif mode == "mp":
		hp_mp_label.text = "Set MP"
		hp_mp_spinbox.max_value = current_combatant.stats.max_mp()
		hp_mp_confirm_button.pressed.connect(send_hp_mp.bind("mp"))
	hp_mp_popup.show()

func send_hp_mp(mode : String):
	if mode == "hp":
		#current_combatant.stats.current_hp = min(hp_mp_spinbox.value, current_combatant.stats.max_hp())
		for combatant : BattleCombatant in combat_manager._turn_queue:
			if combatant == current_combatant:
				if combatant.stats.current_hp < hp_mp_spinbox.value:
					combatant.heal(hp_mp_spinbox.value - combatant.stats.current_hp)
					EventBus.emit_signal("combatant_healed", combatant, hp_mp_spinbox.value - combatant.stats.current_hp)
				else:
					combatant.take_damage(combatant.stats.current_hp - hp_mp_spinbox.value)
					EventBus.emit_signal("combatant_damaged", combatant, combatant.stats.current_hp - hp_mp_spinbox.value)
	elif mode == "mp":
		current_combatant.stats.current_mp = min(hp_mp_spinbox.value, current_combatant.stats.max_mp())
		#for combatant : BattleCombatant in combat_manager._turn_queue:
			#if combatant == current_combatant:
				#combatant. (hp_mp_spinbox.value - combatant.stats.current_hp)
	refresh_stats(current_combatant)
	hp_mp_popup.hide()

func popup_status(mode : String):
	if status_confirm_button.pressed.is_connected(send_status):
		status_confirm_button.pressed.disconnect(send_status)
	status_list.clear()
	if mode == "add":
		status_label.text = "Add status"
		var files = DirAccess.get_files_at("res://data/statuses/")
		for file : String in files:
			var current_status : StatusEffect = load("res://data/statuses/%s" % file)
			status_list.add_item(current_status.status_name)
			status_list.set_item_metadata(status_list.item_count-1, current_status)
		status_confirm_button.pressed.connect(send_status.bind("add"))
	elif mode == "remove":
		status_label.text = "Remove status"
		for i in current_combatant.source_resource.active_statuses:
			status_list.add_item(i["effect"].status_name)
			status_list.set_item_metadata(status_list.item_count -1, i["effect"])
		status_confirm_button.pressed.connect(send_status.bind("remove"))
	status_popup.show()

func send_status(mode : String):
	if mode == "add":
		current_combatant.apply_status(status_list.get_item_metadata(status_list.get_selected_items()[0]))
	elif mode == "remove":
		for i in current_combatant.source_resource.active_statuses:
			if i["effect"] == status_list.get_item_metadata(status_list.get_selected_items()[0]):
				current_combatant.source_resource.active_statuses.erase(i)
	refresh_stats(current_combatant)
	status_popup.hide()
