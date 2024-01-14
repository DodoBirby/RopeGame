extends Enemy

@onready var hurtbox = $Hurtbox
@onready var raycastleft = $RayCast2DLeft
@onready var raycastright = $RayCast2DRight
@onready var raycastwallleft = $RayCast2DWallLeft
@onready var raycastwallright = $RayCast2DWallRight


var facing = 1
@onready var goblin = $Goblin
var MOVESPEED: float = 300
var GRAVITY = 400.0

func _physics_process(delta):
	for body in hurtbox.get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage()
	velocity.y += GRAVITY * delta
	velocity.x = MOVESPEED * facing
	if facing == -1 and not raycastleft.is_colliding():
		facing = 1
	elif facing == 1 and not raycastright.is_colliding():
		facing = -1
	if facing == 1 and raycastwallright.is_colliding():
		facing = -1
	elif facing == -1 and raycastwallleft.is_colliding():
		facing = 1
	move_and_slide()
	animator(delta)

func take_damage():
	GlobalSignalBus.shake_camera(30.0)
	queue_free()

func animator(delta):
	if facing == 1:
		goblin.flip_h = false
	else:
		goblin.flip_h = true
	goblin.play("default")
