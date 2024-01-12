extends CharacterBody2D

@onready var hurtbox = $Hurtbox

func _physics_process(delta):
	for body in hurtbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage()
