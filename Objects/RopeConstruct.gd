class_name RopeConstruct
extends Construct
#TODO Add coyote and jump buffer

enum STATES {AIRBORNE, GROUNDED, DORMANT}

var player: Player
var awake = false
var prevdir = -1
var colliding = false
var coyotetime = 0
var jumpbuffer = 0

@onready var collider = $StandingCollider
@onready var throwsound = $Throw
@onready var footstepsound = $Footstep

#Animator
@onready var pack = $CompositeSprite/ConsBackpack
@onready var body = $CompositeSprite/ConsBody
@onready var leg = $CompositeSprite/ConsLeg
@onready var mounted = $CompositeSprite/ConsMounted
var animationgroup = "Idle"
var running = false
var animspeed = 2
var facing = true
var throwtimer = 0
var sleeptimer = 0
var awaketimer = 0

@onready var NoClapBox = $NoClapBox
@onready var NoMountBox = $NoMountBox

var PUSH_FORCE = 100.0

func _ready():
	# Ok to touch
	MOVESPEED = 360
	JUMP_HEIGHT = 70
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
			collider.shape.size.y = 132
			collider.position.y = -3
		STATES.AIRBORNE:
			GlobalSignalBus.shake_camera(10)
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
	animator(delta)
	if throwtimer > 0:
		throwtimer -= 1
	if awaketimer > 0:
		awaketimer -= 1
	if sleeptimer > 0:
		sleeptimer -= 1

func dormant_tick(delta):
	for body in NoMountBox.get_overlapping_bodies():
		if body is TileMap:
			position.y -= 64
	if awaketimer <= 0:
		velocity.x = 0
		velocity.y += GRAVITY * delta
		if awake:
			set_collision_layer_value(2, false)
			set_collision_mask_value(6, false)
			modulate = Color(1, 1, 1)
			collider.shape.size.y = 132
			collider.position.y = -3
			if colliding and Input.is_action_just_pressed("Up") and not NoMountBox.has_overlapping_bodies():
				player.active = false
				player.visible = false
				change_state(STATES.GROUNDED)
		else:
			set_collision_layer_value(2, true)
			set_collision_mask_value(6, true)
			collider.shape.size.y = 108
			collider.position.y = 9
		move_and_slide()
		for i in get_slide_collision_count():
			var c = get_slide_collision(i)
			var collider = c.get_collider()
			if collider is PushBox:
				c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)
			if collider is Enemy and c.get_normal() == Vector2.UP:
				collider.take_damage()
				

func grounded_tick(delta):
	var dir = 0
	coyotetime = 8
	if Input.is_action_pressed("Left") and not throwtimer > 0:
		dir = -1
		prevdir = -1
		running = true
		facing = true
	elif Input.is_action_pressed("Right") and not throwtimer > 0:
		dir = 1
		prevdir = 1
		running = true
		facing = false
	else:
		running = false
	if Input.is_action_just_pressed("Up") or jumpbuffer > 0:
		velocity.y = -JUMPFORCE
		coyotetime = 0
		jumpbuffer = 0
	if Input.is_action_just_pressed("Down"):
		player.dismount()
		awake = false
		change_state(STATES.DORMANT)
		sleeptimer = 40
	if Input.is_action_just_pressed("Throw"):
		throwtimer = 12
	if throwtimer == 1:
		throwsound.play()
		player.throw(prevdir * PI / 4)
		awake = false
		change_state(STATES.DORMANT)
		sleeptimer = 40
	velocity.x = lerp(velocity.x, float(MOVESPEED * dir), 0.5)
	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is PushBox:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)
		if collider is Enemy and c.get_normal() == Vector2.UP:
			collider.take_damage()

func airborne_tick(delta):
	var dir = 0
	if Input.is_action_pressed("Left"):
		dir = -1
		prevdir = -1
		facing = true
	elif Input.is_action_pressed("Right"):
		dir = 1
		prevdir = 1
		facing = false
	if Input.is_action_just_pressed("Up"):
		if coyotetime > 0:
			velocity.y = -JUMPFORCE
			coyotetime = 0
		else:
			jumpbuffer = 10
	velocity.x = lerp(velocity.x, float(MOVESPEED * dir), 0.5)
	velocity.y += GRAVITY * delta
	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is PushBox:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)
		if collider is Enemy and c.get_normal() == Vector2.UP:
			collider.take_damage()
	if coyotetime > 0:
		coyotetime -= 1
	if jumpbuffer > 0:
		jumpbuffer -= 1
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
		
		if awake:
			sleeptimer = 40
		else:
			awaketimer = 45
		awake = !awake
		print("Calling func clap()")

func take_damage():
	if state != STATES.DORMANT:
		player.dismount()
		awake = false
		change_state(STATES.DORMANT)
		sleeptimer = 40 / animspeed

func _on_pickup_box_body_entered(body):
	if body is Player:
		colliding = true


func _on_pickup_box_body_exited(body):
	if body is Player:
		colliding = false

func animator(delta):
	mounted.z_index = 0
	if state == STATES.DORMANT:
		mounted.visible = false
		running = false
		if awake:
			animationgroup = "Idle"
			if awaketimer > 0:
				animationgroup = "Awaken"
		elif throwtimer == 1:
			animationgroup = "Sleep"
			body.frame = 3
			sleeptimer = 24
			print("Hello")
		else:
			animationgroup = "Dormant"
		if sleeptimer > 0:
			animationgroup = "Sleep"
	elif state == STATES.AIRBORNE:
			animationgroup = "Jump"
			if body.frame == 3:
				body.frame = 3
				mounted.frame = 3
				pack.frame = 3
	elif state == STATES.GROUNDED:
		if running:
			animationgroup = "Run"
		else: 
			animationgroup = "Idle"
		if throwtimer > 0:
			animationgroup = "Throw"
			mounted.z_index = 3
	if animationgroup == "Idle":
		animspeed = 1
	else:
		animspeed = 2
	if state != STATES.DORMANT:
		mounted.visible = true
		play_if_valid(mounted, animationgroup, animspeed)
	play_if_valid(pack, animationgroup, animspeed)
	play_if_valid(body, animationgroup, animspeed)
	play_if_valid(leg, animationgroup, animspeed)
	pack.flip_h = facing
	body.flip_h = facing
	leg.flip_h = facing
	mounted.flip_h = facing

#Yoink
func play_if_valid(sprite: AnimatedSprite2D, animation: String, animspeed):
	if sprite.sprite_frames.has_animation(animation):
		sprite.visible = true
		sprite.play(animation, animspeed)
	else: 
		sprite.visible = false


func _on_cons_body_frame_changed():
	if body.frame == 0 or body.frame == 4:
		if animationgroup == "Run":
			footstepsound.play()
