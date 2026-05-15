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
var hovered := false
var is_commander := false
var _target: Vector2
var _atk_cooldown := 0.0

func _ready() -> void:
	hp = hp_max
	_target = position
	mouse_entered.connect(func(): hovered = true; queue_redraw())
	mouse_exited.connect(func(): hovered = false; queue_redraw())

func _process(delta: float) -> void:
	if position.distance_to(_target) > 1.0:
		position = position.move_toward(_target, move_speed * delta)
		queue_redraw()
	var half := body_size / 2.0
	position = position.clamp(Vector2(half, half), _MAP_SIZE - Vector2(half, half))
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
	elif hovered:
		draw_rect(rect, Color(1, 1, 1, 0.5), false, 2.0)

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

const _MAP_SIZE := Vector2(150 * 64, 150 * 64)

func move_to(pos: Vector2) -> void:
	var half := body_size / 2.0
	_target = pos.clamp(Vector2(half, half), _MAP_SIZE - Vector2(half, half))

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
