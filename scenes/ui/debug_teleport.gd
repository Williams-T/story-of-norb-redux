extends HBoxContainer

@onready var scenes_container : VBoxContainer = $ScenesContainer
@onready var warps_container : VBoxContainer = $WarpsContainer

func _ready() -> void:
	refresh_scenes()

func refresh_scenes():
	for child in scenes_container.get_children():
		if child.name != "ScenesLabel":
			child.queue_free()
	var dungeons := DirAccess.get_files_at("res://scenes/dungeons/")
	var towns := DirAccess.get_files_at("res://scenes/towns/")
	var world := DirAccess.get_files_at("res://scenes/world/")
	var scenes = []
	for scene in dungeons:
		if scene.contains(".tscn"):
			var path = "res://scenes/dungeons/%s" % scene
			scenes.append(path)
	for scene in towns:
		if scene.contains(".tscn"):
			var path = "res://scenes/towns/%s" % scene
			scenes.append(path)
	for scene in world:
		if scene.contains(".tscn") and !scene.contains("MapScene"):
			var path = "res://scenes/world/%s" % scene
			scenes.append(path)
	for path : String in scenes:
		var button := Button.new()
		button.text = path.split("/")[-1].trim_suffix(".tscn")
		button.pressed.connect(refresh_warps.bind(path))
		scenes_container.add_child(button)

func refresh_warps(path : String):
	for child in warps_container.get_children():
		if child.name != "WarpsLabel":
			child.queue_free()
	var file = FileAccess.open(path,FileAccess.READ)
	if file:
		while not file.eof_reached():
			var line = file.get_line()
			if line.begins_with("warp_id"):
				var warp_id = line.trim_prefix("warp_id = ")
				warp_id = warp_id.get_slice("\"", 1)
				var button := Button.new()
				button.text = warp_id
				button.pressed.connect(func():SceneManager.travel_to(path, warp_id, "fade"); print(path, " ", warp_id))
				warps_container.add_child(button)
