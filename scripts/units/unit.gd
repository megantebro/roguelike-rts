class_name Unit
extends Area2D

signal unit_selected(unit)

@export var hp_max: float = 100.0
@export var atk: float = 10.0
@export var atk_range: float = 180.0
@export var atk_interval: float = 1.0
@export var move_speed: float = 100.0
@export var sight: float = 220.0
@export var radius: float = 24.0
@export var body_size: float = 48.0
@export var unit_color: Color = Color(0.2, 0.6, 1.0)
@export var texture: Texture2D = null

var hp: float
var selected := false
var _target: Vector2
var _atk_cooldown := 0.0

func _ready() -> void:
	hp = hp_max
	_target = position

func _process(delta: float) -> void:
	if position.distance_to(_target) > 1.0:
		position = position.move_toward(_target, move_speed * delta)
		queue_redraw()
	if _atk_cooldown > 0.0:
		_atk_cooldown -= delta

func _draw() -> void:
	var half := body_size / 2.0
	var rect := Rect2(-half, -half, body_size, body_size)
	if texture != null:
		draw_texture_rect(texture, rect, false, unit_color)
	else:
		draw_rect(rect, unit_color)
	if selected:
		draw_rect(rect, Color.WHITE, false, 2.0)

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

func can_attack() -> bool:
	return _atk_cooldown <= 0.0

func attack(target: Node) -> void:
	if not can_attack():
		return
	_atk_cooldown = atk_interval
	if target.has_method("take_damage"):
		target.take_damage(atk)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		die()

func die() -> void:
	queue_free()
