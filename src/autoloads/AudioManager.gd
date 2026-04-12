extends Node

# Bus structure is defined in the Godot Audio panel, not here.
# Musicians: your files go in res://audio/music/ and res://audio/sfx/

func play_music(track_path: String, transition: String = "crossfade") -> void:
	pass


func play_sfx(sfx_path: String) -> void:
	pass


func _ready() -> void:
	EventBus.music_change_requested.connect(
		func(path, transition): play_music(path, transition)
	)
	EventBus.sfx_requested.connect(
		func(path): play_sfx(path)
	)
