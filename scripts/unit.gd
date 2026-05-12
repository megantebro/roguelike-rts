extends Area2D

signal unit_selected(unit)

@export var unit_color: Color = Color(0.2, 0.6, 1.0)

const SIZE := 48
const SPEED := 300.0

var selected := false
var _target: Vector2

func _ready() -> void:
	_target = position

func _process(delta: float) -> void:
	if position.distance_to(_target) > 1.0:
		position = position.move_toward(_target, SPEED * delta)
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-SIZE / 2.0, -SIZE / 2.0, SIZE, SIZE), unit_color)
	var border_color := Color.WHITE if selected else Color.BLACK
	draw_rect(Rect2(-SIZE / 2.0, -SIZE / 2.0, SIZE, SIZE), border_color, false, 2.0)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		unit_selected.emit(self)
		get_viewport().set_input_as_handled()

func select() -> void:
	selected = true
	queue_redraw()

func deselect() -> void:
	selected = false
	queue_redraw()

func move_to(pos: Vector2) -> void:
	_target = pos
