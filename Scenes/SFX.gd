extends HSlider

@onready var _bus = AudioServer.get_bus_index("SFX")

func _ready():
	value = MusicController.sound_volume

func _on_value_changed(value):
	MusicController.sound_volume = value
	AudioServer.set_bus_volume_db(_bus, linear_to_db(value))
