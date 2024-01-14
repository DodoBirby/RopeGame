extends Node
signal camerashake(strength)
signal PLAYERDAMAGED
signal PLAYERDIED
signal cameralimits(rect)


func shake_camera(strength):
	emit_signal("camerashake", strength)

func player_damaged():
	emit_signal("PLAYERDAMAGED")

func cameralimitset(rect: Rect2):
	emit_signal("cameralimits", rect)

func player_died():
	emit_signal("PLAYERDIED")
