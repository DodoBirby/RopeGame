class_name HUD
extends CanvasLayer

@onready var gameoverscreen = $GameOver
var radius: float = 0.0


func _ready():
	GlobalSignalBus.PLAYERDIED.connect(_on_player_playerdied)
	wakeup()

func _process(delta):
	gameoverscreen.material.set_shader_parameter("radius", radius)

func _on_player_playerdied():
	gameoverscreen.visible = true
	

func wakeup():
	var tween = get_tree().create_tween()
	radius = 0.0
	tween.tween_property(self, "radius", 1.0, 2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

