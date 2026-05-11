extends CharacterBody2D
class_name NPC

#@export var inventory = [ItemResource]
@export var stats : CharacterStatBlock = null
@export var queued_dialogue : DialogueSequence = null
@export_range(0.0, 999.99, 0.1) var wander_radius := 0.0

@onready var sprite : AnimatedSprite2D = $Sprite
@onready var interaction_area :Area2D = $InteractionArea
@onready var timer : Timer = $Timer

enum Directions {NORTH, EAST, SOUTH, WEST}
var facing : Directions = Directions.SOUTH
var _wander_origin : Vector2
var _target_position : Vector2
#var _wander_delay = 10.0
#var _wander_max_interval = 15.0
var _player_in_range := false
var _interactable_entity : Node2D = null
var _wandering := false

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exit)
	timer.timeout.connect(wander)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.interact_pressed.connect(try_interact)
	_wander_origin = position
	orient_facing(Vector2.DOWN)
	if wander_radius > 0.0:
		timer.start(randf_range(6.0, 12.0))

func _on_dialogue_started(_sequence : DialogueSequence):
	timer.stop()
	_wandering = false
func _on_dialogue_finished():
	if wander_radius > 0.0:
		timer.start(randf_range(6.0, 12.0))

func _on_body_entered(body : Node2D):
	if body is Player:
		_player_in_range = true
		_interactable_entity = body

func _on_body_exit(body : Node2D):
	if body is Player:
		_player_in_range = false
		_interactable_entity = null

func try_interact():
	if _player_in_range and queued_dialogue:
		orient_facing(position.direction_to(_interactable_entity.position))
		DialogueManager.start_dialogue(queued_dialogue)

func orient_facing(dir : Vector2):
	if abs(dir.y) > abs(dir.x):
		facing = Directions.SOUTH if dir.y > 0 else Directions.NORTH
	else:
		facing = Directions.EAST if dir.x > 0 else Directions.WEST
	if !_wandering:
		match facing:
			Directions.NORTH:
				sprite.play("idle_up")
			Directions.SOUTH:
				sprite.play("idle_down")
			Directions.EAST:
				sprite.play("idle_right")
			Directions.WEST:
				sprite.play("idle_left")
	else:
		match facing:
			Directions.NORTH:
				sprite.play("walk_up")
			Directions.SOUTH:
				sprite.play("walk_down")
			Directions.EAST:
				sprite.play("walk_right")
			Directions.WEST:
				sprite.play("walk_left")

func wander():
	_wandering = true
	randomize()
	var t = randf() * TAU # Random angle
	var r = sqrt(randf()) * wander_radius # Uniform radius
	_target_position = _wander_origin + Vector2(r * cos(t), r * sin(t))
	orient_facing(_wander_origin.direction_to(_target_position))
	if stats:
		velocity = _wander_origin.direction_to(_target_position) * stats.base_move_speed 
	else:
		velocity = _wander_origin.direction_to(_target_position) * 120.0

func _physics_process(_delta: float) -> void:
	if _wandering and (position.distance_to(_target_position) < 8.0 \
or position.distance_to(_wander_origin) >= wander_radius):
		_wandering = false
		orient_facing(velocity)
		velocity = Vector2.ZERO
		timer.start(randf_range(6.0, 12.0))
	if wander_radius > 0.0 and _wandering:
		move_and_slide()
