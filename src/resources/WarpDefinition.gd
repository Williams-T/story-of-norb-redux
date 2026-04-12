class_name WarpDefinition
extends Resource

@export var target_scene: String = ""    # res://scenes/... path
@export var target_warp_id: String = ""  # ID of the arrival warp in target scene
@export var transition: String = "fade"  # matches SceneManager transition names
