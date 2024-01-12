extends CanvasLayer

@onready var gameoverscreen = $GameOver

func _on_player_playerdied():
	gameoverscreen.visible = true
