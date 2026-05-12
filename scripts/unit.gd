extends Node2D

@export var unit_color: Color = Color(0.2, 0.6, 1.0)

const SIZE := 48

func _draw() -> void:
	draw_rect(Rect2(-SIZE / 2.0, -SIZE / 2.0, SIZE, SIZE), unit_color)
	draw_rect(Rect2(-SIZE / 2.0, -SIZE / 2.0, SIZE, SIZE), Color.WHITE, false, 2.0)
