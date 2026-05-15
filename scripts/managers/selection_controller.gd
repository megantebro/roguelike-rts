class_name SelectionController
extends Node

const DRAG_THRESHOLD := 8.0
const FORMATION_SPACING := 50.0

@onready var main_node: Main = get_parent()

var selected: Array = []

var _left_on_ground := false
var _is_dragging := false
var _drag_start_screen := Vector2.ZERO

func register_unit(unit: Node) -> void:
	unit.unit_selected.connect(_on_unit_selected)

func _on_unit_selected(unit) -> void:
	deselect_all()
	selected.append(unit)
	unit.select()
	main_node.commander_hud.show_hud()
	_left_on_ground = false

func deselect_all() -> void:
	for unit in selected:
		unit.deselect()
	selected.clear()
	main_node.cancel_all_placement()
	main_node.commander_hud.hide_hud()

func has_selection() -> bool:
	return not selected.is_empty()

func start_drag_potential(screen_pos: Vector2) -> void:
	_left_on_ground = true
	_drag_start_screen = screen_pos

func move_selected_to(target: Vector2) -> void:
	if selected.is_empty():
		return
	var count := selected.size()
	var side := int(ceil(sqrt(float(count))))
	var half_extent := (float(side) - 1.0) / 2.0
	for i in count:
		var col := i % side
		var row := i / side
		var offset := Vector2(float(col) - half_extent, float(row) - half_extent) * FORMATION_SPACING
		selected[i].move_to(target + offset)

func handle_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _is_dragging:
			var screen_rect: Rect2 = main_node.selection_box.stop()
			_select_in_rect(screen_rect)
			_is_dragging = false
		elif _left_on_ground:
			deselect_all()
		_left_on_ground = false
	elif event is InputEventMouseMotion and _left_on_ground:
		if not _is_dragging and event.position.distance_to(_drag_start_screen) > DRAG_THRESHOLD:
			_is_dragging = true
			main_node.selection_box.begin(_drag_start_screen)
		if _is_dragging:
			main_node.selection_box.update_pos(event.position)

func _select_in_rect(screen_rect: Rect2) -> void:
	deselect_all()
	for unit in main_node.units_root.get_children():
		if screen_rect.has_point(main_node.world_to_screen(unit.position)):
			unit.select()
			selected.append(unit)
	if not selected.is_empty():
		main_node.commander_hud.show_hud()
