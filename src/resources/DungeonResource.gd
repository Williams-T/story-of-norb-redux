class_name DungeonResource extends Resource

@export var floor_name: String = ""
@export var encounter_rate: float = 0.0
# groups and weights are index aligned, solely modified by the editor
@export var encounter_groups: Array[EnemyGroupResource] = []
@export var encounter_weights: Array[float] = []
@export var encounter_music: String = ""
