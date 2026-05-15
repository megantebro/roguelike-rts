extends Node2D

var main_node: Main = null
var _res_bar: HpBar
var _fac_bar: HpBar

func _ready() -> void:
	_res_bar = HpBar.new()
	add_child(_res_bar)

	_fac_bar = HpBar.new()
	_fac_bar.bar_width   = FactoryManager.FACTORY_SIZE
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
	var rm := main_node.resources
	if rm.pending_idx < 0 or rm.build_progress <= 0.0:
		_res_bar.visible = false
		return
	_res_bar.position = rm.positions[rm.pending_idx] + Vector2(0.0, -23.0)
	_res_bar.fill = rm.build_progress / ResourceManager.BUILD_TIME
	_res_bar.visible = true
	_res_bar.queue_redraw()

func _update_fac_bar() -> void:
	var fm := main_node.factories
	if not fm.is_building or fm.build_progress <= 0.0:
		_fac_bar.visible = false
		return
	var half := FactoryManager.FACTORY_SIZE / 2.0
	_fac_bar.position = fm.building_pos + Vector2(0.0, half + 4.0)
	_fac_bar.fill = fm.build_progress / FactoryManager.FACTORY_BUILD_TIME
	_fac_bar.visible = true
	_fac_bar.queue_redraw()
