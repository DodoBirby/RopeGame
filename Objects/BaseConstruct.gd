class_name Construct
extends CharacterBody2D

var MOVESPEED = 360
var PULLFORCE = 0.5
var JUMP_HEIGHT: float = 130
var TIME_TO_PEAK: float = 0.5

var GRAVITY = 2.0 * JUMP_HEIGHT / pow(TIME_TO_PEAK, 2)
var JUMPFORCE = 2.0 * JUMP_HEIGHT / TIME_TO_PEAK

var state

'''
Runs once every frame (60fps)
'''
func _physics_process(delta):
	state_tick(delta)
	var transition = state_transition()
	if transition != null:
		change_state(transition)

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
	pass

'''
Returns a state to transition to on this frame
'''
func state_transition():
	return null
