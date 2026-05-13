extends Area2D

signal unit_selected(unit)

@export var unit_color: Color = Color(0.2, 0.6, 1.0)

const SIZE := 48
const SPEED := 300.0

var selected := false
var _target: Vector2

var _texture: Texture2D = preload("res://icon/commander.png")

func _ready() -> void:
	_target = position

func _process(delta: float) -> void:
	if position.distance_to(_target) > 1.0:
		position = position.move_toward(_target, SPEED * delta)
		queue_redraw()

func _draw() -> void:
	var half := SIZE / 2.0
	draw_texture_rect(_texture, Rect2(-half, -half, SIZE, SIZE), false, unit_color)
	if selected:
		draw_rect(Rect2(-half, -half, SIZE, SIZE), Color.WHITE, false, 2.0)

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
