extends Node2D

const TILE_SIZE := 64
const MAP_W := 20
const MAP_H := 14

const TILE_COLOR := Color(0.18, 0.35, 0.18)
const GRID_COLOR := Color(0.1, 0.2, 0.1)

func _ready() -> void:
	_spawn_test_units()

func _draw() -> void:
	for x in MAP_W:
		for y in MAP_H:
			var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			draw_rect(rect, TILE_COLOR)
			draw_rect(rect, GRID_COLOR, false, 1.0)

func _spawn_test_units() -> void:
	var unit_scene := preload("res://scenes/unit.tscn")
	var units_node := $Units

	for i in 3:
		var u := unit_scene.instantiate()
		u.unit_color = Color(0.2, 0.5, 1.0)
		u.position = Vector2(2 * TILE_SIZE + TILE_SIZE / 2.0, (4 + i * 2) * TILE_SIZE + TILE_SIZE / 2.0)
		units_node.add_child(u)

	for i in 3:
		var u := unit_scene.instantiate()
		u.unit_color = Color(1.0, 0.3, 0.2)
		u.position = Vector2(17 * TILE_SIZE + TILE_SIZE / 2.0, (4 + i * 2) * TILE_SIZE + TILE_SIZE / 2.0)
		units_node.add_child(u)
