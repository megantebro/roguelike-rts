extends CanvasLayer

const BUILDINGS := [
	{"name": "Metal\nExtractor", "color": Color(0.15, 0.55, 1.00), "locked": false},
	{"name": "Power\nGenerator", "color": Color(0.70, 0.60, 0.05), "locked": false},
	{"name": "Factory",          "color": Color(0.25, 0.40, 0.70), "locked": true},
	{"name": "Turret",           "color": Color(0.60, 0.20, 0.20), "locked": true},
	{"name": "Shield\nGen",      "color": Color(0.15, 0.55, 0.45), "locked": true},
	{"name": "Radar",            "color": Color(0.40, 0.20, 0.65), "locked": true},
	{"name": "Wall",             "color": Color(0.35, 0.35, 0.40), "locked": true},
	{"name": "Adv\nFactory",     "color": Color(0.20, 0.30, 0.65), "locked": true},
]

const BG_COL      := Color(0.03, 0.05, 0.10, 0.96)
const TOP_LINE    := Color(0.15, 0.50, 0.90, 0.90)
const BTN_BG      := Color(0.05, 0.10, 0.20, 1.0)
const BTN_BDR     := Color(0.20, 0.60, 1.00, 1.0)
const BTN_HOVER   := Color(0.10, 0.20, 0.38, 1.0)
const LOCK_BG     := Color(0.03, 0.05, 0.09, 1.0)
const LOCK_BDR    := Color(0.10, 0.16, 0.28, 1.0)
const LBL_ACTIVE  := Color(0.75, 0.92, 1.00)
const LBL_LOCKED  := Color(0.25, 0.32, 0.42)

func _ready() -> void:
	layer = 5
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
	bg.border_color     = TOP_LINE
	panel.add_theme_stylebox_override("panel", bg)
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	for b in BUILDINGS:
		hbox.add_child(_make_button(b))

func _make_button(b: Dictionary) -> Control:
	var locked: bool = b["locked"]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(90, 134)
	btn.disabled   = locked
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not locked else Control.CURSOR_ARROW

	var bg_col  := LOCK_BG  if locked else BTN_BG
	var bdr_col := LOCK_BDR if locked else BTN_BDR

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

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	btn.add_child(vbox)

	var icon_wrap := CenterContainer.new()
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(58, 58)
	var icon_col: Color = b["color"]
	icon.color = icon_col.darkened(0.55) if locked else icon_col.darkened(0.25)
	icon_wrap.add_child(icon)
	vbox.add_child(icon_wrap)

	var lbl := Label.new()
	lbl.text = b["name"]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", LBL_LOCKED if locked else LBL_ACTIVE)
	vbox.add_child(lbl)

	return btn

func show_hud() -> void:
	show()

func hide_hud() -> void:
	hide()
