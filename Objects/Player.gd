class_name Player
extends CharacterBody2D
# Things to modify
var MOVESPEED = 450.0
var PULLFORCE = 0.5
var JUMP_HEIGHT: float = 130
var TIME_TO_PEAK: float = 0.5
var THROWFORCE = 1300.0
var INVINCIBILITY_FRAMES = 150
var tetherlength = 500.0
var health = 99
var maxhealth = 2
var invincibility = 0
var clapcooldown = 60
var coyotetime = 0
var thrown = 0
var THROWN_FRAMES = 10

# Control Vars
var interact = "Down"

@onready var collision= $BodyCollider
@onready var ropeattach = $RopeAttachPoint


# Animator vars
@onready var spritecontroller = $SpriteController
@onready var spritehead = $SpriteController/Head
@onready var spritebody = $SpriteController/Torso
@onready var spritelegs = $SpriteController/Legs
@onready var spritearms = $SpriteController/BodyArm
@onready var spritearmb = $SpriteController/BackgroundArm
@onready var spritearma = $SpriteController/ForegroundArm
var groupbody = &"Idle"
var grouparms = &"Idle" 
var facing = false
var cangrab = false
var idle = true
var animspeed = 3
var isclapping = false
var isgrabbing = false
var hurtframe = 0
var hurtdir = 1

# Don't touch these, these are controlled by JUMP_HEIGHT and TIME_TO_PEAK above
var GRAVITY = 2.0 * JUMP_HEIGHT / pow(TIME_TO_PEAK, 2)
var JUMPFORCE = 2.0 * JUMP_HEIGHT / TIME_TO_PEAK

var construct_scene: PackedScene = preload("res://Objects/RopeConstruct.tscn")
var camera_scene: PackedScene = preload("res://Objects/player_camera.tscn")
var state = STATES.GROUNDED
var active = true


enum STATES {AIRBORNE, GROUNDED, INACTIVE}

signal PLAYERDIED
signal PLAYERDAMAGED

var tetherpoint: RopeConstruct
var camera: PlayerCam

func _process(delta):
	queue_redraw()

func _ready():
	tetherpoint = construct_scene.instantiate()
	get_parent().add_child.call_deferred(tetherpoint)
	tetherpoint.position = position
	tetherpoint.player = self
	camera = camera_scene.instantiate()
	get_parent().add_child.call_deferred(camera)
	camera.player = self
	camera.construct = tetherpoint
'''
Runs once every frame (60fps)
'''
func _physics_process(delta):
	state_tick(delta)
	var transition = state_transition()
	if transition != null:
		change_state(transition)
	animator(delta)

'''
Grounded state tick function
'''
func grounded_tick(delta):
	var dir = 0
	coyotetime = 8
	if Input.is_action_pressed("Left"):
		dir = -1
		facing = true
		idle = false
	elif Input.is_action_pressed("Right"):
		dir = 1
		facing = false
		idle = false
	else:
		idle = true
	if Input.is_action_just_pressed("Up"):
		velocity.y = -JUMPFORCE
		coyotetime = 0
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
		facing = true
	elif Input.is_action_pressed("Right"):
		dir = 1
		facing = false
	if not Input.is_action_pressed("Up"):
		gravmultiplier = 3
	elif coyotetime > 0:
		velocity.y = -JUMPFORCE
	if Input.is_action_just_pressed("Down"):
		pass
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
	if coyotetime > 0:
		coyotetime -= 1
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
			collision.disabled = false
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
	if thrown > 0:
		thrown -= 1
	match state:
		STATES.GROUNDED:
			grounded_tick(delta)
		STATES.AIRBORNE:
			airborne_tick(delta)
		STATES.INACTIVE:
			collision.disabled = true
			visible = false
			position = tetherpoint.position
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
	thrown = THROWN_FRAMES
	active = true
	change_state(STATES.AIRBORNE)
	position = tetherpoint.position
	var throwvector = Vector2.UP.rotated(angle)
	velocity = throwvector * THROWFORCE * (tetherlength / 500.0)
	position += throwvector * 100

func die():
	
	emit_signal("PLAYERDIED")
	#TODO Respawn

func take_damage():
	
	#TODO add direction the player took damage from, send away from source and set `hurtdir` appropriately. remove player control while in hurtframes.
	hurtdir = 0
	if invincibility <= 0:
		hurtframe = 30
		invincibility = INVINCIBILITY_FRAMES
		health -= 1
		emit_signal("PLAYERDAMAGED")
		print(health)
		if health <= 0:
			die()

func rope_pickup():
	tetherlength += 100

# Xander's Insane animator function

func animator(delta):
	if clapcooldown > 0:
		clapcooldown -= 1
	
	if state == STATES.AIRBORNE:
		groupbody = "Jump"
		grouparms = "Jump"
		if isclapping:
			isclapping = false
		
		if spritebody.frame == 4:
			spritehead.frame = 4
			spritebody.frame = 4
			spritelegs.frame = 4
			spritearms.frame = 4
		
	if state == STATES.GROUNDED:
		if Input.is_action_just_pressed(interact):
			if clapcooldown == 0 && cangrab == false && !isgrabbing:
				clapcooldown = 15 * animspeed
				isclapping = true
			
		if idle == true:
			grouparms = "Idle"
			groupbody = "Idle"
		else:
			if Input.is_action_pressed("Left") || Input.is_action_pressed("Right"):
				groupbody = "Run"
				grouparms = "Run"
			
		if isclapping:
			grouparms = "Clap"
			if clapcooldown == 8 * animspeed:
				tetherpoint.clap()
				
			if spritearms.animation == "Clap" && spritearms.frame == 8:
				isclapping = false
			
		if isgrabbing:
			grouparms = "Grab"
			if spritearms.frame == 4:
				spritearms.frame = 4
				spritearma.frame = 4 
	spritecontroller.modulate = Color(1.0, 1.0, 1.0, 1.0) #Reset player transparency
	if invincibility > 0:
		spritecontroller.modulate = Color(1.0, 1.0, 1.0, 0.5) #Make player transparent when invincible
	if hurtframe > 0:
		
		hurtframe -= 1
		groupbody = "Hurt"
		grouparms = "Void"
		spritehead.frame = hurtdir
		spritebody.frame = hurtdir
		spritelegs.frame = hurtdir
	
	play_if_valid(spritehead, groupbody, animspeed)
	play_if_valid(spritebody, groupbody, animspeed)
	play_if_valid(spritelegs, groupbody, animspeed)
	play_if_valid(spritearms, grouparms, animspeed)
	play_if_valid(spritearma, grouparms, animspeed)
	play_if_valid(spritearmb, grouparms, animspeed)
	
	spritehead.flip_h = facing
	spritebody.flip_h = facing
	spritelegs.flip_h = facing
	spritearma.flip_h = facing
	spritearmb.flip_h = facing
	spritearms.flip_h = facing

# TODO Eventual "Mount the Construct" function.
func mount():
	# timer and physics to move the player up to the mount spot
	# puff of smoke effect over the mount spot to hide the player disappearing
		# make player inactive, change state on construct from Dormant to Grounded
	pass
	
func play_if_valid(sprite: AnimatedSprite2D, animation: String, animspeed):
	if sprite.sprite_frames.has_animation(animation):
		sprite.play(animation, animspeed)

func _draw():
	if active:
		draw_line(to_local(ropeattach.global_position), to_local(tetherpoint.global_position), Color(0.46, 0.16, 0.64), 5)
