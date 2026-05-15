class_name Main
extends Node2D

const TILE_SIZE := 64
const MAP_W := 150
const MAP_H := 150
const TILE_COLOR := Color(0.3, 0.3, 0.3)
const OUTER_TILES := 50
const SURF_TILE := 512
const SEND_INTERVAL := 0.05

const COMMANDER_SCENE := preload("res://scenes/units/commander.tscn")

var _surf_texture: Texture2D = preload("res://icon/Surf.png")

@onready var resources: ResourceManager     = $ResourceManager
@onready var factories: FactoryManager      = $FactoryManager
@onready var selection: SelectionController = $SelectionController
@onready var commander_hud                  = $CommanderHUD
@onready var factory_hud                    = $FactoryHUD
@onready var selection_box                  = $CanvasLayer/SelectionBox
@onready var units_root: Node               = $Units

var commander: Node = null
var _remote_commanders: Dictionary = {}
var _send_timer := 0.0

func _ready() -> void:
	_spawn_commander()
	NetworkManager.player_updated.connect(_on_player_updated)
	NetworkManager.player_left.connect(_on_player_left)
	commander_hud.build_selected.connect(_on_build_selected)
	factory_hud.produce_unit.connect(factories.queue_unit_for_selected)
	factories.unit_spawned.connect(selection.register_unit)
	factories.selection_changed.connect(_on_factory_selection_changed)
	var bar_ov := preload("res://scripts/bar_overlay.gd").new()
	bar_ov.main_node = self
	add_child(bar_ov)

func _process(delta: float) -> void:
	if is_instance_valid(commander):
		call_deferred("_push_commander_from_resources")
		resources.tick(delta, commander as Node2D)
		factories.tick(delta, commander as Node2D)
	_send_timer += delta
	if _send_timer >= SEND_INTERVAL and is_instance_valid(commander):
		_send_timer = 0.0
		NetworkManager.send_state("commander", 100, (commander as Node2D).position)

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
	draw_rect(map_rect, Color.YELLOW, false, 8.0)

func _unhandled_input(event: InputEvent) -> void:
	if resources.is_placing() or factories.is_placing():
		return
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		var world := screen_to_world(event.position)
		var fi := factories.factory_at(world)
		if fi >= 0:
			selection.deselect_all()
			if event.double_click:
				factories.select_all_factories()
			else:
				factories.select_factory(fi)
			return
		selection.start_drag_potential(event.position)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		selection.move_selected_to(screen_to_world(event.position))

func _input(event: InputEvent) -> void:
	if factories.is_placing():
		factories.handle_placement_input(event)
		return
	if resources.is_placing():
		resources.handle_placement_input(event)
		return
	selection.handle_drag_input(event)

func _on_build_selected(bname: String) -> void:
	cancel_all_placement()
	if bname == "Metal\nExtractor":
		resources.start_placing()
	elif bname == "Factory":
		factories.start_placing()

func cancel_all_placement() -> void:
	resources.cancel()
	factories.cancel()
	factories.deselect_factory()
	commander_hud.deactivate()

func _on_factory_selection_changed(idx: int) -> void:
	if idx >= 0:
		factory_hud.show_hud()
	else:
		factory_hud.hide_hud()

func _spawn_commander() -> void:
	commander = COMMANDER_SCENE.instantiate()
	commander.unit_color = Color(0.2, 0.5, 1.0)
	commander.position = Vector2(10 * TILE_SIZE + TILE_SIZE / 2.0, 10 * TILE_SIZE + TILE_SIZE / 2.0)
	units_root.add_child(commander)
	selection.register_unit(commander)

func _on_player_updated(id: int, data: Dictionary) -> void:
	var pos := Vector2(float(data.get("x", 0)), float(data.get("y", 0)))
	if not _remote_commanders.has(id):
		var cmd := COMMANDER_SCENE.instantiate()
		cmd.unit_color = Color(1.0, 0.3, 0.2)
		cmd.position = pos
		units_root.add_child(cmd)
		_remote_commanders[id] = cmd
	else:
		_remote_commanders[id].position = pos

func _on_player_left(id: int) -> void:
	if _remote_commanders.has(id):
		_remote_commanders[id].queue_free()
		_remote_commanders.erase(id)

func _push_commander_from_resources() -> void:
	if is_instance_valid(commander):
		resources.push_unit(commander as Node2D)

func screen_to_world(screen_pos: Vector2) -> Vector2:
	var cam: Camera2D = $Camera2D
	return cam.global_position + (screen_pos - get_viewport_rect().size / 2.0) / cam.zoom

func world_to_screen(world_pos: Vector2) -> Vector2:
	var cam: Camera2D = $Camera2D
	return (world_pos - cam.global_position) * cam.zoom + get_viewport_rect().size / 2.0
