extends TileMap


func _ready():
	var tilerect = get_used_rect()
	tilerect.size *= 64
	tilerect.position *= 64
	GlobalSignalBus.cameralimitset.call_deferred(tilerect)
	
