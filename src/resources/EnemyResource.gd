class_name EnemyResource
extends EntityResource

enum AIBehavior { RANDOM, AGGRESSIVE, DEFENSIVE, HEALER, BERSERKER }

@export var enemy_name: String = ""
@export var sprite_frames: SpriteFrames

@export_group("Rewards")
@export var experience_reward: int = 0
@export var gold_reward: int = 0
@export var drop_table: Array[ItemResource] = []
@export var equip_drop_chance : float = 0.5

@export_group("Battle")
@export var behavior: AIBehavior = AIBehavior.RANDOM
