class_name EnemyResource
extends Resource

@export var enemy_name: String = ""
@export var sprite_frames: SpriteFrames
@export var stats: CharacterStatBlock

@export_group("Rewards")
@export var experience_reward: int = 0
@export var gold_reward: int = 0
@export var drop_table: Array[ItemResource] = []
