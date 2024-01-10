extends Construct

enum STATES {AIRBORNE, GROUNDED, DORMANT, AWAKE}

var rope_bridge: StaticBody2D
var rope_bridge_scene: PackedScene = preload("res://Objects/rope_bridge.tscn")

func _ready():
	MOVESPEED = 360
	JUMP_HEIGHT = 130
	TIME_TO_PEAK = 0.5
	GRAVITY = 2.0 * JUMP_HEIGHT / pow(TIME_TO_PEAK, 2)
	JUMPFORCE = 2.0 * JUMP_HEIGHT / TIME_TO_PEAK
	state = STATES.GROUNDED
	
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
		STATES.DORMANT:
			dormant_tick(delta)

func dormant_tick(delta):
	pass

func grounded_tick(delta):
	var dir = 0
	if Input.is_action_pressed("Left"):
		dir = -1
	elif Input.is_action_pressed("Right"):
		dir = 1
	if Input.is_action_just_pressed("Up"):
		velocity.y = -JUMPFORCE
	if Input.is_action_just_pressed("Down") and dir != 0:
		create_rope_bridge(dir)
	velocity.x = lerp(velocity.x, float(MOVESPEED * dir), 0.3)
	move_and_slide()

func create_rope_bridge(dir):
	if rope_bridge:
		rope_bridge.queue_free()
	rope_bridge = rope_bridge_scene.instantiate()
	get_parent().add_child(rope_bridge)
	rope_bridge.position = position
	rope_bridge.position.x = position.x + 50 * dir
	rope_bridge.scale.x = 10

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
	
	return null
