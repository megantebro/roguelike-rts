extends Node2D

var active := false
var _start := Vector2.ZERO
var _end := Vector2.ZERO

func _draw() -> void:
	if not active:
		return
	var rect := Rect2(_start, _end - _start).abs()
	draw_rect(rect, Color(0.3, 0.7, 1.0, 0.12))
	draw_rect(rect, Color(0.4, 0.8, 1.0, 0.9), false, 1.5)

func begin(pos: Vector2) -> void:
	active = true
	_start = pos
	_end = pos
	queue_redraw()

func update_pos(pos: Vector2) -> void:
	_end = pos
	queue_redraw()

func stop() -> Rect2:
	var r := Rect2(_start, _end - _start).abs()
	active = false
	queue_redraw()
	return r
