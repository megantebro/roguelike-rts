extends Node2D

var main_node: Main = null

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if main_node == null:
		return
	var pending: int = main_node._pending_claim_idx
	if pending < 0 or main_node._build_progress <= 0.0:
		return
	var ppos: Vector2 = main_node._resource_positions[pending]
	var bar_w := 36.0
	var bar_h := 5.0
	var bx := ppos.x - bar_w / 2.0
	var by := ppos.y - 23.0
	var fill := main_node._build_progress / main_node.BUILD_TIME
	draw_rect(Rect2(bx, by, bar_w, bar_h), Color(0.05, 0.08, 0.15, 0.9))
	draw_rect(Rect2(bx, by, bar_w * fill, bar_h), Color(0.0, 1.0, 0.25))
	draw_rect(Rect2(bx, by, bar_w, bar_h), Color(0.3, 0.5, 0.8, 0.6), false, 1.0)
