extends Node
signal camerashake(strength)
signal PLAYERDAMAGED(newhealth)
signal PLAYERDIED
signal cameralimits(rect)


func shake_camera(strength):
	emit_signal("camerashake", strength)

func player_damaged(newhealth):
	emit_signal("PLAYERDAMAGED", newhealth)

func cameralimitset(rect: Rect2):
	emit_signal("cameralimits", rect)

func player_died():
	emit_signal("PLAYERDIED")
