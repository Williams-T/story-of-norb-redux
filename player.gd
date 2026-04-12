class_name Player
extends CharacterBody2D

@export var stat_block: CharacterStatBlock

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const AGI_SPEED_MODIFIER := 0.003

var _last_direction := Vector2.DOWN

func _ready() -> void:
	sprite.play("idle_down")

func _physics_process(delta: float) -> void:
	_update_last_direction()
	var direction := _get_input_direction()
	_apply_movement(direction)
	_update_animation(direction)
	move_and_slide()

func _update_last_direction():
	if Input.is_action_pressed("move_up"):
		_last_direction = Vector2.UP
	elif Input.is_action_pressed("move_down"):
		_last_direction = Vector2.DOWN
	elif Input.is_action_pressed("move_left"):
		_last_direction = Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		_last_direction = Vector2.RIGHT
	var vert_strength = Input.get_axis("move_up", "move_down")
	if vert_strength != 0:
		if vert_strength < 0:
			_last_direction = Vector2.UP
		else:
			_last_direction = Vector2.DOWN
		
func _get_input_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up","move_down")

func _apply_movement(direction: Vector2) -> void:
	var agi_modifier := 1.0 + (stat_block.agi - 10) * AGI_SPEED_MODIFIER
	velocity = direction * stat_block.base_move_speed * agi_modifier

func _update_animation(direction : Vector2):
	if direction == Vector2.ZERO:
		_play_idle_animation()
	else:
		_play_walk_animation()

func _play_walk_animation() -> void:
	match _last_direction:
		Vector2.UP:
			sprite.animation = "walk_up"
		Vector2.LEFT:
			sprite.animation = "walk_left"
		Vector2.DOWN:
			sprite.animation = "walk_down"
		Vector2.RIGHT:
			sprite.animation = "walk_right"

func _play_idle_animation():
	match _last_direction:
		Vector2.UP:
			sprite.animation = "idle_up"
		Vector2.LEFT:
			sprite.animation = "idle_left"
		Vector2.DOWN:
			sprite.animation = "idle_down"
		Vector2.RIGHT:
			sprite.animation = "idle_right"
