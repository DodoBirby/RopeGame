class_name Switch
extends Area2D

@export var tilemap: TileMap
@export var layer_to_switch: int = 0
@export var enabled: bool = false
@onready var sprite = $Sprite2D

func _ready():
	tilemap = get_parent()
	tilemap.set_layer_enabled(layer_to_switch, enabled)

func _on_body_entered(body):
	if body is Player:
		body.switchnearby = self
	
func _physics_process(delta):
	if enabled:
		sprite.region_rect.position = Vector2.ZERO
	else:
		sprite.region_rect.position = Vector2(16, 0)


func _on_body_exited(body):
	if body is Player:
		body.switchnearby = null

func switch():
	enabled = !enabled
	tilemap.set_layer_enabled(layer_to_switch, enabled)
