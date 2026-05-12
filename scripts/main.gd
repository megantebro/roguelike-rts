extends Node2D

const TILE_SIZE := 64
const MAP_W := 150
const MAP_H := 150
const TILE_COLOR := Color(0.3, 0.3, 0.3)
const RESOURCE_COUNT := 1200
const RESOURCE_SEED := 42
const DRAG_THRESHOLD := 8.0
const RESOURCE_RADIUS := TILE_SIZE * 1.5

const RES_COLOR        := Color(0.1, 0.35, 0.85)
const RES_COLOR_NEARBY := Color(0.5, 0.85, 1.0)

var _resource_positions: Array[Vector2] = []
var _nearby_resource_indices: Array[int] = []
var _selected_units: Array = []
var _left_on_ground := false
var _is_dragging := false
var _drag_start_screen := Vector2.ZERO
var _p1: Node = null
var _remote_commanders: Dictionary = {}
var _send_timer := 0.0
const SEND_INTERVAL := 0.05

func _ready() -> void:
	_generate_resources()
	_spawn_commanders()
	NetworkManager.player_updated.connect(_on_player_updated)
	NetworkManager.player_left.connect(_on_player_left)

func _process(delta: float) -> void:
	if _selected_units.size() > 0:
		_update_nearby_resources(_selected_units[0].position)
	elif _nearby_resource_indices.size() > 0:
		_nearby_resource_indices.clear()
		queue_redraw()
	_send_timer += delta
	if _send_timer >= SEND_INTERVAL and is_instance_valid(_p1):
		_send_timer = 0.0
		NetworkManager.send_state("commander", 100, _p1.position)

func _draw() -> void:
	var map_rect := Rect2(0, 0, MAP_W * TILE_SIZE, MAP_H * TILE_SIZE)
	draw_rect(map_rect, TILE_COLOR)
	_draw_resources()
	draw_rect(map_rect, Color.YELLOW, false, 8.0)

func _generate_resources() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RESOURCE_SEED
	for i in RESOURCE_COUNT:
		var x := rng.randf_range(3 * TILE_SIZE, (MAP_W - 3) * TILE_SIZE)
		var y := rng.randf_range(3 * TILE_SIZE, (MAP_H - 3) * TILE_SIZE)
		_resource_positions.append(Vector2(x, y))

func _update_nearby_resources(commander_pos: Vector2) -> void:
	var r2 := RESOURCE_RADIUS * RESOURCE_RADIUS
	var new_nearby: Array[int] = []
	for i in _resource_positions.size():
		if commander_pos.distance_squared_to(_resource_positions[i]) <= r2:
			new_nearby.append(i)
	if new_nearby != _nearby_resource_indices:
		_nearby_resource_indices = new_nearby
		queue_redraw()

func _draw_resources() -> void:
	var s := 14.0
	for i in _resource_positions.size():
		var pos := _resource_positions[i]
		var col := RES_COLOR_NEARBY if _nearby_resource_indices.has(i) else RES_COLOR
		draw_colored_polygon(PackedVector2Array([
			Vector2(pos.x,     pos.y - s),
			Vector2(pos.x + s, pos.y),
			Vector2(pos.x,     pos.y + s),
			Vector2(pos.x - s, pos.y),
		]), col)

func _spawn_commanders() -> void:
	var unit_scene := preload("res://scenes/unit.tscn")
	_p1 = unit_scene.instantiate()
	_p1.unit_color = Color(0.2, 0.5, 1.0)
	_p1.position = Vector2(10 * TILE_SIZE + TILE_SIZE / 2.0, 10 * TILE_SIZE + TILE_SIZE / 2.0)
	_p1.unit_selected.connect(_on_unit_selected)
	$Units.add_child(_p1)

func _on_player_updated(id: int, data: Dictionary) -> void:
	var pos := Vector2(float(data.get("x", 0)), float(data.get("y", 0)))
	if not _remote_commanders.has(id):
		var unit_scene := preload("res://scenes/unit.tscn")
		var cmd := unit_scene.instantiate()
		cmd.unit_color = Color(1.0, 0.3, 0.2)
		cmd.position = pos
		$Units.add_child(cmd)
		_remote_commanders[id] = cmd
	else:
		_remote_commanders[id].position = pos

func _on_player_left(id: int) -> void:
	if _remote_commanders.has(id):
		_remote_commanders[id].queue_free()
		_remote_commanders.erase(id)

func _on_unit_selected(unit) -> void:
	_deselect_all()
	_selected_units.append(unit)
	unit.select()
	$CommanderHUD.show_hud()
	_left_on_ground = false

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		_left_on_ground = true
		_drag_start_screen = event.position
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if _selected_units.size() > 0:
			_move_selected_to(_screen_to_world(event.position))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _is_dragging:
			var screen_rect: Rect2 = $CanvasLayer/SelectionBox.stop()
			_select_in_rect(screen_rect)
			_is_dragging = false
		elif _left_on_ground:
			_deselect_all()
		_left_on_ground = false
	elif event is InputEventMouseMotion and _left_on_ground:
		if not _is_dragging and event.position.distance_to(_drag_start_screen) > DRAG_THRESHOLD:
			_is_dragging = true
			$CanvasLayer/SelectionBox.begin(_drag_start_screen)
		if _is_dragging:
			$CanvasLayer/SelectionBox.update_pos(event.position)

func _deselect_all() -> void:
	for unit in _selected_units:
		unit.deselect()
	_selected_units.clear()
	$CommanderHUD.hide_hud()

func _select_in_rect(screen_rect: Rect2) -> void:
	_deselect_all()
	for unit in $Units.get_children():
		if screen_rect.has_point(_world_to_screen(unit.position)):
			unit.select()
			_selected_units.append(unit)
	if _selected_units.size() > 0:
		$CommanderHUD.show_hud()

func _move_selected_to(target: Vector2) -> void:
	var count := _selected_units.size()
	for i in count:
		var offset := Vector2.ZERO
		if count > 1:
			var angle := (TAU / count) * i
			offset = Vector2(cos(angle), sin(angle)) * 80.0
		_selected_units[i].move_to(target + offset)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var cam: Camera2D = $Camera2D
	return cam.global_position + (screen_pos - get_viewport_rect().size / 2.0) / cam.zoom

func _world_to_screen(world_pos: Vector2) -> Vector2:
	var cam: Camera2D = $Camera2D
	return (world_pos - cam.global_position) * cam.zoom + get_viewport_rect().size / 2.0
