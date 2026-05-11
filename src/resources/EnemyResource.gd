# Stretch goal: this resource is intended to eventually extend
# a shared EntityResource base alongside EnemyResource.
# Keep shared fields structurally parallel to EnemyResource.

class_name EnemyResource
extends EntityResource

enum AIBehavior { RANDOM, AGGRESSIVE, DEFENSIVE, HEALER, BERSERKER }

@export var enemy_name: String = ""
@export var sprite_frames: SpriteFrames
@export var stats: CharacterStatBlock

@export_group("Rewards")
@export var experience_reward: int = 0
@export var gold_reward: int = 0
@export var drop_table: Array[ItemResource] = []

@export_group("Battle")
@export var actions : Array[BattleAction] = []
@export var behavior: AIBehavior = AIBehavior.RANDOM
