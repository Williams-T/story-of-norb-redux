extends NPC

@export var group : EnemyGroupResource
var awaiting_dialogue := false

func _ready() -> void:
	super._ready()
	for i in interaction_area.body_entered.get_connections():
		interaction_area.body_entered.disconnect(i["callable"])
	interaction_area.body_entered.connect(_on_body_entered)
	EventBus.interact_pressed.disconnect(try_interact)
	#EventBus.interact_pressed.connect(try_interact)

func _on_body_entered(body : Node2D):
	if body is Player:
		_player_in_range = true
		_interactable_entity = body
		try_interact()

func try_interact():
	if group != null and _player_in_range:
		if queued_dialogue:
			orient_facing(position.direction_to(_interactable_entity.position))
			awaiting_dialogue = true
			DialogueManager.start_dialogue(queued_dialogue)
		else:
			EncounterManager.start_encounter(group, true)

func _on_dialogue_finished():
	if awaiting_dialogue == true:
		awaiting_dialogue = false
		EncounterManager.start_encounter(group, true)
