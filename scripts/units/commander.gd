class_name Commander
extends Unit

func _init() -> void:
	is_commander = true
	hp_max = 5000.0
	atk = 80.0
	atk_range = 250.0
	atk_interval = 1.0
	move_speed = 80.0
	sight = 300.0
	radius = 24.0
	body_size = 48.0
	unit_color = Color(0.2, 0.5, 1.0)
	texture = preload("res://icon/commander.png")
