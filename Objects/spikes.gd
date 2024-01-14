extends StaticBody2D

@onready var Hurtbox = $Hurtbox

func _physics_process(delta):
	for body in Hurtbox.get_overlapping_bodies():
		if body is Player:
			body.take_damage()
