class_name Player
extends CharacterBody2D
# Things to modify
var MOVESPEED = 450.0
var PULLFORCE = 0.5
var JUMP_HEIGHT: float = 138
var TIME_TO_PEAK: float = 0.5
var THROWFORCE = 1300.0
var INVINCIBILITY_FRAMES = 90
var tetherlength = 8
var reelmax = tetherlength * 64
var reellength = reelmax
var reelspeed = 3
var health = 80
var maxhealth = 2
var invincibility = 0
var clapcooldown = 60
var coyotetime = 0
var thrown = 0
var THROWN_FRAMES = 400000
var PUSH_FORCE = 100.0
var jumpbuffer = 0
var JUMP_BUFFER_FRAMES = 10
var respawnpos: Vector2
var switchnearby: Switch = null



# Control Vars
var interact = "Down"

@onready var collision= $BodyCollider
@onready var ropeattach = $RopeAttachPoint
@onready var clapsound = $Clapper
@onready var jumpsound = $Jump
@onready var switchsound = $Switch
@onready var somersaultsound = $Somersault
@onready var pickupsound = $Pickup
@onready var pullstop = $PullStopRay

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
var hud_scene: PackedScene = preload("res://Scenes/hud.tscn")
var state = STATES.GROUNDED
var active = true


enum STATES {AIRBORNE, GROUNDED, INACTIVE}

signal PLAYERDIED
signal PLAYERDAMAGED

var tetherpoint: RopeConstruct
var camera: PlayerCam
var hud: HUD

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
	camera.position = position
	camera.construct = tetherpoint
	hud = hud_scene.instantiate()
	get_parent().add_child.call_deferred(hud)
	
'''
Runs once every frame (60fps)
'''
func _physics_process(delta):
	if Input.is_action_just_pressed("Reset"):
		die()
	state_tick(delta)
	var transition = state_transition()
	if transition != null:
		change_state(transition)
	animator(delta)
	if facing == true:
		transform.x.x = -1
	else:
		transform.x.x = 1
	_pullstop()

'''
Grounded state tick function
'''
func grounded_tick(delta):
	var dir = 0
	thrown = 0
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
	if Input.is_action_just_pressed("Down") and switchnearby:
		switchnearby.switch()
		switchsound.play()
		
	if Input.is_action_just_pressed("Up") or jumpbuffer > 0:
		velocity.y = -JUMPFORCE
		jumpsound.play()
		jumpbuffer = 0
		coyotetime = 0
	velocity.x = lerp(velocity.x, float(MOVESPEED * dir), 0.3)
	var tethervector = tetherpoint.position - position
	if (tethervector.length() > reellength + 20):
		position += tethervector.normalized() * (tethervector.length() - reellength - 20)
	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is PushBox:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)


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
	if Input.is_action_just_pressed("Up"):
		if coyotetime > 0:
			coyotetime = 0
			velocity.y = -JUMPFORCE
			jumpsound.play()
		else:
			jumpbuffer = JUMP_BUFFER_FRAMES
		
	if Input.is_action_just_pressed("Down"):
		pass
	if Input.is_action_pressed("ReelIn"):
		if reellength <= reelmax:
			reellength -= reelspeed
	if Input.is_action_pressed("ReelOut"):
		if reellength <= reelmax:
			reellength += reelspeed
	if reellength > reelmax:
		reellength = reelmax
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
	if (dotproduct < 0 and tethervector.length() > reellength):
		var multiplier = 1
		if dotproduct < -300:
			multiplier = 1.5
		velocity += -dotproduct * tethervector.normalized() * multiplier
	if (tethervector.length() > reellength + 20):
		position += tethervector.normalized() * (tethervector.length() - reellength - 20)
	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is PushBox:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)
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
		STATES.AIRBORNE:
			if not Input.is_action_pressed("Left") and not Input.is_action_pressed("Right"):
				velocity.x = 0
			reellength = reelmax

'''
Runs when a new state is entered
'''
func enter_state(newstate) -> void:
	pass

'''
Runs per frame state logic
'''
func state_tick(delta) -> void:
	if jumpbuffer > 0:
		jumpbuffer -= 1
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
	position = tetherpoint.position + Vector2.UP * 50
	var throwvector = Vector2.UP.rotated(angle)
	velocity = throwvector * THROWFORCE * (tetherlength * 64 / 500.0)

func die():
	get_tree().reload_current_scene.call_deferred()
	#TODO Respawn

func take_damage():
	
	#TODO add direction the player took damage from, send away from source and set `hurtdir` appropriately. remove player control while in hurtframes.
	hurtdir = 0
	if invincibility <= 0:
		hurtframe = 30
		invincibility = INVINCIBILITY_FRAMES
		health -= 1
		GlobalSignalBus.player_damaged()
		if health <= 0:
			die()

func rope_pickup():
	tetherlength += 2
	reelmax = tetherlength * 64
	pickupsound.play()

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
		if thrown > 0:
			groupbody = "Thrown"
			if not somersaultsound.playing:
				somersaultsound.play()
			if facing == true:
				spritebody.rotation -= 1
			else:
				spritebody.rotation += 1
	if state == STATES.GROUNDED:
		if Input.is_action_just_pressed(interact) and not switchnearby:
			if clapcooldown == 0 && cangrab == false && !isgrabbing:
				clapcooldown = 35 / animspeed
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
			if clapcooldown == 15 / animspeed:
				tetherpoint.clap()
				clapsound.play()
				
			if spritearms.animation == "Clap" && spritearms.frame == 5:
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
		grouparms = ""
		spritehead.frame = hurtdir
		spritebody.frame = hurtdir
		spritelegs.frame = hurtdir
	if thrown == 0:
		spritebody.rotation = 0
		somersaultsound.stop()

	play_if_valid(spritehead, groupbody, animspeed)
	play_if_valid(spritebody, groupbody, animspeed)
	play_if_valid(spritelegs, groupbody, animspeed)
	play_if_valid(spritearms, grouparms, animspeed)
	play_if_valid(spritearma, grouparms, animspeed)
	play_if_valid(spritearmb, grouparms, animspeed)

# TODO Eventual "Mount the Construct" function.
func mount():
	# timer and physics to move the player up to the mount spot
	# puff of smoke effect over the mount spot to hide the player disappearing
		# make player inactive, change state on construct from Dormant to Grounded
	pass
	
func play_if_valid(sprite: AnimatedSprite2D, animation: String, animspeed):
	if sprite.sprite_frames.has_animation(animation):
		sprite.visible = true
		sprite.play(animation, animspeed)
	else:
		sprite.visible = false

func dismount():
	active = true
	change_state(STATES.AIRBORNE)
	position = tetherpoint.position
	var throwvector = Vector2.UP
	position += throwvector * 120

func _draw():
	if active:
		draw_line(to_local(ropeattach.global_position), to_local(tetherpoint.global_position), Color(0.46, 0.16, 0.0), 5)

func _pullstop():
	var pullstopmax = 22
	pullstop.target_position = Vector2(tetherpoint.position)
	pullstop.exclude_parent = true
	var temp = pullstop.get_collision_point()
	print(temp)
	draw_line(position, temp, Color(0.2, 0, 0, 1))
	var temp2 = tetherpoint.position
	print(temp2)
