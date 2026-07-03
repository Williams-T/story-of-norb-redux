extends MapController
class_name DungeonController

@export var dungeon_resource : DungeonResource

func _ready() -> void:
	super._ready()
	EncounterManager.register_floor(dungeon_resource, player)
	if EncounterManager.returned_from_combat == true:
		EncounterManager.returned_from_combat = false
		player.global_position = EncounterManager.player_positions[0]
		#print("%s , %s" % [player.global_position, EncounterManager.player_positions])

func _exit_tree() -> void:
	EncounterManager.deregister_floor()
