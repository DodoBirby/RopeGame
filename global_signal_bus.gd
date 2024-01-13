extends Node
signal camerashake(strength)
signal PLAYERDAMAGED
signal PLAYERDIED

func shake_camera(strength):
	emit_signal("camerashake", strength)

func player_damaged():
	emit_signal("PLAYERDAMAGED")

