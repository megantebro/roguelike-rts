extends Camera2D

const TILE_SIZE := 64
const MAP_W := 150
const MAP_H := 150
const VISIBLE_TILES := 15
const MOVE_SPEED := 1200.0
const ZOOM_STEP := 0.1
const ZOOM_MIN := 0.3
const ZOOM_MAX := 3.0
const OUTER_TILES := 50

var _dragging := false

func _ready() -> void:
	var vp := get_viewport_rect().size
	zoom = Vector2.ONE * (vp.x / (VISIBLE_TILES * TILE_SIZE))
	position = Vector2(10 * TILE_SIZE + TILE_SIZE / 2.0, 10 * TILE_SIZE + TILE_SIZE / 2.0)

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): dir.y -= 1
	if Input.is_key_pressed(KEY_S): dir.y += 1
	if Input.is_key_pressed(KEY_A): dir.x -= 1
	if Input.is_key_pressed(KEY_D): dir.x += 1
	if dir != Vector2.ZERO:
		position += dir.normalized() * MOVE_SPEED * delta
	_clamp()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = (zoom + Vector2.ONE * ZOOM_STEP).clamp(Vector2.ONE * ZOOM_MIN, Vector2.ONE * ZOOM_MAX)
			_clamp()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = (zoom - Vector2.ONE * ZOOM_STEP).clamp(Vector2.ONE * ZOOM_MIN, Vector2.ONE * ZOOM_MAX)
			_clamp()
	elif event is InputEventMouseMotion and _dragging:
		position -= event.relative / zoom
		_clamp()

func _clamp() -> void:
	var half := get_viewport_rect().size / zoom / 2.0
	var outer := OUTER_TILES * TILE_SIZE
	position.x = clamp(position.x, half.x - outer, MAP_W * TILE_SIZE + outer - half.x)
	position.y = clamp(position.y, half.y - outer, MAP_H * TILE_SIZE + outer - half.y)
