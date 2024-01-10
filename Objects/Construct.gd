extends CharacterBody2D
@export var GRAVITY = 2000
@export var JUMPFORCE = 800
@export var MOVESPEED = 500
@onready var area2d = $Area2D
var active: bool = false
var colliding: bool = false
var player: Player

func _physics_process(delta):
	var gravmultiplier = 1
	var dir = 0
	
	
	if active:
		player.position = position
		if Input.is_action_pressed("Left"):
			dir = -1
		elif Input.is_action_pressed("Right"):
			dir = 1
		if Input.is_action_just_pressed("Up") and is_on_floor():
			velocity.y = -JUMPFORCE
		if not Input.is_action_pressed("Up"):
			gravmultiplier = 3
		if Input.is_action_just_pressed("Down"):
			player.visible = true
			active = false
	
	elif Input.is_action_just_pressed("Down") and colliding:
		active = true
		
	velocity.y += GRAVITY * delta * gravmultiplier
	velocity.x = lerp(velocity.x, float(MOVESPEED * dir), 0.3)
	move_and_slide()


func _on_area_2d_body_entered(body):
	if body is Player:
		colliding = true
		player = body
	

func _on_area_2d_body_exited(body):
	if body is Player:
		colliding = false
