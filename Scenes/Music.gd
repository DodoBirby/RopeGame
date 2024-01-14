extends HSlider

@onready var _bus = AudioServer.get_bus_index("Music")

func _ready():
	value = MusicController.music_volume

func _on_value_changed(value):
	MusicController.music_volume = value
	AudioServer.set_bus_volume_db(_bus, linear_to_db(value))
