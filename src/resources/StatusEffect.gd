class_name StatusEffect
extends Resource

enum StatusType {POISON, SLEEP, BLIND, STUN, BERSERK}

@export var status_name : String = ""
@export var status_type : StatusType = StatusType.POISON
@export var duration_turns : int = -1
@export var damage_per_turn : int = 0
@export var blocks_action : bool = false
@export var accuracy_modifier : float = 1.0
