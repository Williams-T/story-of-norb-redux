extends VBoxContainer

var _current_combatant : BattleCombatant
var _current_page := 0
var target_index = 0
var target_array = []
var all_targets = false
var party = []
var enemies = []
var positions = {}
var slots = {}
var selecting_targets : bool = false


@onready var battle_log_label : RichTextLabel = $TopBar/PanelContainer/BattleLog
@onready var action_menu = $Controls/ActionMenu
@onready var attack_menu = $Controls/AttackMenu
@onready var spell_menu = $Controls/SpellMenu
@onready var item_menu = $Controls/ItemMenu
@onready var attack_button : Button = $Controls/ActionMenu/AttackButton
@onready var spell_button : Button = $Controls/ActionMenu/SpellButton
@onready var item_button : Button = $Controls/ActionMenu/ItemButton
@onready var escape_button : Button = $Controls/ActionMenu/EscapeButton


@onready var enemy_position_1 : Control = $EnemyRow/HBoxContainer/EnemyPosition1
@onready var enemy_position_2 : Control = $EnemyRow/HBoxContainer/EnemyPosition2
@onready var enemy_position_3 : Control = $EnemyRow/HBoxContainer/EnemyPosition3
@onready var enemy_position_4 : Control = $EnemyRow/HBoxContainer/EnemyPosition4
@onready var enemy_position_5 : Control = $EnemyRow/HBoxContainer/EnemyPosition5
@onready var party_position_1 : Control = $PartyRow/HBoxContainer/PartyPosition1
@onready var party_position_2 : Control = $PartyRow/HBoxContainer/PartyPosition2
@onready var party_position_3 : Control = $PartyRow/HBoxContainer/PartyPosition3
@onready var party_position_4 : Control = $PartyRow/HBoxContainer/PartyPosition4
@onready var party_position_5 : Control = $PartyRow/HBoxContainer/PartyPosition5

var current_menu : GridContainer = null
var _tweens_remaining = 0
var _animations_pending = 0

@warning_ignore_start("unused_parameter")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.turn_started.connect(func(c : BattleCombatant): _current_combatant = c)
	EventBus.combat_queued.connect(set_positions)
	EventBus.player_turn_started.connect(set_up)
	EventBus.target_select_requested.connect(target_select)
	EventBus.all_targets.connect(func(): all_targets = true)
	EventBus.combatant_status_applied.connect(func(combatant : BattleCombatant, status : StatusEffect): (positions[combatant].get_child(1) as Indicator).change_text(status.status_name))
	EventBus.combatant_status_expired.connect(func(combatant : BattleCombatant, status : StatusEffect): (positions[combatant].get_child(1) as Indicator).change_text(""))
	action_menu.get_child(0).grab_focus()
	attack_button.pressed.connect(_on_action_menu_pressed.bind('attack'))
	spell_button.pressed.connect(_on_action_menu_pressed.bind('spell'))
	item_button.pressed.connect(_on_action_menu_pressed.bind('item'))
	escape_button.pressed.connect(_on_action_menu_pressed.bind('escape'))
	slots["enemy"]=[
		enemy_position_1,
		enemy_position_2,
		enemy_position_3,
		enemy_position_4,
		enemy_position_5,
	]
	slots["party"]=[
		party_position_1,
		party_position_2,
		party_position_3,
		party_position_4,
		party_position_5,
	]
	EventBus.combatant_damaged.connect(_on_combatant_damaged)
	EventBus.combatant_died.connect(_on_combatant_died)
	EventBus.combatant_healed.connect(_on_combatant_healed)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.combat_log_updated.connect(_on_combat_log_updated)

func _on_combat_log_updated(text : String):
	battle_log_label.text = text
		

func set_positions(combatants : Array[BattleCombatant]):
	party.clear()
	enemies.clear()
	for i in combatants:
		if i.is_player_controlled:
			party.append(i)
		else:
			enemies.append(i)
	for i in slots["enemy"].size():
		if i < enemies.size():
			positions[enemies[i]]=slots["enemy"][i]
		else:
			slots["enemy"][i].hide()
	for i in slots["party"].size():
		if i < party.size():
			positions[party[i]]=slots["party"][i]
		else:
			slots["party"][i].hide()
	_tweens_remaining = positions.keys().size()
	for i : BattleCombatant in positions.keys():
		var sprite = AnimatedSprite2D.new()
		#sprite.sprite_frames = i.source_resource.sprite_frames
		if i.source_resource is EnemyResource:
			sprite.sprite_frames = i.source_resource.sprite_frames
		elif i.source_resource is PartyMemberResource:
			sprite.sprite_frames = i.source_resource.battle_sprite_frames
		positions[i].add_child(sprite)
		var offset = Vector2(600, 0) if not i.is_player_controlled else Vector2(-600, 0)
		sprite.position = offset
		sprite.set_meta("dead", false)
		sprite.animation_finished.connect(func():
			if not sprite.get_meta("dead"):
				if sprite.sprite_frames.has_animation("idle"):
					sprite.play("idle")
			else:
				sprite.stop())
		#sprite.play("battle_entrance")
		if sprite.sprite_frames.has_animation("idle_down"):
			sprite.play("idle_down")
		var target_pos = positions[i].size
		var tween = create_tween()
		tween.tween_property(sprite, "position", target_pos, 0.4)
		tween.finished.connect(func():
			_tweens_remaining -= 1
			if _tweens_remaining <= 0:
				EventBus.combat_visuals_ready.emit()
				_tweens_remaining = positions.keys().size())
		var indicator : Indicator = preload("res://scenes/ui/indicator.tscn").instantiate()
		positions[i].add_child(indicator)
		positions[i].get_child(1).hide()
		indicator.hp_bar.min_value = 0
		indicator.mp_bar.min_value = 0
		indicator.hp_bar.max_value = i.max_hp()
		indicator.mp_bar.max_value = i.max_mp()
		indicator.hp_bar.value = i.stats.current_hp
		indicator.mp_bar.value = i.stats.current_mp
		#indicator.text = "v"
		indicator.offset_transform_enabled = true
		indicator.offset_transform_position = Vector2(80,20)
		##indicator.offset_transform_position_ratio = Vector2(1.8, -0.8)
		#indicator.offset_transform_position = Vector2(125,60)
		#indicator.name = "SelectionArrow"
func set_up(prev_node : GridContainer = null): 
	if prev_node != null:
		prev_node.hide()
	action_menu.show()
	current_menu = action_menu
	var button : Button = action_menu.get_child(0)
	button.grab_focus()

func _on_action_menu_pressed(choice : String):
	match choice:
		'attack':
			populate_attack_menu()
		'spell':
			populate_spell_menu()
		'item':
			populate_item_menu()
		'escape':
			EventBus.player_flee_attempted.emit()

func paginate(action_array : Array, base_node : GridContainer, page : int = 0):
	var button_1 : Button = base_node.find_child("Button1")
	button_1.grab_focus()
	var button_2 : Button = base_node.find_child("Button2")
	var button_3 : Button = base_node.find_child("Button3")
	var buttons = [button_1, button_2, button_3]
	var back : Button = base_node.find_child("Back")
	if back.pressed.is_connected(set_up):
		back.pressed.disconnect(set_up)
	back.pressed.connect(set_up.bind(base_node))
	var navigation := base_node.find_child("Navigation")
	var nav_next : Button = base_node.find_child("NavNext")
	var nav_back : Button = base_node.find_child("NavBack")
	if nav_back.pressed.is_connected(set_up):
		nav_back.pressed.disconnect(set_up)
	nav_back.pressed.connect(set_up.bind(base_node))
	if action_array.size() > 3:
		back.hide()
		navigation.show()
	else:
		back.show()
		navigation.hide()
	for i in range(3):
		var action_index = (page * 3)+i
		var button : Button = buttons[i]
		if action_index <= action_array.size() - 1:
			if action_array[action_index] is BattleAction:
				button.text = action_array[action_index].action_name
			elif action_array[action_index] is ItemResource:
				button.text = action_array[action_index].item_name
			if button.pressed.is_connected(send_action):
				button.pressed.disconnect(send_action)
			button.pressed.connect(send_action.bind(action_array[action_index]))
			if nav_next.pressed.is_connected(paginate):
				nav_next.pressed.disconnect(paginate)
			nav_next.pressed.connect(paginate.bind(action_array, base_node, page + 1))
		else:
			buttons[i].disabled = true
			if nav_next.pressed.is_connected(paginate):
				nav_next.pressed.disconnect(paginate)
			nav_next.pressed.connect(paginate.bind(action_array, base_node, 0))
func send_action(action):
	if action is BattleAction:
		EventBus.player_action_selected.emit(action)
	elif action is ItemResource:
		pass

func target_select(valid_targets : Array[BattleCombatant]):
	current_menu.hide()
	selecting_targets = true
	target_array = valid_targets
	target_index = 0
	clear_arrows()
	var arrow = positions[target_array[target_index]].get_child(1)
	arrow.show()
	arrow.change_color(Color.RED)

func _on_resolve_started():
	_animations_pending = 0
	await get_tree().process_frame
	if _animations_pending <= 0:
		EventBus.combat_animations_finished.emit()

func _on_combatant_damaged(combatant : BattleCombatant, amount : int):
	var sprite : AnimatedSprite2D = positions[combatant].get_child(0)
	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	_animations_pending += 1
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.3)
	var indicator : Indicator = positions[combatant].get_child(1)
	indicator.update_hp(combatant.stats.current_hp)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	tween.finished.connect(func():
		_animations_pending -= 1
		if _animations_pending <= 0:
			EventBus.combat_animations_finished.emit())
	
	
func _on_combatant_died(combatant : BattleCombatant):
	var sprite : AnimatedSprite2D = positions[combatant].get_child(0)
	if sprite.sprite_frames.has_animation("died"):
		sprite.play("died")
	sprite.set_meta("dead",true)
	sprite.animation_finished.connect(func():
		_animations_pending += 1
		var tween = create_tween()
		tween.tween_property(positions[combatant], "custom_minimum_size.x", 0, 0.3)
		tween.tween_callback(positions[combatant].hide)
		tween.finished.connect(func():
			_animations_pending -= 1
			if _animations_pending <= 0:
				EventBus.combat_animations_finished.emit())
		)
	
func _on_combatant_healed(combatant : BattleCombatant, amount : int):
	var sprite : AnimatedSprite2D = positions[combatant].get_child(0)
	if sprite.sprite_frames.has_animation("healed"):
		sprite.play("healed")
	_animations_pending += 1
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.GREEN, 0.3)
	var indicator : Indicator = positions[combatant].get_child(1)
	indicator.update_hp(combatant.stats.current_hp)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	tween.finished.connect(func():
		_animations_pending -= 1
		if _animations_pending <= 0:
			EventBus.combat_animations_finished.emit())

func _on_turn_started(combatant : BattleCombatant):
	clear_arrows()
	var arrow = positions[combatant].get_child(1)
	arrow.show()
	arrow.change_color(Color.YELLOW)
	pass # put arrow as child and control show/hide from this method

func clear_arrows():
	for i : BattleCombatant in enemies + party:
		var node : Indicator = positions[i].get_child(1)
		#node.modulate = Color.WHITE
		node.hide()

func populate_attack_menu():
	_current_page = 0
	action_menu.hide()
	attack_menu.show()
	current_menu = attack_menu
	paginate(_current_combatant.physical_actions, attack_menu, _current_page)

func populate_spell_menu():
	_current_page = 0
	action_menu.hide()
	spell_menu.show()
	current_menu = spell_menu
	paginate(_current_combatant.return_available_magic_actions() + _current_combatant.return_available_healing_actions(), spell_menu, _current_page)

func populate_item_menu():
	_current_page = 0
	action_menu.hide()
	item_menu.show()
	current_menu = item_menu
	paginate(_current_combatant.inventory, item_menu, _current_page)

func _unhandled_input(event: InputEvent) -> void:
	if selecting_targets and !all_targets:
		if event.is_action_pressed("combat_confirm") or target_array.size() == 1:
			var targets :Array[BattleCombatant] = []
			targets.append(target_array[target_index])
			EventBus.player_targets_selected.emit(targets)
			selecting_targets = false
		elif event.is_action_pressed('move_right') or event.is_action_pressed("move_down"):
			target_index = wrapi(target_index + 1, 0, target_array.size())
			update_target_arrow()
		elif event.is_action_pressed('move_left') or event.is_action_pressed("move_up"):
			target_index = wrapi(target_index - 1, 0, target_array.size())
			update_target_arrow()
		elif event.is_action_pressed("combat_cancel"):
			selecting_targets = false
			all_targets = false
			set_up()
	elif selecting_targets:
		if event.is_action_pressed("combat_confirm") or target_array.size() == 1:
			EventBus.player_targets_selected.emit(target_array)
			selecting_targets = false
			all_targets = false

func update_target_arrow():
	if !all_targets:
		clear_arrows()
		var arrow = positions[target_array[target_index]].get_child(1)
		arrow.show()
		arrow.change_color(Color.RED)
	else:
		clear_arrows()
		for i in target_array.size():
			var arrow = positions[target_array[i]].get_child(1)
			arrow.show()
			arrow.change_color(Color.RED)
