extends CanvasLayer

signal produce_unit(unit_name: String)

const UNITS := [
	{"name": "Infantry", "color": Color(0.75, 0.65, 0.40), "locked": false},
	{"name": "Tank",     "color": Color(0.40, 0.50, 0.30), "locked": false},
	{"name": "Artillery","color": Color(0.60, 0.40, 0.20), "locked": true},
	{"name": "Air",      "color": Color(0.50, 0.70, 0.90), "locked": true},
]

const BG_COL     := Color(0.03, 0.05, 0.10, 0.96)
const TOP_LINE   := Color(0.15, 0.50, 0.90, 0.90)
const BTN_BG     := Color(0.05, 0.10, 0.20, 1.0)
const BTN_BDR    := Color(0.20, 0.60, 1.00, 1.0)
const BTN_HOVER  := Color(0.10, 0.20, 0.38, 1.0)
const BTN_FLASH  := Color(0.20, 0.45, 0.75, 1.0)
const LOCK_BG    := Color(0.03, 0.05, 0.09, 1.0)
const LOCK_BDR   := Color(0.10, 0.16, 0.28, 1.0)
const LBL_ACTIVE := Color(0.75, 0.92, 1.00)
const LBL_LOCKED := Color(0.25, 0.32, 0.42)

func _ready() -> void:
	layer = 6
	_build_ui()
	hide()

func _build_ui() -> void:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.custom_minimum_size = Vector2(0, 150)
	panel.offset_top    = -150
	panel.offset_bottom = 0

	var bg := StyleBoxFlat.new()
	bg.bg_color = BG_COL
	bg.border_width_top = 2
	bg.border_color = TOP_LINE
	panel.add_theme_stylebox_override("panel", bg)
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	for u in UNITS:
		hbox.add_child(_make_button(u))

func _make_button(u: Dictionary) -> Control:
	var locked: bool = u["locked"]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(90, 134)
	btn.disabled   = locked
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not locked else Control.CURSOR_ARROW

	var bg_col  := LOCK_BG  if locked else BTN_BG
	var bdr_col := LOCK_BDR if locked else BTN_BDR
	_apply_styles(btn, bg_col, bdr_col)

	if not locked:
		var uname: String = u["name"]
		btn.pressed.connect(func(): _on_btn_pressed(btn, uname))

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	btn.add_child(vbox)

	var icon_wrap := CenterContainer.new()
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(58, 58)
	icon.color = u["color"].darkened(0.55) if locked else u["color"]
	icon_wrap.add_child(icon)
	vbox.add_child(icon_wrap)

	var lbl := Label.new()
	lbl.text = u["name"]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", LBL_LOCKED if locked else LBL_ACTIVE)
	vbox.add_child(lbl)

	return btn

func _apply_styles(btn: Button, bg_col: Color, bdr_col: Color) -> void:
	for sname in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s := StyleBoxFlat.new()
		s.bg_color = BTN_HOVER if sname == "hover" else bg_col
		s.border_width_left   = 1
		s.border_width_right  = 1
		s.border_width_top    = 1
		s.border_width_bottom = 1
		s.border_color = bdr_col
		s.corner_radius_top_left     = 3
		s.corner_radius_top_right    = 3
		s.corner_radius_bottom_left  = 3
		s.corner_radius_bottom_right = 3
		btn.add_theme_stylebox_override(sname, s)

func _on_btn_pressed(btn: Button, uname: String) -> void:
	_apply_styles(btn, BTN_FLASH, BTN_BDR)
	produce_unit.emit(uname)
	var tween := create_tween()
	tween.tween_interval(0.08)
	tween.tween_callback(func(): _apply_styles(btn, BTN_BG, BTN_BDR))

func show_hud() -> void:
	show()

func hide_hud() -> void:
	hide()
