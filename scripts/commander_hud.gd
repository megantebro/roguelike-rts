extends CanvasLayer

const BUILD_OPTIONS := [
	{"name": "Metal\nExtractor",  "color": Color(0.2, 0.5, 0.8)},
	{"name": "Power\nGenerator",  "color": Color(0.65, 0.65, 0.15)},
]

func _ready() -> void:
	layer = 5
	_build_ui()
	hide()

func _build_ui() -> void:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.custom_minimum_size = Vector2(0, 130)
	panel.offset_top = -130
	panel.offset_bottom = 0

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 0.93)
	bg.border_width_top = 2
	bg.border_color = Color(0.35, 0.35, 0.45)
	panel.add_theme_stylebox_override("panel", bg)
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	for opt in BUILD_OPTIONS:
		hbox.add_child(_make_button(opt))

func _make_button(opt: Dictionary) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(88, 110)
	btn.text = opt["name"]
	btn.add_theme_font_size_override("font_size", 12)

	var normal := StyleBoxFlat.new()
	normal.bg_color = opt["color"].darkened(0.35)
	normal.border_width_left   = 1
	normal.border_width_right  = 1
	normal.border_width_top    = 1
	normal.border_width_bottom = 1
	normal.border_color = opt["color"]
	normal.corner_radius_top_left    = 4
	normal.corner_radius_top_right   = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = opt["color"].darkened(0.1)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = opt["color"].lightened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed)

	return btn

func show_hud() -> void:
	show()

func hide_hud() -> void:
	hide()
