extends Node2D


func save_options():
	var options_file = FileAccess.open("user://config.cfg", FileAccess.WRITE)
	var option_dict = {
		"sfx_volume": MusicController.sound_volume,
		"music_volume": MusicController.music_volume
	}
	var json_string = JSON.stringify(option_dict)
	options_file.store_line(json_string)


func _on_back_button_pressed():
	save_options()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


func _on_fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

