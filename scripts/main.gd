extends Node2D
class_name Main

const TILE_SIZE := 64
const MAP_W := 150
const MAP_H := 150
const TILE_COLOR := Color(0.3, 0.3, 0.3)
const RESOURCE_COUNT := 1200
const RESOURCE_SEED := 42
const DRAG_THRESHOLD := 8.0
const RESOURCE_RADIUS := TILE_SIZE * 1.5
const SNAP_WORLD_RADIUS := TILE_SIZE * 0.6
const BUILD_TIME := 3.0
const METAL_SPACING    := 100.0
const METAL_COLLIDE_R  := 36.0
const OUTER_TILES      := 50
const SURF_TILE        := 512
const FACTORY_SIZE       := 128.0
const FACTORY_BUILD_TIME := 10.0
const FACTORY_RADIUS     := TILE_SIZE * 1.5

var _surf_texture: Texture2D    = preload("res://icon/Surf.png")
var _factory_texture: Texture2D = preload("res://icon/Tank Factory.png")

const RES_COLOR       := Color(0.0, 1.0, 0.25)
const RES_RING_COLOR  := Color(0.2, 0.5, 1.0)
const SNAP_RING_COLOR := Color(1.0, 1.0, 1.0, 0.9)

var _resource_positions: Array[Vector2] = []
var _claimed_resources: Dictionary = {}
var _selected_units: Array = []
var _left_on_ground := false
var _is_dragging := false
var _drag_start_screen := Vector2.ZERO
var _p1: Node = null
var _remote_commanders: Dictionary = {}
var _send_timer := 0.0
const SEND_INTERVAL := 0.05

var _placing_resource    := false
var _snap_resource_idx   := -1
var _pending_claim_idx   := -1
var _pending_keep_placing := false
var _claim_queue: Array[int] = []
var _res_drag_start      := Vector2.ZERO
var _res_dragging        := false
var _build_progress      := 0.0

var _placing_factory       := false
var _factory_preview       := Vector2.ZERO
var _factory_positions: Array[Vector2] = []
var _factory_queue: Array[Vector2]     = []
var _factory_is_building   := false
var _factory_building_pos  := Vector2.ZERO
var _factory_build_progress := 0.0

func _ready() -> void:
	_generate_resources()
	_spawn_commanders()
	NetworkManager.player_updated.connect(_on_player_updated)
	NetworkManager.player_left.connect(_on_player_left)
	$CommanderHUD.build_selected.connect(_on_build_selected)
	var bar_ov := preload("res://scripts/bar_overlay.gd").new()
	bar_ov.main_node = self
	add_child(bar_ov)

func _process(delta: float) -> void:
	if is_instance_valid(_p1):
		call_deferred("_push_commander_from_metals")
		if _placing_resource:
			_update_snap()
		if _pending_claim_idx >= 0:
			var p1pos: Vector2 = (_p1 as Node2D).position
			if p1pos.distance_squared_to(_resource_positions[_pending_claim_idx]) <= RESOURCE_RADIUS * RESOURCE_RADIUS:
				_build_progress += delta
				queue_redraw()
				if _build_progress >= BUILD_TIME:
					_claimed_resources[_pending_claim_idx] = true
					_pending_claim_idx = -1
					_build_progress = 0.0
					queue_redraw()
					_start_next_in_queue()
		if _factory_is_building:
			var p1pos: Vector2 = (_p1 as Node2D).position
			if p1pos.distance_squared_to(_factory_building_pos) <= FACTORY_RADIUS * FACTORY_RADIUS:
				_factory_build_progress += delta
				queue_redraw()
				if _factory_build_progress >= FACTORY_BUILD_TIME:
					_factory_positions.append(_factory_building_pos)
					_factory_is_building = false
					_factory_build_progress = 0.0
					queue_redraw()
					_start_next_factory()
	_send_timer += delta
	if _send_timer >= SEND_INTERVAL and is_instance_valid(_p1):
		_send_timer = 0.0
		NetworkManager.send_state("commander", 100, (_p1 as Node2D).position)

func _draw() -> void:
	var outer := OUTER_TILES * TILE_SIZE
	var x0 := -outer
	var y0 := -outer
	var x1 := MAP_W * TILE_SIZE + outer
	var y1 := MAP_H * TILE_SIZE + outer
	var col := 0
	var x := x0
	while x < x1:
		var row := 0
		var y := y0
		while y < y1:
			var sx := -1.0 if (col % 2 == 1) else 1.0
			var sy := -1.0 if (row % 2 == 1) else 1.0
			var ox := x + SURF_TILE if (col % 2 == 1) else x
			var oy := y + SURF_TILE if (row % 2 == 1) else y
			draw_set_transform(Vector2(ox, oy), 0.0, Vector2(sx, sy))
			draw_texture_rect(_surf_texture, Rect2(0, 0, SURF_TILE, SURF_TILE), false)
			y += SURF_TILE
			row += 1
		x += SURF_TILE
		col += 1
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var map_rect := Rect2(0, 0, MAP_W * TILE_SIZE, MAP_H * TILE_SIZE)
	draw_rect(map_rect, TILE_COLOR)
	_draw_resources()
	_draw_factories()
	draw_rect(map_rect, Color.YELLOW, false, 8.0)

func _draw_factories() -> void:
	var half := FACTORY_SIZE / 2.0
	for fpos in _factory_positions:
		draw_texture_rect(_factory_texture, Rect2(fpos - Vector2(half, half), Vector2(FACTORY_SIZE, FACTORY_SIZE)), false)
	if _factory_is_building:
		draw_texture_rect(_factory_texture, Rect2(_factory_building_pos - Vector2(half, half), Vector2(FACTORY_SIZE, FACTORY_SIZE)), false, Color(1, 1, 1, 0.5))
	for fpos in _factory_queue:
		draw_texture_rect(_factory_texture, Rect2(fpos - Vector2(half, half), Vector2(FACTORY_SIZE, FACTORY_SIZE)), false, Color(1, 1, 1, 0.3))
	if _placing_factory:
		var invalid := _factory_overlaps(_factory_preview)
		var col := Color(1, 0.2, 0.2, 0.6) if invalid else Color(1, 1, 1, 0.6)
		draw_texture_rect(_factory_texture, Rect2(_factory_preview - Vector2(half, half), Vector2(FACTORY_SIZE, FACTORY_SIZE)), false, col)

func _generate_resources() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RESOURCE_SEED
	var spacing := 192.0
	var jitter  := spacing * 0.2
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
		_resource_positions.append(all[i])

func _update_snap() -> void:
	var mouse_world := _screen_to_world(get_viewport().get_mouse_position())
	var best_idx := -1
	var best_d2 := SNAP_WORLD_RADIUS * SNAP_WORLD_RADIUS
	for i in _resource_positions.size():
		if _claimed_resources.has(i):
			continue
		var d2 := mouse_world.distance_squared_to(_resource_positions[i])
		if d2 < best_d2:
			best_d2 = d2
			best_idx = i
	if best_idx != _snap_resource_idx:
		_snap_resource_idx = best_idx
		queue_redraw()

func _draw_resources() -> void:
	var r := 10.0
	for i in _resource_positions.size():
		var pos := _resource_positions[i]
		draw_circle(pos, r, RES_COLOR)
		if _claimed_resources.has(i):
			draw_arc(pos, r + 5.0, 0.0, TAU, 32, RES_RING_COLOR, 2.5)

	if _placing_resource and _snap_resource_idx >= 0 and not _res_dragging:
		var pos := _resource_positions[_snap_resource_idx]
		var snap_col := Color(1.0, 0.25, 0.2, 0.9) if _too_close_to_metal(_snap_resource_idx) else SNAP_RING_COLOR
		draw_arc(pos, r + 11.0, 0.0, TAU, 32, snap_col, 2.0)

	if is_instance_valid(_p1) and (_claim_queue.size() > 0 or _pending_claim_idx >= 0):
		var prev_pos: Vector2 = (_p1 as Node2D).position
		if _pending_claim_idx >= 0:
			var ppos := _resource_positions[_pending_claim_idx]
			draw_line(prev_pos, ppos, Color(0.5, 0.8, 1.0, 0.5), 1.5)
			draw_circle(ppos, r * 0.65, Color(0.3, 0.6, 1.0, 0.6))
			prev_pos = ppos
		for idx in _claim_queue:
			var pos := _resource_positions[idx]
			draw_line(prev_pos, pos, Color(0.5, 0.8, 1.0, 0.4), 1.5)
			draw_circle(pos, r * 0.65, Color(0.3, 0.6, 1.0, 0.4))
			prev_pos = pos

func _spawn_commanders() -> void:
	var unit_scene := preload("res://scenes/unit.tscn")
	_p1 = unit_scene.instantiate()
	_p1.unit_color = Color(0.2, 0.5, 1.0)
	_p1.position = Vector2(10 * TILE_SIZE + TILE_SIZE / 2.0, 10 * TILE_SIZE + TILE_SIZE / 2.0)
	_p1.unit_selected.connect(_on_unit_selected)
	$Units.add_child(_p1)

func _on_build_selected(bname: String) -> void:
	_placing_resource = (bname == "Metal\nExtractor")
	_placing_factory  = (bname == "Factory")
	_snap_resource_idx = -1
	queue_redraw()

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
	if _placing_resource or _placing_factory:
		return
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		_left_on_ground = true
		_drag_start_screen = event.position
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if _selected_units.size() > 0:
			_move_selected_to(_screen_to_world(event.position))

func _input(event: InputEvent) -> void:
	if _placing_factory:
		_handle_factory_input(event)
		return
	if _placing_resource:
		_handle_placement_input(event)
		return
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

func _handle_placement_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_res_drag_start = event.position
				_res_dragging = false
			else:
				if _res_dragging:
					var screen_rect: Rect2 = $CanvasLayer/SelectionBox.stop()
					_queue_resources_in_rect(screen_rect)
					_res_dragging = false
				elif _snap_resource_idx >= 0:
					_place_single_resource()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_placement()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not _res_dragging and event.position.distance_to(_res_drag_start) > DRAG_THRESHOLD:
			_res_dragging = true
			$CanvasLayer/SelectionBox.begin(_res_drag_start)
		if _res_dragging:
			$CanvasLayer/SelectionBox.update_pos(event.position)

func _place_single_resource() -> void:
	if _too_close_to_metal(_snap_resource_idx):
		return
	var p1pos: Vector2 = (_p1 as Node2D).position
	var res_pos := _resource_positions[_snap_resource_idx]
	var shift := Input.is_key_pressed(KEY_SHIFT)
	if p1pos.distance_squared_to(res_pos) <= RESOURCE_RADIUS * RESOURCE_RADIUS:
		_pending_claim_idx = _snap_resource_idx
		_snap_resource_idx = -1
		_pending_keep_placing = shift
		_build_progress = 0.0
		(_p1 as Node2D).call("move_to", _stop_pos_for(_pending_claim_idx))
		queue_redraw()
	else:
		_claim_queue.append(_snap_resource_idx)
		_pending_keep_placing = shift
		if _pending_claim_idx < 0:
			_start_next_in_queue()

func _queue_resources_in_rect(screen_rect: Rect2) -> void:
	var to_add: Array[int] = []
	for i in _resource_positions.size():
		if _claimed_resources.has(i) or _claim_queue.has(i) or i == _pending_claim_idx:
			continue
		if _too_close_to_metal(i):
			continue
		if screen_rect.has_point(_world_to_screen(_resource_positions[i])):
			to_add.append(i)
	if to_add.is_empty():
		return
	var start: Vector2
	if not _claim_queue.is_empty():
		start = _resource_positions[_claim_queue.back()]
	elif _pending_claim_idx >= 0:
		start = _resource_positions[_pending_claim_idx]
	else:
		start = (_p1 as Node2D).position
	_claim_queue.append_array(_nearest_neighbor_sort(to_add, start))
	_pending_keep_placing = Input.is_key_pressed(KEY_SHIFT)
	if _pending_claim_idx < 0:
		_start_next_in_queue()
	queue_redraw()

func _nearest_neighbor_sort(indices: Array[int], start: Vector2) -> Array[int]:
	var remaining := indices.duplicate()
	var sorted: Array[int] = []
	var current := start
	while not remaining.is_empty():
		var best_i := 0
		var best_d2 := current.distance_squared_to(_resource_positions[remaining[0]])
		for j in range(1, remaining.size()):
			var d2 := current.distance_squared_to(_resource_positions[remaining[j]])
			if d2 < best_d2:
				best_d2 = d2
				best_i = j
		sorted.append(remaining[best_i])
		current = _resource_positions[remaining[best_i]]
		remaining.remove_at(best_i)
	return sorted

func _stop_pos_for(idx: int) -> Vector2:
	var res_pos := _resource_positions[idx]
	var dir := (_p1 as Node2D).position - res_pos
	if dir.length_squared() > 1.0:
		return res_pos + dir.normalized() * (METAL_COLLIDE_R + 2.0)
	return res_pos + Vector2.RIGHT * (METAL_COLLIDE_R + 2.0)

func _start_next_in_queue() -> void:
	while not _claim_queue.is_empty():
		var idx := _claim_queue[0]
		_claim_queue.remove_at(0)
		if not _claimed_resources.has(idx) and not _too_close_to_metal(idx):
			_pending_claim_idx = idx
			_build_progress = 0.0
			(_p1 as Node2D).call("move_to", _stop_pos_for(idx))
			return
	if not _pending_keep_placing:
		_cancel_placement()

func _push_commander_from_metals() -> void:
	if not is_instance_valid(_p1):
		return
	var u := _p1 as Node2D
	for i in _resource_positions.size():
		var rpos := _resource_positions[i]
		var diff := u.position - rpos
		var d2 := diff.length_squared()
		if d2 < METAL_COLLIDE_R * METAL_COLLIDE_R and d2 > 0.001:
			u.position += diff.normalized() * (METAL_COLLIDE_R - sqrt(d2))

func _too_close_to_metal(idx: int) -> bool:
	var pos := _resource_positions[idx]
	for claimed_idx in _claimed_resources:
		if pos.distance_squared_to(_resource_positions[claimed_idx]) < METAL_SPACING * METAL_SPACING:
			return true
	return false

func _handle_factory_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_factory_preview = _screen_to_world(event.position)
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _factory_overlaps(_factory_preview):
				_factory_queue.append(_factory_preview)
				if not _factory_is_building:
					_start_next_factory()
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_placing_factory = false
			$CommanderHUD.deactivate()
			queue_redraw()

func _factory_overlaps(pos: Vector2) -> bool:
	for fpos in _factory_positions:
		if pos.distance_to(fpos) < FACTORY_SIZE:
			return true
	if _factory_is_building and pos.distance_to(_factory_building_pos) < FACTORY_SIZE:
		return true
	for fpos in _factory_queue:
		if pos.distance_to(fpos) < FACTORY_SIZE:
			return true
	return false

func _factory_stop_pos(fpos: Vector2) -> Vector2:
	var dir := (_p1 as Node2D).position - fpos
	if dir.length_squared() > 1.0:
		return fpos + dir.normalized() * (FACTORY_RADIUS * 0.7)
	return fpos + Vector2.RIGHT * (FACTORY_RADIUS * 0.7)

func _start_next_factory() -> void:
	if _factory_queue.is_empty():
		return
	_factory_building_pos = _factory_queue[0]
	_factory_queue.remove_at(0)
	_factory_is_building = true
	_factory_build_progress = 0.0
	(_p1 as Node2D).call("move_to", _factory_stop_pos(_factory_building_pos))

func _cancel_placement() -> void:
	_placing_resource = false
	_placing_factory  = false
	_snap_resource_idx = -1
	_pending_claim_idx = -1
	_pending_keep_placing = false
	_claim_queue.clear()
	_res_dragging = false
	_build_progress = 0.0
	$CommanderHUD.deactivate()
	queue_redraw()

func _deselect_all() -> void:
	for unit in _selected_units:
		unit.deselect()
	_selected_units.clear()
	_cancel_placement()
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
