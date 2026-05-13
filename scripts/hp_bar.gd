class_name HpBar
extends Node2D

var bar_width    := 36.0
var bar_height   := 5.0
var fill         := 0.0
var bg_color     := Color(0.05, 0.08, 0.15, 0.9)
var fill_color   := Color(0.0, 1.0, 0.25)
var border_color := Color(0.3, 0.5, 0.8, 0.6)

func _draw() -> void:
	var bx := -bar_width / 2.0
	draw_rect(Rect2(bx, 0, bar_width, bar_height), bg_color)
	draw_rect(Rect2(bx, 0, bar_width * fill, bar_height), fill_color)
	if border_color.a > 0.0:
		draw_rect(Rect2(bx, 0, bar_width, bar_height), border_color, false, 1.0)
