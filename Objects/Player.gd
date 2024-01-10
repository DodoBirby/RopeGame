class_name Player
extends CharacterBody2D
var MOVESPEED = 360
var PULLFORCE = 0.5
var JUMP_HEIGHT: float = 130
var TIME_TO_PEAK: float = 0.5

var GRAVITY = 2.0 * JUMP_HEIGHT / pow(TIME_TO_PEAK, 2)
var JUMPFORCE = 2.0 * JUMP_HEIGHT / TIME_TO_PEAK

var state = STATES.GROUNDED

enum STATES {AIRBORNE, GROUNDED, TETHERED}

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
	velocity.x = lerp(velocity.x, float(MOVESPEED * dir), 0.3)
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
	velocity.x = lerp(velocity.x, float(MOVESPEED * dir), 0.3)
	velocity.y += GRAVITY * delta * gravmultiplier
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
	pass

'''
Runs when a new state is entered
'''
func enter_state(newstate) -> void:
	pass

'''
Runs per frame state logic
'''
func state_tick(delta) -> void:
	match state:
		STATES.GROUNDED:
			grounded_tick(delta)
		STATES.AIRBORNE:
			airborne_tick(delta)

'''
Returns a state to transition to on this frame
'''
func state_transition():
	match state:
		STATES.AIRBORNE:
			if is_on_floor():
				return STATES.GROUNDED
		STATES.GROUNDED:
			if not is_on_floor():
				return STATES.AIRBORNE
		STATES.TETHERED:
			pass
	return null
