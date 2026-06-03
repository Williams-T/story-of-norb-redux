extends HBoxContainer

@onready var entities_container : VBoxContainer = $EntitiesContainer
@onready var add_button : Button = $ButtonContainer/AddButton
@onready var remove_button : Button = $ButtonContainer/RemoveButton
@onready var party_container : VBoxContainer = $PartyContainer
@onready var name_edit : LineEdit = $StatsContainer/HBoxContainer/NameLineEdit
@onready var level_spin : SpinBox = $StatsContainer/LevelSpin
@onready var hp_spin : SpinBox = $StatsContainer/GridContainer/HpSpinBox
@onready var mp_spin : SpinBox = $StatsContainer/GridContainer/MpSpinBox
@onready var str_spin : SpinBox = $StatsContainer/GridContainer2/StrSpinBox
@onready var vit_spin : SpinBox = $StatsContainer/GridContainer2/VitSpinBox
@onready var agi_spin : SpinBox = $StatsContainer/GridContainer2/AgiSpinBox
@onready var int_spin : SpinBox = $StatsContainer/GridContainer2/IntSpinBox
@onready var wil_spin : SpinBox = $StatsContainer/GridContainer2/WilSpinBox

var current_party_member : EntityResource
var populating = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refresh_entities()
	refresh_party()
	add_button.pressed.connect(func(): GameState.party.append(current_party_member) ; refresh_party())
	remove_button.pressed.connect(func(): GameState.party.erase(current_party_member); refresh_party())
	name_edit.text_changed.connect(save_fields)
	level_spin.value_changed.connect(save_fields)
	hp_spin.value_changed.connect(save_fields)
	mp_spin.value_changed.connect(save_fields)
	str_spin.value_changed.connect(save_fields)
	vit_spin.value_changed.connect(save_fields)
	agi_spin.value_changed.connect(save_fields)
	int_spin.value_changed.connect(save_fields)
	wil_spin.value_changed.connect(save_fields)

func refresh_entities():
	for node in entities_container.get_children():
		if node.name != "EntitiesLabel":
			node.queue_free()
	var entities = []
	entities.append_array(DirAccess.get_files_at("res://data/characters/"))
	#entities.append_array(DirAccess.get_files_at("res://data/enemies/"))
	for i : String in entities:
		var loaded
		if i in DirAccess.get_files_at("res://data/characters/"):
			loaded = load("res://data/characters/%s" % i)
		else:
			loaded = load("res://data/enemies/%s" % i)
		if loaded is PartyMemberResource or loaded is EnemyResource:
			var button := Button.new()
			button.text = i.trim_suffix(".tres")
			button.pressed.connect(select_entity.bind(loaded, button))
			entities_container.add_child(button)

func refresh_party():
	for node in party_container.get_children():
		if node.name != "PartyLabel":
			node.queue_free()
	for i : EntityResource in GameState.party:
		var button := Button.new()
		button.text = i.stats.character_name
		button.pressed.connect(select_party_member.bind(i, button))
		party_container.add_child(button)
func select_entity(entity : EntityResource, button):
	if entity is EnemyResource:
		var new_party_member := PartyMemberResource.new()
		new_party_member.stats = entity.stats.duplicate(true)
		new_party_member.stats.character_name = entity.enemy_name
		new_party_member.inventory = entity.drop_table
		new_party_member.actions = entity.actions
		current_party_member = new_party_member
	else:
		current_party_member = entity
	for child in entities_container.get_children() + party_container.get_children():
		if !(child is Button):
			continue
		if child != button:
			child.add_theme_color_override("font_color", Color.WHITE)
		else:
			child.add_theme_color_override("font_color", Color.GOLD)
	add_button.disabled = false
	remove_button.disabled = true

func select_party_member(entity : EntityResource, button : Button):
	for child in entities_container.get_children() + party_container.get_children():
		if !(child is Button):
			continue
		if child != button:
			child.add_theme_color_override("font_color", Color.WHITE)
		else:
			child.add_theme_color_override("font_color", Color.GOLD)
	current_party_member = entity
	populate_fields()
	add_button.disabled = true
	remove_button.disabled = false

func populate_fields():
	populating = true
	name_edit.text = current_party_member.stats.character_name
	level_spin.value = current_party_member.stats.level
	if current_party_member.stats.current_hp == -1:
		current_party_member.stats.current_hp = current_party_member.stats.max_hp()
	hp_spin.value = current_party_member.stats.current_hp
	hp_spin.max_value = current_party_member.stats.max_hp()
	if current_party_member.stats.current_mp == -1:
		current_party_member.stats.current_mp = current_party_member.stats.max_mp()
	mp_spin.value = current_party_member.stats.current_mp
	mp_spin.max_value = current_party_member.stats.max_mp()
	str_spin.value = current_party_member.stats.str
	vit_spin.value = current_party_member.stats.vit
	agi_spin.value = current_party_member.stats.agi
	int_spin.value = current_party_member.stats.intelligence
	wil_spin.value = current_party_member.stats.wil
	populating = false

func save_fields(val):
	if current_party_member and populating == false:
		current_party_member.stats.character_name = name_edit.text
		current_party_member.stats.level = level_spin.value
		current_party_member.stats.current_hp = hp_spin.value
		current_party_member.stats.current_mp = mp_spin.value
		current_party_member.stats.str = str_spin.value
		current_party_member.stats.vit = vit_spin.value
		current_party_member.stats.agi = agi_spin.value
		current_party_member.stats.intelligence = int_spin.value
		current_party_member.stats.wil = wil_spin.value
