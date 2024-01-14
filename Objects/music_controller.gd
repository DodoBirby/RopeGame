extends Node

@onready var musicplayer = $Music
@onready var menumusic = preload("res://Assets/Pause Menu Track 1 v1.0.mp3")
@onready var gamemusic = preload("res://Assets/Flaming Soul Part 2 v1.0.mp3")


var music_volume = 0.5
var sound_volume = 0.5
var _sound_bus = AudioServer.get_bus_index("SFX")
var _music_bus = AudioServer.get_bus_index("Music")

func _init():
	if FileAccess.file_exists("user://config.cfg"):
		var option_file = FileAccess.open("user://config.cfg", FileAccess.READ)
		
		while option_file.get_position() < option_file.get_length():
			var json: JSON = JSON.new()
			var json_string = option_file.get_line()
			var parse_result = json.parse(json_string)
			if not parse_result == OK:
				print("Json parse error")
				continue
			music_volume = json.data["music_volume"]
			sound_volume = json.data["sfx_volume"]
	AudioServer.set_bus_volume_db(_sound_bus, linear_to_db(sound_volume))
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(music_volume))

func start_menu_music():
	musicplayer.stop()
	musicplayer.stream = menumusic
	musicplayer.play()

func start_game_music():
	musicplayer.stop()
	musicplayer.stream = gamemusic
	musicplayer.play()
