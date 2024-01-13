class_name PlayerCam
extends Camera2D

var player: Player
var construct: RopeConstruct

var viewport_rect: Rect2
var MAXZOOM: float = 1
var MARGIN = 400
var current_zoom: float

# Camera shake
var RANDOM_STRENGTH = 30.0
var SHAKE_FADE = 5.0

var rng = RandomNumberGenerator.new()

var shake_strength = 0.0


func _ready():
	enabled = true
	viewport_rect = get_viewport_rect()
	GlobalSignalBus.PLAYERDAMAGED.connect(shake)
	GlobalSignalBus.camerashake.connect(shake_with_strength)
	
func _process(delta):
	
	if not player or not construct:
		return
	var center = Vector2.ZERO
	center.x = (player.position.x + construct.position.x) / 2
	center.y = (player.position.y + construct.position.y) / 2
	position = center
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, SHAKE_FADE * delta)
		offset = randomoffset()
	else:
		offset = Vector2.ZERO
	var camera_rect = Rect2(player.position.x, player.position.y, 0, 0)
	camera_rect = camera_rect.expand(construct.position)
	camera_rect = camera_rect.grow(MARGIN)
	var scale_factor_x: float = viewport_rect.size.x / camera_rect.size.x
	var scale_factor_y: float = viewport_rect.size.y / camera_rect.size.y
	var scale_factor: float = min(scale_factor_x, scale_factor_y)
	current_zoom = lerp(current_zoom, min(scale_factor, MAXZOOM), 0.5)
	zoom.x = current_zoom
	zoom.y = current_zoom
	
func shake():
	shake_strength = RANDOM_STRENGTH

func shake_with_strength(strength):
	shake_strength = strength

func randomoffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
