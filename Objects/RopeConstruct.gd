class_name RopeConstruct
extends Construct

enum STATES {AIRBORNE, GROUNDED, DORMANT}

var player: Player
var awake = false
var prevdir = -1
var colliding = false

@onready var NoClapBox = $NoClapBox
@onready var NoMountBox = $NoMountBox

var PUSH_FORCE = 100.0

func _ready():
	# Ok to touch
	MOVESPEED = 360
	JUMP_HEIGHT = 60
	TIME_TO_PEAK = 0.2
	
	# Don't touch
	GRAVITY = 2.0 * JUMP_HEIGHT / pow(TIME_TO_PEAK, 2)
	JUMPFORCE = 2.0 * JUMP_HEIGHT / TIME_TO_PEAK
	
	# Initial state
	state = STATES.DORMANT
	
'''
Runs when a state is exited
'''
func exit_state(oldstate) -> void:
	match oldstate:
		STATES.DORMANT:
			set_collision_layer_value(2, true)
			set_collision_mask_value(6, true)
			modulate = Color(1, 1, 1)

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
	velocity.x = 0
	velocity.y += GRAVITY * delta
	if awake:
		set_collision_layer_value(2, false)
		set_collision_mask_value(6, false)
		modulate = Color(1, 1, 1)
		if colliding and Input.is_action_just_pressed("Up") and not NoMountBox.has_overlapping_bodies():
			player.active = false
			change_state(STATES.GROUNDED)
	else:
		set_collision_layer_value(2, true)
		set_collision_mask_value(6, true)
		modulate = Color(0, 0, 0)
	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is PushBox:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)

func grounded_tick(delta):
	var dir = 0
	if Input.is_action_pressed("Left"):
		dir = -1
		prevdir = -1
	elif Input.is_action_pressed("Right"):
		dir = 1
		prevdir = 1
	if Input.is_action_just_pressed("Up"):
		velocity.y = -JUMPFORCE
	if Input.is_action_just_pressed("Throw"):
		player.throw(prevdir * PI / 4)
		awake = false
		change_state(STATES.DORMANT)
	
	velocity.x = lerp(velocity.x, float(MOVESPEED * dir), 0.5)
	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is PushBox:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)


func airborne_tick(delta):
	var dir = 0
	var gravmultiplier = 1
	if Input.is_action_pressed("Left"):
		dir = -1
		prevdir = -1
	elif Input.is_action_pressed("Right"):
		dir = 1
		prevdir = 1
	if not Input.is_action_pressed("Up"):
		gravmultiplier = 3
	velocity.x = lerp(velocity.x, float(MOVESPEED * dir), 0.5)
	velocity.y += GRAVITY * delta * gravmultiplier
	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is PushBox:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)

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

func clap():
	if not NoClapBox.has_overlapping_bodies():
		awake = !awake
		print("Calling func clap()")
		


func _on_pickup_box_body_entered(body):
	if body is Player:
		colliding = true


func _on_pickup_box_body_exited(body):
	if body is Player:
		colliding = false
