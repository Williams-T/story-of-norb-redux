extends VBoxContainer
class_name DebugStartCombat


var current_enemy_group : EnemyGroupResource = null
var enemy_groups := {}

@onready var combat_list : ItemList = $ItemList
@onready var combat_button : Button = $Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	combat_button.pressed.connect(start_combat)
	scan_enemy_groups()
	pass # Replace with function body.

func scan_enemy_groups():
	enemy_groups.clear()
	var files = DirAccess.get_files_at("res://data/enemy_groups/")
	for file : String in files:
		var loaded = load("res://data/enemy_groups/%s" % file)
		if loaded is EnemyGroupResource:
			combat_list.add_item(file)
			combat_list.set_item_metadata(combat_list.item_count - 1, loaded)

func start_combat():
	if GameState.in_combat:
		SceneManager.end_combat('')
	if combat_list.is_anything_selected():
		DebugMenu.hide()
		SceneManager.start_combat(combat_list.get_item_metadata(combat_list.get_selected_items()[0]))
