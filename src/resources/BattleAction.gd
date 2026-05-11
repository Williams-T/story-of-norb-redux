class_name BattleAction
extends Resource

enum ActionCategory {ATTACK, MAGIC, SKILL}
enum TargetType {SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF}
enum DamageType {PHYSICAL, MAGICAL, HEALING, NONE}

@export var action_name: String = ""
@export var description: String = ""
@export var category: ActionCategory = ActionCategory.ATTACK
@export var mp_cost: int = 0 # zero for physical attacks
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var power: int = 1 #the base value the damage formula will scale from
@export var status_to_apply: StatusEffect = null # null means no status, so no default needed
@export_range(0.0, 1.0, 0.1) var status_chance: float = 0.5 # probability the status applies, 0.0 to 1.0
@export var animation_key: String = ""
