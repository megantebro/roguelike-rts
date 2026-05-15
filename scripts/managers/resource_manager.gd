class_name ResourceManager
extends Node2D

const TILE_SIZE := 64
const MAP_W := 150
const MAP_H := 150
const RESOURCE_COUNT := 1200
const RESOURCE_SEED := 42
const RESOURCE_RADIUS := TILE_SIZE * 1.5
const SNAP_WORLD_RADIUS := TILE_SIZE * 0.6
const BUILD_TIME := 3.0
const METAL_SPACING := 100.0
const METAL_COLLIDE_R := 36.0
const DRAG_THRESHOLD := 8.0

const RES_COLOR := Color(0.0, 1.0, 0.25)
const RES_RING_COLOR := Color(0.2, 0.5, 1.0)
const SNAP_RING_COLOR := Color(1.0, 1.0, 1.0, 0.9)

@onready var main_node: Main = get_parent()

var positions: Array[Vector2] = []
var claimed: Dictionary = {}
var pending_idx := -1
var build_progress := 0.0

var _placing := false
var _snap_idx := -1
var _claim_queue: Array[int] = []
var _keep_placing := false
var _drag_start := Vector2.ZERO
var _dragging := false

func _ready() -> void:
	_generate()

func is_placing() -> bool:
	return _placing

func start_placing() -> void:
	_placing = true
	_snap_idx = -1
	queue_redraw()

func cancel() -> void:
	_placing = false
	_snap_idx = -1
	pending_idx = -1
	_keep_placing = false
	_claim_queue.clear()
	_dragging = false
	build_progress = 0.0
	queue_redraw()

func tick(delta: float, commander: Node2D) -> void:
	if not is_instance_valid(commander):
		return
	if _placing:
		_update_snap()
	if pending_idx >= 0:
		if commander.position.distance_squared_to(positions[pending_idx]) <= RESOURCE_RADIUS * RESOURCE_RADIUS:
			build_progress += delta
			queue_redraw()
			if build_progress >= BUILD_TIME:
				claimed[pending_idx] = true
				pending_idx = -1
				build_progress = 0.0
				_start_next_in_queue(commander)
				queue_redraw()

func push_unit(unit: Node2D) -> void:
	for i in positions.size():
		var rpos := positions[i]
		var diff := unit.position - rpos
		var d2 := diff.length_squared()
		if d2 < METAL_COLLIDE_R * METAL_COLLIDE_R and d2 > 0.001:
			unit.position += diff.normalized() * (METAL_COLLIDE_R - sqrt(d2))

func handle_placement_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_start = event.position
				_dragging = false
			else:
				if _dragging:
					var screen_rect: Rect2 = main_node.selection_box.stop()
					_queue_resources_in_rect(screen_rect)
					_dragging = false
				elif _snap_idx >= 0:
					_place_single()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel()
			main_node.commander_hud.deactivate()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not _dragging and event.position.distance_to(_drag_start) > DRAG_THRESHOLD:
			_dragging = true
			main_node.selection_box.begin(_drag_start)
		if _dragging:
			main_node.selection_box.update_pos(event.position)

func _place_single() -> void:
	if _too_close_to_claimed(_snap_idx):
		return
	var commander: Node2D = main_node.commander
	var p1pos := commander.position
	var res_pos := positions[_snap_idx]
	var shift := Input.is_key_pressed(KEY_SHIFT)
	if p1pos.distance_squared_to(res_pos) <= RESOURCE_RADIUS * RESOURCE_RADIUS:
		pending_idx = _snap_idx
		_snap_idx = -1
		_keep_placing = shift
		build_progress = 0.0
		commander.call("move_to", _stop_pos_for(pending_idx))
		queue_redraw()
	else:
		_claim_queue.append(_snap_idx)
		_keep_placing = shift
		if pending_idx < 0:
			_start_next_in_queue(commander)

func _queue_resources_in_rect(screen_rect: Rect2) -> void:
	var to_add: Array[int] = []
	for i in positions.size():
		if claimed.has(i) or _claim_queue.has(i) or i == pending_idx:
			continue
		if _too_close_to_claimed(i):
			continue
		if screen_rect.has_point(main_node.world_to_screen(positions[i])):
			to_add.append(i)
	if to_add.is_empty():
		return
	var commander: Node2D = main_node.commander
	var start: Vector2
	if not _claim_queue.is_empty():
		start = positions[_claim_queue.back()]
	elif pending_idx >= 0:
		start = positions[pending_idx]
	else:
		start = commander.position
	_claim_queue.append_array(_nearest_neighbor_sort(to_add, start))
	_keep_placing = Input.is_key_pressed(KEY_SHIFT)
	if pending_idx < 0:
		_start_next_in_queue(commander)
	queue_redraw()

func _nearest_neighbor_sort(indices: Array[int], start: Vector2) -> Array[int]:
	var remaining := indices.duplicate()
	var sorted: Array[int] = []
	var current := start
	while not remaining.is_empty():
		var best_i := 0
		var best_d2 := current.distance_squared_to(positions[remaining[0]])
		for j in range(1, remaining.size()):
			var d2 := current.distance_squared_to(positions[remaining[j]])
			if d2 < best_d2:
				best_d2 = d2
				best_i = j
		sorted.append(remaining[best_i])
		current = positions[remaining[best_i]]
		remaining.remove_at(best_i)
	return sorted

func _stop_pos_for(idx: int) -> Vector2:
	var res_pos := positions[idx]
	var commander: Node2D = main_node.commander
	var dir := commander.position - res_pos
	if dir.length_squared() > 1.0:
		return res_pos + dir.normalized() * (METAL_COLLIDE_R + 2.0)
	return res_pos + Vector2.RIGHT * (METAL_COLLIDE_R + 2.0)

func _start_next_in_queue(commander: Node2D) -> void:
	while not _claim_queue.is_empty():
		var idx := _claim_queue[0]
		_claim_queue.remove_at(0)
		if not claimed.has(idx) and not _too_close_to_claimed(idx):
			pending_idx = idx
			build_progress = 0.0
			commander.call("move_to", _stop_pos_for(idx))
			return
	if not _keep_placing:
		cancel()
		main_node.commander_hud.deactivate()

func _too_close_to_claimed(idx: int) -> bool:
	var pos := positions[idx]
	for claimed_idx in claimed:
		if pos.distance_squared_to(positions[claimed_idx]) < METAL_SPACING * METAL_SPACING:
			return true
	return false

func _update_snap() -> void:
	var mouse_world := main_node.screen_to_world(get_viewport().get_mouse_position())
	var best_idx := -1
	var best_d2 := SNAP_WORLD_RADIUS * SNAP_WORLD_RADIUS
	for i in positions.size():
		if claimed.has(i):
			continue
		var d2 := mouse_world.distance_squared_to(positions[i])
		if d2 < best_d2:
			best_d2 = d2
			best_idx = i
	if best_idx != _snap_idx:
		_snap_idx = best_idx
		queue_redraw()

func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RESOURCE_SEED
	var spacing := 192.0
	var jitter := spacing * 0.2
	var all: Array[Vector2] = []
	var gx := 3.0 * TILE_SIZE + spacing * 0.5
	while gx < (MAP_W - 3.0) * TILE_SIZE:
		var gy := 3.0 * TILE_SIZE + spacing * 0.5
		while gy < (MAP_H - 3.0) * TILE_SIZE:
			all.append(Vector2(
				gx + rng.randf_range(-jitter, jitter),
				gy + rng.randf_range(-jitter, jitter)
			))
			gy += spacing
		gx += spacing
	for i in range(all.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := all[i]
		all[i] = all[j]
		all[j] = tmp
	for i in mini(RESOURCE_COUNT, all.size()):
		positions.append(all[i])

func _draw() -> void:
	var r := 10.0
	for i in positions.size():
		var pos := positions[i]
		draw_circle(pos, r, RES_COLOR)
		if claimed.has(i):
			draw_arc(pos, r + 5.0, 0.0, TAU, 32, RES_RING_COLOR, 2.5)
	if _placing and _snap_idx >= 0 and not _dragging:
		var pos := positions[_snap_idx]
		var snap_col := Color(1.0, 0.25, 0.2, 0.9) if _too_close_to_claimed(_snap_idx) else SNAP_RING_COLOR
		draw_arc(pos, r + 11.0, 0.0, TAU, 32, snap_col, 2.0)
	var commander = main_node.commander if main_node != null else null
	if is_instance_valid(commander) and (_claim_queue.size() > 0 or pending_idx >= 0):
		var prev_pos: Vector2 = (commander as Node2D).position
		if pending_idx >= 0:
			var ppos := positions[pending_idx]
			draw_line(prev_pos, ppos, Color(0.5, 0.8, 1.0, 0.5), 1.5)
			draw_circle(ppos, r * 0.65, Color(0.3, 0.6, 1.0, 0.6))
			prev_pos = ppos
		for idx in _claim_queue:
			var pos := positions[idx]
			draw_line(prev_pos, pos, Color(0.5, 0.8, 1.0, 0.4), 1.5)
			draw_circle(pos, r * 0.65, Color(0.3, 0.6, 1.0, 0.4))
			prev_pos = pos
