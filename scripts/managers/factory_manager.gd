class_name FactoryManager
extends Node2D

const TILE_SIZE := 64
const FACTORY_SIZE := 128.0
const FACTORY_BUILD_TIME := 10.0
const FACTORY_RADIUS := TILE_SIZE * 1.5
const UNIT_BUILD_TIME := 3.0

const UNIT_SCENES := {
	"Infantry": preload("res://scenes/units/infantry.tscn"),
	"Tank":     preload("res://scenes/units/tank.tscn"),
}

signal unit_spawned(unit)
signal selection_changed(idx: int)

@onready var main_node: Main = get_parent()

var _texture: Texture2D = preload("res://icon/Tank Factory.png")

var positions: Array[Vector2] = []
var build_queue: Array[Vector2] = []
var is_building := false
var building_pos := Vector2.ZERO
var build_progress := 0.0

var selected_idx := -1

var _queues: Array = []                # parallel: each entry is Array[String]
var _unit_progress: Array[float] = []
var _spawn_counts: Array[int] = []

var _placing := false
var _preview := Vector2.ZERO

func is_placing() -> bool:
	return _placing

func start_placing() -> void:
	_placing = true
	queue_redraw()

func cancel() -> void:
	_placing = false
	queue_redraw()

func factory_at(world_pos: Vector2) -> int:
	var half := FACTORY_SIZE / 2.0
	for i in positions.size():
		var fpos := positions[i]
		if abs(world_pos.x - fpos.x) <= half and abs(world_pos.y - fpos.y) <= half:
			return i
	return -1

func select_factory(idx: int) -> void:
	if idx < 0 or idx >= positions.size():
		return
	selected_idx = idx
	selection_changed.emit(idx)
	queue_redraw()

func deselect_factory() -> void:
	if selected_idx < 0:
		return
	selected_idx = -1
	selection_changed.emit(-1)
	queue_redraw()

func queue_unit_for_selected(unit_name: String) -> void:
	if selected_idx < 0:
		return
	if not UNIT_SCENES.has(unit_name):
		return
	_queues[selected_idx].append(unit_name)
	queue_redraw()

func tick(delta: float, commander: Node2D) -> void:
	if is_building and is_instance_valid(commander):
		if commander.position.distance_squared_to(building_pos) <= FACTORY_RADIUS * FACTORY_RADIUS:
			build_progress += delta
			queue_redraw()
			if build_progress >= FACTORY_BUILD_TIME:
				positions.append(building_pos)
				_queues.append([] as Array)
				_unit_progress.append(0.0)
				_spawn_counts.append(0)
				is_building = false
				build_progress = 0.0
				_start_next_build(commander)
				queue_redraw()
	_tick_production(delta)

func _start_next_build(commander: Node2D) -> void:
	if build_queue.is_empty():
		return
	building_pos = build_queue[0]
	build_queue.remove_at(0)
	is_building = true
	build_progress = 0.0
	commander.call("move_to", _stop_pos_for(building_pos))

func _stop_pos_for(fpos: Vector2) -> Vector2:
	var commander: Node2D = main_node.commander
	var dir := commander.position - fpos
	if dir.length_squared() > 1.0:
		return fpos + dir.normalized() * (FACTORY_RADIUS * 0.7)
	return fpos + Vector2.RIGHT * (FACTORY_RADIUS * 0.7)

func _tick_production(delta: float) -> void:
	for i in positions.size():
		if (_queues[i] as Array).is_empty():
			continue
		_unit_progress[i] += delta
		queue_redraw()
		if _unit_progress[i] >= UNIT_BUILD_TIME:
			_unit_progress[i] -= UNIT_BUILD_TIME
			var unit_name: String = (_queues[i] as Array).pop_front()
			_spawn_unit_at(i, unit_name)

func _spawn_unit_at(factory_idx: int, unit_name: String) -> void:
	var scene: PackedScene = UNIT_SCENES.get(unit_name)
	if scene == null:
		return
	var fpos := positions[factory_idx]
	var n := _spawn_counts[factory_idx]
	_spawn_counts[factory_idx] += 1
	var angle := float(n) * 0.9
	var offset := Vector2(cos(angle), sin(angle)) * (FACTORY_SIZE * 0.55)
	var unit := scene.instantiate()
	unit.position = fpos + offset
	main_node.units_root.add_child(unit)
	unit_spawned.emit(unit)

func _overlaps(pos: Vector2) -> bool:
	for fpos in positions:
		if pos.distance_to(fpos) < FACTORY_SIZE:
			return true
	if is_building and pos.distance_to(building_pos) < FACTORY_SIZE:
		return true
	for fpos in build_queue:
		if pos.distance_to(fpos) < FACTORY_SIZE:
			return true
	return false

func handle_placement_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_preview = main_node.screen_to_world(event.position)
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _overlaps(_preview):
				build_queue.append(_preview)
				if not is_building:
					_start_next_build(main_node.commander)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel()
			main_node.commander_hud.deactivate()

func _draw() -> void:
	var half := FACTORY_SIZE / 2.0
	for i in positions.size():
		var fpos := positions[i]
		draw_texture_rect(_texture, Rect2(fpos - Vector2(half, half), Vector2(FACTORY_SIZE, FACTORY_SIZE)), false)
		var q: int = (_queues[i] as Array).size()
		if q > 0:
			var bar_w := FACTORY_SIZE
			var bar_y := fpos.y - half - 12.0
			var bar_x := fpos.x - half
			draw_rect(Rect2(bar_x, bar_y, bar_w, 6.0), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(bar_x, bar_y, bar_w * (_unit_progress[i] / UNIT_BUILD_TIME), 6.0), Color(0.3, 0.8, 1.0))
			for j in mini(q - 1, 8):
				draw_circle(Vector2(bar_x + 5.0 + j * 10.0, bar_y - 8.0), 3.0, Color(0.5, 0.85, 1.0))
		if i == selected_idx:
			draw_rect(Rect2(fpos - Vector2(half + 2.0, half + 2.0), Vector2(FACTORY_SIZE + 4.0, FACTORY_SIZE + 4.0)), Color(1, 1, 1, 0.9), false, 3.0)
	if is_building:
		draw_texture_rect(_texture, Rect2(building_pos - Vector2(half, half), Vector2(FACTORY_SIZE, FACTORY_SIZE)), false, Color(1, 1, 1, 0.5))
	for fpos in build_queue:
		draw_texture_rect(_texture, Rect2(fpos - Vector2(half, half), Vector2(FACTORY_SIZE, FACTORY_SIZE)), false, Color(1, 1, 1, 0.3))
	if _placing:
		var invalid := _overlaps(_preview)
		var col := Color(1, 0.2, 0.2, 0.6) if invalid else Color(1, 1, 1, 0.6)
		draw_texture_rect(_texture, Rect2(_preview - Vector2(half, half), Vector2(FACTORY_SIZE, FACTORY_SIZE)), false, col)
