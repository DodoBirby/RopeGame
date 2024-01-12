class_name Player
extends CharacterBody2D
# Things to modify
var MOVESPEED = 400
var PULLFORCE = 0.5
var JUMP_HEIGHT: float = 130
var TIME_TO_PEAK: float = 0.5
var THROWFORCE = 1300
var INVINCIBILITY_FRAMES = 60
var tetherlength = 500
var health = 2
var maxhealth = 2
var invincibility = 0



# Don't touch these, these are controlled by JUMP_HEIGHT and TIME_TO_PEAK above
var GRAVITY = 2.0 * JUMP_HEIGHT / pow(TIME_TO_PEAK, 2)
var JUMPFORCE = 2.0 * JUMP_HEIGHT / TIME_TO_PEAK

var construct_scene: PackedScene = preload("res://Objects/RopeConstruct.tscn")
var state = STATES.GROUNDED
var active = true


enum STATES {AIRBORNE, GROUNDED, INACTIVE}

signal PLAYERDIED

var tetherpoint: RopeConstruct

func _ready():
	tetherpoint = construct_scene.instantiate()
	get_parent().add_child.call_deferred(tetherpoint)
	tetherpoint.position = position
	tetherpoint.player = self
'''
Runs once every frame (60fps)
'''
func _physics_process(delta):
	state_tick(delta)
	var transition = state_transition()
	if transition != null:
		change_state(transition)

'''
Grounded state tick function
'''
func grounded_tick(delta):
	var dir = 0
	if Input.is_action_pressed("Left"):
		dir = -1
	elif Input.is_action_pressed("Right"):
		dir = 1
	if Input.is_action_just_pressed("Up"):
		velocity.y = -JUMPFORCE
	if Input.is_action_just_pressed("Down"):
		tetherpoint.clap()
	velocity.x = lerp(velocity.x, float(MOVESPEED * dir), 0.3)
	var tethervector = tetherpoint.position - position
	if (tethervector.length() > tetherlength + 20):
		position += tethervector.normalized() * (tethervector.length() - tetherlength - 20)
	move_and_slide()


'''
Airborne state tick function
'''
func airborne_tick(delta):
	var dir = 0
	var gravmultiplier = 1
	if Input.is_action_pressed("Left"):
		dir = -1
	elif Input.is_action_pressed("Right"):
		dir = 1
	if not Input.is_action_pressed("Up"):
		gravmultiplier = 3
	if Input.is_action_just_pressed("Down"):
		tetherpoint.clap()
	if dir != 0:
		var speedcap
		if dir == 1:
			speedcap = max(velocity.x, MOVESPEED)
		else:
			speedcap = min(velocity.x, -MOVESPEED)
		velocity.x = lerp(velocity.x, float(speedcap), 0.3)
	velocity.y += GRAVITY * delta * gravmultiplier
	var tethervector = tetherpoint.position - position
	var dotproduct = tethervector.normalized().dot(velocity)
	if (dotproduct < 0 and tethervector.length() > tetherlength):
		var multiplier = 1
		if dotproduct < -300:
			multiplier = 1.5
		velocity += -dotproduct * tethervector.normalized() * multiplier
	if (tethervector.length() > tetherlength + 20):
		position += tethervector.normalized() * (tethervector.length() - tetherlength - 20)
	move_and_slide()
'''
Called when a state transition needs to occur
'''
func change_state(newstate):
	exit_state(state)
	enter_state(newstate)
	state = newstate

'''
Runs when a state is exited
'''
func exit_state(oldstate) -> void:
	match oldstate:
		STATES.INACTIVE:
			visible = true

'''
Runs when a new state is entered
'''
func enter_state(newstate) -> void:
	pass

'''
Runs per frame state logic
'''
func state_tick(delta) -> void:
	
	if invincibility > 0:
		invincibility -= 1
	match state:
		STATES.GROUNDED:
			grounded_tick(delta)
		STATES.AIRBORNE:
			airborne_tick(delta)
		STATES.INACTIVE:
			visible = false
			position = Vector2(-100, -100)
'''
Returns a state to transition to on this frame
'''
func state_transition():
	match state:
		STATES.AIRBORNE:
			if is_on_floor():
				return STATES.GROUNDED
			if not active:
				return STATES.INACTIVE
		STATES.GROUNDED:
			if not is_on_floor():
				return STATES.AIRBORNE
			if not active:
				return STATES.INACTIVE
		STATES.INACTIVE:
			if active:
				return STATES.GROUNDED
	return null

func throw(angle):
	active = true
	change_state(STATES.AIRBORNE)
	position = tetherpoint.position
	var throwvector = Vector2.UP.rotated(angle)
	velocity = throwvector * THROWFORCE
	position += throwvector * 100

func die():
	
	emit_signal("PLAYERDIED")
	#TODO Respawn

func take_damage():
	if invincibility <= 0:
		invincibility = INVINCIBILITY_FRAMES
		health -= 1
		print(health)
		if health <= 0:
			die()

func rope_pickup():
	tetherlength += 50
