extends Node2D

var main_node: Main = null
var _res_bar: HpBar
var _fac_bar: HpBar

func _ready() -> void:
	_res_bar = HpBar.new()
	add_child(_res_bar)

	_fac_bar = HpBar.new()
	_fac_bar.bar_width   = main_node.FACTORY_SIZE
	_fac_bar.bar_height  = 6.0
	_fac_bar.fill_color  = Color(0.3, 0.8, 1.0)
	_fac_bar.bg_color    = Color(0.15, 0.15, 0.15, 1.0)
	_fac_bar.border_color = Color(0, 0, 0, 0)
	add_child(_fac_bar)

func _process(_delta: float) -> void:
	if main_node == null:
		return
	_update_res_bar()
	_update_fac_bar()

func _update_res_bar() -> void:
	var pending: int = main_node._pending_claim_idx
	if pending < 0 or main_node._build_progress <= 0.0:
		_res_bar.visible = false
		return
	_res_bar.position = main_node._resource_positions[pending] + Vector2(0.0, -23.0)
	_res_bar.fill = main_node._build_progress / main_node.BUILD_TIME
	_res_bar.visible = true
	_res_bar.queue_redraw()

func _update_fac_bar() -> void:
	if not main_node._factory_is_building or main_node._factory_build_progress <= 0.0:
		_fac_bar.visible = false
		return
	var half := main_node.FACTORY_SIZE / 2.0
	_fac_bar.position = main_node._factory_building_pos + Vector2(0.0, half + 4.0)
	_fac_bar.fill = main_node._factory_build_progress / main_node.FACTORY_BUILD_TIME
	_fac_bar.visible = true
	_fac_bar.queue_redraw()
