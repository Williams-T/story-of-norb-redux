class_name PartyMemberResource
extends EntityResource

@export var battle_sprite_frames: SpriteFrames
@export var portrait: Texture2D
@export var pending_xp : float = 0.0
@export var xp_gauge: float = 0.0
@export var xp_till_level_up : float = 100.0

@export var stat_levels = {
	"str" : [0.0, 100.0],
	"agi" : [0.0, 100.0],
	"vit" : [0.0, 100.0],
	"intelligence" : [0.0, 100.0],
	"wil" : [0.0, 100.0],
}

@export var previous_location = null

func accumulate(stat_name : String, amount : float):
	stat_levels[stat_name][0] += amount
	pending_xp += amount * 0.5

func process_progression():
	for i in stat_levels.keys():
		while stat_levels[i][0] >= stat_levels[i][1]:
			stat_levels[i][0] -= stat_levels[i][1]
			stat_levels[i][1] = stat_levels[i][1] * 1.2
			stats.set(i, stats.get(i)+1)
			EventBus.stat_increased.emit(self, i, stats.get(i))
			print("%s %s raised to %s" % [stats.character_name, i, stats.get(i)])
	xp_gauge += pending_xp
	pending_xp = 0
	while xp_gauge >= xp_till_level_up:
		xp_gauge -= xp_till_level_up
		xp_till_level_up = xp_till_level_up * 1.2
		stats.level += 1
		EventBus.level_increased.emit(self, stats.level)
		print("%s's level raised to %s" % [stats.character_name, stats.level])
		for i in stat_levels.keys():
			stat_levels[i][0] = stat_levels[i][0] * 1.2
			if stat_levels[i][0] >= stat_levels[i][1]:
				stat_levels[i][0] -= stat_levels[i][1]
				stat_levels[i][1] = stat_levels[i][1] * 1.2
				stats.set(i, stats.get(i)+1)
				EventBus.stat_increased.emit(self, i, stats.get(i))
				print("%s %s raised to %s" % [stats.character_name, i, stats.get(i)])
	
