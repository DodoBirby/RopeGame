extends Node2D

func _ready():
	MusicController.start_menu_music()

func _on_quit_pressed():
	get_tree().quit()


func _on_play_pressed():
	MusicController.start_game_music()
	get_tree().change_scene_to_file("res://Scenes/the_cave.tscn")


func _on_options_pressed():
	get_tree().change_scene_to_file("res://Scenes/options.tscn")
