extends AnimatedSprite2D


func _on_pickup_radius_body_entered(body):
	if body is Player:
		body.rope_pickup()
		queue_free()

func _ready():
	play("default")
