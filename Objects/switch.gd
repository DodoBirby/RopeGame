class_name Switch
extends Area2D

@export var tilemap: TileMap
@export var layer_to_switch: int = 0
var enabled: bool = false


func _on_body_entered(body):
	if body is Player:
		body.switchnearby = self
	
func _physics_process(delta):
	if enabled:
		modulate = Color(1, 1, 1, 1)
	else:
		modulate = Color(1, 1, 1, 0.5)


func _on_body_exited(body):
	if body is Player:
		body.switchnearby = null

func switch():
	enabled = !enabled
	tilemap.set_layer_enabled(layer_to_switch, enabled)
