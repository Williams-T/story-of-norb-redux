class_name Player
extends CharacterBody2D

#@export var stat_block: CharacterStatBlock
@export var party_member : PartyMemberResource

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var cam : Camera2D = $Camera2D

const AGI_SPEED_MODIFIER := 0.003

var _last_direction := Vector2.DOWN

func _ready() -> void:
	#GameState.previous_player_location = global_position
	sprite.play("idle_down")
	print(party_member.stats.current_hp)
	EventBus.player_movement_unlocked.connect(func():set_physics_process(true))
	EventBus.player_movement_locked.connect(func():set_physics_process(false))
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('interact'):
		EventBus.interact_pressed.emit()

func _physics_process(_delta: float) -> void:
	var direction := _get_input_direction()
	_update_last_direction()
	_apply_movement(direction)
	_update_animation(direction)
	move_and_slide()

func _update_last_direction():
	if Input.is_action_pressed("move_left"):
		_last_direction = Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		_last_direction = Vector2.RIGHT
	if Input.is_action_pressed("move_up"):
		_last_direction = Vector2.UP
	elif Input.is_action_pressed("move_down"):
		_last_direction = Vector2.DOWN
		
func _get_input_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up","move_down")

func _apply_movement(direction: Vector2) -> void:
	var agi_modifier :float = 1.0 + (party_member.stats.agi - 10) * AGI_SPEED_MODIFIER
	velocity = direction * party_member.stats.base_move_speed * agi_modifier

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

func set_camera_limits(rect : Rect2):
	@warning_ignore_start("narrowing_conversion")
	cam.limit_top = rect.position.y
	cam.limit_left = rect.position.x
	cam.limit_bottom = rect.position.y + rect.size.y
	cam.limit_right = rect.position.x + rect.size.x
