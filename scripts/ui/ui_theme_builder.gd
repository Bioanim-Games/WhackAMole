class_name UIThemeBuilder
extends RefCounted

## Pure-Godot procedural styling, CJK-ready font builder, enlarged OptionButton
## popup styling, friendly Village background builder, and procedural tool icons.

static var _shared_font: SystemFont = null


static func get_ui_font() -> SystemFont:
	if _shared_font == null:
		_shared_font = SystemFont.new()
		_shared_font.font_names = PackedStringArray([
			"Segoe UI",
			"Roboto",
			"Noto Sans",
			"Noto Sans CJK SC",
			"Noto Sans CJK JP",
			"Noto Sans CJK KR",
			"Microsoft YaHei",
			"Yu Gothic UI",
			"Malgun Gothic",
			"Droid Sans Fallback",
			"Arial",
			"sans-serif",
		])
		_shared_font.font_weight = 800
	return _shared_font


static func make_label_settings(
	font_size: int,
	font_color: Color = Color.WHITE,
	outline_size: int = 8,
	outline_color: Color = Color("#180E07"),
	shadow_offset: Vector2 = Vector2(0, 4)
) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = get_ui_font()
	ls.font_size = font_size
	ls.font_color = font_color
	ls.outline_size = outline_size
	ls.outline_color = outline_color
	ls.shadow_size = 6
	ls.shadow_color = Color(0, 0, 0, 0.6)
	ls.shadow_offset = shadow_offset
	return ls


static func make_panel_style(
	bg_color: Color = Color(0.13, 0.09, 0.06, 0.94),
	border_color: Color = Color("#D99B26"),
	corner_radius: int = 24,
	border_width: int = 4,
	content_margin: int = 22
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = content_margin
	sb.content_margin_right = content_margin
	sb.content_margin_top = content_margin
	sb.content_margin_bottom = content_margin
	return sb


static func apply_arcade_button_style(
	btn: Button,
	fill_color: Color,
	lip_color: Color,
	text_color: Color = Color("#FFFDF7"),
	font_size: int = 40,
	corner_radius: int = 26,
	lip_height: int = 10
) -> void:
	btn.add_theme_font_override("font", get_ui_font())
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color.lightened(0.12))
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_focus_color", text_color)
	btn.add_theme_color_override("font_outline_color", Color("#1A0F06"))
	btn.add_theme_constant_override("outline_size", 8)

	var normal := StyleBoxFlat.new()
	normal.bg_color = fill_color
	normal.border_color = lip_color
	normal.set_border_width_all(4)
	normal.border_width_bottom = lip_height
	normal.set_corner_radius_all(corner_radius)
	normal.shadow_color = Color(0, 0, 0, 0.42)
	normal.shadow_size = 10
	normal.shadow_offset = Vector2(0, 5)
	normal.content_margin_left = 26
	normal.content_margin_right = 26
	normal.content_margin_top = 14
	normal.content_margin_bottom = 18

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = fill_color.lightened(0.1)
	hover.border_color = lip_color.lightened(0.12)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = fill_color.darkened(0.08)
	pressed.border_width_bottom = 4
	pressed.content_margin_top = 18
	pressed.content_margin_bottom = 14

	var focus: StyleBoxFlat = hover.duplicate()
	focus.border_color = Color("#FFF3A1")
	focus.set_border_width_all(5)
	focus.border_width_bottom = lip_height

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.28, 0.26, 0.24, 0.88)
	disabled.border_color = Color(0.18, 0.16, 0.15, 0.92)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_stylebox_override("disabled", disabled)


## Styles an OptionButton AND its PopupMenu so dropdown items are big (32px+) and easy to read.
static func style_option_button(opt: OptionButton, font_size: int = 32) -> void:
	opt.add_theme_font_override("font", get_ui_font())
	opt.add_theme_font_size_override("font_size", font_size)
	opt.add_theme_color_override("font_color", Color("#FFFDF5"))
	opt.add_theme_color_override("font_hover_color", Color("#FFE066"))
	opt.add_theme_color_override("font_outline_color", Color("#1A0F06"))
	opt.add_theme_constant_override("outline_size", 6)

	var sb := make_panel_style(Color(0.18, 0.12, 0.08, 0.96), Color("#FFB800"), 20, 3, 16)
	opt.add_theme_stylebox_override("normal", sb)
	opt.add_theme_stylebox_override("hover", sb)
	opt.add_theme_stylebox_override("pressed", sb)
	opt.add_theme_stylebox_override("focus", sb)

	var popup: PopupMenu = opt.get_popup()
	if popup != null:
		popup.add_theme_font_override("font", get_ui_font())
		popup.add_theme_font_size_override("font_size", font_size)
		popup.add_theme_color_override("font_color", Color("#FFFDF5"))
		popup.add_theme_color_override("font_hover_color", Color("#FFE066"))
		popup.add_theme_constant_override("v_separation", 20)
		var pop_sb := make_panel_style(Color(0.12, 0.08, 0.05, 0.98), Color("#FFB800"), 18, 4, 18)
		popup.add_theme_stylebox_override("panel", pop_sb)
		var hover_sb := make_panel_style(Color(0.32, 0.21, 0.10, 0.95), Color("#FFE066"), 12, 2, 8)
		popup.add_theme_stylebox_override("hover", hover_sb)


static func style_slider(slider: HSlider) -> void:
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color("#2C1C11")
	bg_sb.border_color = Color("#8D5B3C")
	bg_sb.set_border_width_all(3)
	bg_sb.set_corner_radius_all(12)
	bg_sb.content_margin_top = 14
	bg_sb.content_margin_bottom = 14
	slider.add_theme_stylebox_override("slider", bg_sb)

	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = Color("#58D68D")
	fill_sb.set_corner_radius_all(12)
	fill_sb.content_margin_top = 14
	fill_sb.content_margin_bottom = 14
	slider.add_theme_stylebox_override("grabber_area", fill_sb)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_sb)


## Builds a sunny, welcoming 2D Village background using 100% pure Godot nodes.
static func build_village_background() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = true

	# 1. Sunny Sky Gradient
	var sky_rect := TextureRect.new()
	sky_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sky_grad := Gradient.new()
	sky_grad.offsets = PackedFloat32Array([0.0, 0.45, 0.72, 1.0])
	sky_grad.colors = PackedColorArray([
		Color("#2FA4FF"),
		Color("#7DD3FC"),
		Color("#FEF08A"),
		Color("#4ADE80"),
	])
	var sky_tex := GradientTexture2D.new()
	sky_tex.gradient = sky_grad
	sky_tex.fill_from = Vector2(0.5, 0.0)
	sky_tex.fill_to = Vector2(0.5, 1.0)
	sky_rect.texture = sky_tex
	sky_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.add_child(sky_rect)

	# 2. Warm Golden Sun Disc
	var sun := Panel.new()
	sun.position = Vector2(90, 170)
	sun.size = Vector2(150, 150)
	sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sun_sb := StyleBoxFlat.new()
	sun_sb.bg_color = Color("#FACC15")
	sun_sb.border_color = Color("#FEF08A")
	sun_sb.set_border_width_all(10)
	sun_sb.set_corner_radius_all(75)
	sun_sb.shadow_color = Color(1.0, 0.88, 0.25, 0.55)
	sun_sb.shadow_size = 38
	sun.add_theme_stylebox_override("panel", sun_sb)
	root.add_child(sun)

	# 3. Fluffy Village Clouds
	var cloud_positions: Array[Vector2] = [
		Vector2(260, 210),
		Vector2(670, 165),
		Vector2(460, 310),
	]
	for i: int in range(cloud_positions.size()):
		var cloud := Panel.new()
		cloud.position = cloud_positions[i]
		cloud.size = Vector2(210 - i * 20, 74)
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var c_sb := StyleBoxFlat.new()
		c_sb.bg_color = Color(1.0, 1.0, 1.0, 0.88)
		c_sb.set_corner_radius_all(37)
		cloud.add_theme_stylebox_override("panel", c_sb)
		root.add_child(cloud)

	# 4. Distant Rolling Green Hills
	var back_hill := Polygon2D.new()
	back_hill.polygon = PackedVector2Array([
		Vector2(-100, 960),
		Vector2(180, 760),
		Vector2(540, 820),
		Vector2(880, 735),
		Vector2(1220, 860),
		Vector2(1220, 1960),
		Vector2(-100, 1960),
	])
	back_hill.color = Color("#4ADE80")
	root.add_child(back_hill)

	# 5. Foreground Village Lawn Meadow
	var front_meadow := Polygon2D.new()
	front_meadow.polygon = PackedVector2Array([
		Vector2(-100, 980),
		Vector2(340, 910),
		Vector2(760, 935),
		Vector2(1220, 895),
		Vector2(1220, 1960),
		Vector2(-100, 1960),
	])
	front_meadow.color = Color("#22C55E")
	root.add_child(front_meadow)

	# 6. Winding Dirt / Cobblestone Village Plaza Path
	var village_path := Polygon2D.new()
	village_path.polygon = PackedVector2Array([
		Vector2(440, 935),
		Vector2(640, 935),
		Vector2(860, 1960),
		Vector2(220, 1960),
	])
	village_path.color = Color("#D97706")
	root.add_child(village_path)

	# 7. Wooden Picket Fence across the Village Lawn
	for post_i: int in range(13):
		var post := Panel.new()
		post.position = Vector2(36 + post_i * 82, 855)
		post.size = Vector2(22, 75)
		post.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var p_sb := StyleBoxFlat.new()
		p_sb.bg_color = Color("#92400E")
		p_sb.border_color = Color("#78350F")
		p_sb.set_border_width_all(2)
		p_sb.corner_radius_top_left = 10
		p_sb.corner_radius_top_right = 10
		post.add_theme_stylebox_override("panel", p_sb)
		root.add_child(post)

	var fence_rail := Panel.new()
	fence_rail.position = Vector2(20, 882)
	fence_rail.size = Vector2(1040, 16)
	fence_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rail_sb := StyleBoxFlat.new()
	rail_sb.bg_color = Color("#B45309")
	rail_sb.border_color = Color("#78350F")
	rail_sb.set_border_width_all(2)
	fence_rail.add_theme_stylebox_override("panel", rail_sb)
	root.add_child(fence_rail)

	# 8. Left Cozy Village Cottage
	_add_village_cottage(
		root,
		Vector2(65, 670),
		Color("#FEF3C7"),
		Color("#EA580C"),
		Color("#78350F")
	)

	# 9. Right Village Shop Cottage
	_add_village_cottage(
		root,
		Vector2(765, 650),
		Color("#FDE68A"),
		Color("#0D9488"),
		Color("#92400E")
	)

	return root


static func _add_village_cottage(
	parent: Control,
	pos: Vector2,
	wall_color: Color,
	roof_color: Color,
	trim_color: Color
) -> void:
	var house_root := Control.new()
	house_root.position = pos
	house_root.size = Vector2(250, 260)
	house_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(house_root)

	# Chimney
	var chimney := Panel.new()
	chimney.position = Vector2(175, 10)
	chimney.size = Vector2(36, 75)
	chimney.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ch_sb := StyleBoxFlat.new()
	ch_sb.bg_color = Color("#991B1B")
	ch_sb.border_color = trim_color
	ch_sb.set_border_width_all(3)
	chimney.add_theme_stylebox_override("panel", ch_sb)
	house_root.add_child(chimney)

	# Cottage Wall
	var wall := Panel.new()
	wall.position = Vector2(25, 95)
	wall.size = Vector2(200, 155)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w_sb := StyleBoxFlat.new()
	w_sb.bg_color = wall_color
	w_sb.border_color = trim_color
	w_sb.set_border_width_all(5)
	w_sb.set_corner_radius_all(8)
	wall.add_theme_stylebox_override("panel", w_sb)
	house_root.add_child(wall)

	# Pitched Roof
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(0, 105),
		Vector2(125, 12),
		Vector2(250, 105),
	])
	roof.color = roof_color
	house_root.add_child(roof)

	# Wooden Door
	var door := Panel.new()
	door.position = Vector2(55, 155)
	door.size = Vector2(56, 95)
	door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var d_sb := StyleBoxFlat.new()
	d_sb.bg_color = trim_color
	d_sb.border_color = Color("#451A03")
	d_sb.set_border_width_all(4)
	d_sb.corner_radius_top_left = 26
	d_sb.corner_radius_top_right = 26
	door.add_theme_stylebox_override("panel", d_sb)
	house_root.add_child(door)

	# Warm Glowing Window
	var win := Panel.new()
	win.position = Vector2(135, 135)
	win.size = Vector2(62, 62)
	win.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var win_sb := StyleBoxFlat.new()
	win_sb.bg_color = Color("#FEF08A")
	win_sb.border_color = trim_color
	win_sb.set_border_width_all(5)
	win_sb.set_corner_radius_all(10)
	win.add_theme_stylebox_override("panel", win_sb)
	house_root.add_child(win)


## Builds a large, readable 124x124 pure-Godot procedural node icon for each Store Tool.
static func build_tool_avatar_icon(tool_id: String, accent_color: Color) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(124, 124)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color("#261910")
	bg_sb.border_color = accent_color
	bg_sb.set_border_width_all(4)
	bg_sb.set_corner_radius_all(26)
	bg.add_theme_stylebox_override("panel", bg_sb)
	root.add_child(bg)

	match tool_id:
		"drill":
			var tracks := Panel.new()
			tracks.position = Vector2(20, 78)
			tracks.size = Vector2(82, 22)
			tracks.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tr_sb := StyleBoxFlat.new()
			tr_sb.bg_color = Color("#2C3E50")
			tr_sb.border_color = Color("#95A5A6")
			tr_sb.set_border_width_all(3)
			tr_sb.set_corner_radius_all(10)
			tracks.add_theme_stylebox_override("panel", tr_sb)
			root.add_child(tracks)

			var hull := Panel.new()
			hull.position = Vector2(24, 40)
			hull.size = Vector2(50, 38)
			hull.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var hu_sb := StyleBoxFlat.new()
			hu_sb.bg_color = Color("#F39C12")
			hu_sb.set_corner_radius_all(8)
			hull.add_theme_stylebox_override("panel", hu_sb)
			root.add_child(hull)

			var cone := Polygon2D.new()
			cone.polygon = PackedVector2Array([
				Vector2(74, 40),
				Vector2(108, 59),
				Vector2(74, 78),
			])
			cone.color = Color("#ECF0F1")
			root.add_child(cone)

		"air_pump":
			var handle := Panel.new()
			handle.position = Vector2(30, 18)
			handle.size = Vector2(64, 14)
			handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ha_sb := StyleBoxFlat.new()
			ha_sb.bg_color = Color("#2C3E50")
			ha_sb.set_corner_radius_all(6)
			handle.add_theme_stylebox_override("panel", ha_sb)
			root.add_child(handle)

			var rod := Panel.new()
			rod.position = Vector2(57, 32)
			rod.size = Vector2(10, 22)
			rod.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ro_sb := StyleBoxFlat.new()
			ro_sb.bg_color = Color("#BDC3C7")
			rod.add_theme_stylebox_override("panel", ro_sb)
			root.add_child(rod)

			var cyl := Panel.new()
			cyl.position = Vector2(38, 52)
			cyl.size = Vector2(48, 54)
			cyl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var cy_sb := StyleBoxFlat.new()
			cy_sb.bg_color = Color("#E74C3C")
			cy_sb.border_color = Color("#FADBD8")
			cy_sb.set_border_width_all(3)
			cy_sb.set_corner_radius_all(10)
			cyl.add_theme_stylebox_override("panel", cy_sb)
			root.add_child(cyl)

		"multi_hammer":
			var shaft := Panel.new()
			shaft.position = Vector2(55, 56)
			shaft.size = Vector2(14, 50)
			shaft.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var sh_sb := StyleBoxFlat.new()
			sh_sb.bg_color = Color("#A04000")
			sh_sb.set_corner_radius_all(5)
			shaft.add_theme_stylebox_override("panel", sh_sb)
			root.add_child(shaft)

			for i: int in range(3):
				var head := Panel.new()
				head.position = Vector2(16 + i * 32, 24)
				head.size = Vector2(28, 34)
				head.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var hd_sb := StyleBoxFlat.new()
				hd_sb.bg_color = Color("#9B59B6")
				hd_sb.border_color = Color("#FFD700")
				hd_sb.set_border_width_all(3)
				hd_sb.set_corner_radius_all(8)
				head.add_theme_stylebox_override("panel", hd_sb)
				root.add_child(head)

		"water_hose":
			var drop := Polygon2D.new()
			drop.polygon = PackedVector2Array([
				Vector2(62, 18),
				Vector2(92, 62),
				Vector2(86, 92),
				Vector2(62, 102),
				Vector2(38, 92),
				Vector2(32, 62),
			])
			drop.color = Color("#3498DB")
			root.add_child(drop)

			var shine := Panel.new()
			shine.position = Vector2(46, 58)
			shine.size = Vector2(12, 22)
			shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var sn_sb := StyleBoxFlat.new()
			sn_sb.bg_color = Color("#D6EAF8")
			sn_sb.set_corner_radius_all(6)
			shine.add_theme_stylebox_override("panel", sn_sb)
			root.add_child(shine)

	return root
