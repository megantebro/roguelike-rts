extends Control

var is_locked: bool = false

func _draw() -> void:
	var c := size / 2.0
	var a := 0.4 if is_locked else 1.0
	draw_circle(c, 18.0, Color(0.0, 1.0, 0.25, a))
	draw_arc(c, 24.0, 0.0, TAU, 32, Color(0.2, 0.5, 1.0, a), 3.0)
