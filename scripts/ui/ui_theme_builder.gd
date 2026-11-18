class_name UIThemeBuilder
extends RefCounted

## Pure-Godot procedural styling, CJK-ready font builder, and procedural node
## icon generator for moles and anti-mole tools.

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
		_shared_font.font_weight = 700
	return _shared_font


static func make_label_settings(
	font_size: int,
	font_color: Color = Color.WHITE,
	outline_size: int = 6,
	outline_color: Color = Color("#180E07"),
	shadow_offset: Vector2 = Vector2(0, 3)
) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = get_ui_font()
	ls.font_size = font_size
	ls.font_color = font_color
	ls.outline_size = outline_size
	ls.outline_color = outline_color
	ls.shadow_size = 4
	ls.shadow_color = Color(0, 0, 0, 0.55)
	ls.shadow_offset = shadow_offset
	return ls


static func make_panel_style(
	bg_color: Color = Color(0.13, 0.09, 0.06, 0.92),
	border_color: Color = Color("#D99B26"),
	corner_radius: int = 20,
	border_width: int = 3,
	content_margin: int = 18
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
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
	font_size: int = 24,
	corner_radius: int = 20
) -> void:
	btn.add_theme_font_override("font", get_ui_font())
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color.lightened(0.12))
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_focus_color", text_color)
	btn.add_theme_color_override("font_outline_color", Color("#1A0F06"))
	btn.add_theme_constant_override("outline_size", 6)

	var normal := StyleBoxFlat.new()
	normal.bg_color = fill_color
	normal.border_color = lip_color
	normal.set_border_width_all(3)
	normal.border_width_bottom = 8
	normal.set_corner_radius_all(corner_radius)
	normal.shadow_color = Color(0, 0, 0, 0.4)
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(0, 4)
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	normal.content_margin_top = 12
	normal.content_margin_bottom = 14

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = fill_color.lightened(0.1)
	hover.border_color = lip_color.lightened(0.12)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = fill_color.darkened(0.08)
	pressed.border_width_bottom = 4
	pressed.content_margin_top = 15
	pressed.content_margin_bottom = 11

	var focus: StyleBoxFlat = hover.duplicate()
	focus.border_color = Color("#FFF3A1")
	focus.set_border_width_all(4)
	focus.border_width_bottom = 8

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.28, 0.26, 0.24, 0.85)
	disabled.border_color = Color(0.18, 0.16, 0.15, 0.9)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_stylebox_override("disabled", disabled)


## Builds a pure-Godot procedural node avatar for any of the 5 Mole types.
static func build_mole_avatar_icon(mole_id: String, unlocked: bool) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(68, 68)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Outer circular frame
	var badge := Panel.new()
	badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = Color("#2C1C11") if unlocked else Color("#181412")
	badge_sb.border_color = Color("#FFB800") if unlocked else Color("#554B43")
	badge_sb.set_border_width_all(2)
	badge_sb.set_corner_radius_all(34)
	badge.add_theme_stylebox_override("panel", badge_sb)
	root.add_child(badge)

	# Dirt hole rim at bottom
	var hole := Panel.new()
	hole.position = Vector2(10, 48)
	hole.size = Vector2(48, 12)
	hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hole_sb := StyleBoxFlat.new()
	hole_sb.bg_color = Color("#4A2E1B") if unlocked else Color("#2B2420")
	hole_sb.set_corner_radius_all(6)
	hole.add_theme_stylebox_override("panel", hole_sb)
	root.add_child(hole)

	# Mole head body
	var body := Panel.new()
	body.position = Vector2(16, 18)
	body.size = Vector2(36, 36)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body_sb := StyleBoxFlat.new()
	if not unlocked:
		body_sb.bg_color = Color("#3A332E")
	elif mole_id == "dorado":
		body_sb.bg_color = Color("#FFD700")
	else:
		body_sb.bg_color = Color("#8D5B3C")
	body_sb.set_corner_radius_all(16)
	body.add_theme_stylebox_override("panel", body_sb)
	root.add_child(body)

	# Snout
	var snout := Panel.new()
	snout.position = Vector2(24, 33)
	snout.size = Vector2(20, 12)
	snout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var snout_sb := StyleBoxFlat.new()
	snout_sb.bg_color = (Color("#FFE875") if mole_id == "dorado" else Color("#C4946E")) if unlocked else Color("#4A423C")
	snout_sb.set_corner_radius_all(6)
	snout.add_theme_stylebox_override("panel", snout_sb)
	root.add_child(snout)

	# Aviator sunglasses (or clown red nose)
	var glasses := Panel.new()
	glasses.position = Vector2(19, 25)
	glasses.size = Vector2(30, 8)
	glasses.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glasses_sb := StyleBoxFlat.new()
	glasses_sb.bg_color = Color("#111111") if unlocked else Color("#262220")
	glasses_sb.set_corner_radius_all(3)
	glasses.add_theme_stylebox_override("panel", glasses_sb)
	root.add_child(glasses)

	if unlocked:
		match mole_id:
			"casco":
				# Yellow construction hard-hat dome
				var hat := Panel.new()
				hat.position = Vector2(13, 9)
				hat.size = Vector2(42, 16)
				hat.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var hat_sb := StyleBoxFlat.new()
				hat_sb.bg_color = Color("#FFCC00")
				hat_sb.border_color = Color("#CC9900")
				hat_sb.border_width_bottom = 3
				hat_sb.corner_radius_top_left = 16
				hat_sb.corner_radius_top_right = 16
				hat_sb.corner_radius_bottom_left = 4
				hat_sb.corner_radius_bottom_right = 4
				hat.add_theme_stylebox_override("panel", hat_sb)
				root.add_child(hat)
			"escudo":
				# Blue metallic overhead shield
				var shield := Panel.new()
				shield.position = Vector2(12, 8)
				shield.size = Vector2(44, 15)
				shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var sh_sb := StyleBoxFlat.new()
				sh_sb.bg_color = Color("#3498DB")
				sh_sb.border_color = Color("#D6EAF8")
				sh_sb.set_border_width_all(2)
				sh_sb.set_corner_radius_all(6)
				shield.add_theme_stylebox_override("panel", sh_sb)
				root.add_child(shield)
			"ninja":
				# Red ninja headband & mask
				var band := Panel.new()
				band.position = Vector2(15, 16)
				band.size = Vector2(38, 7)
				band.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var band_sb := StyleBoxFlat.new()
				band_sb.bg_color = Color("#E74C3C")
				band_sb.set_corner_radius_all(3)
				band.add_theme_stylebox_override("panel", band_sb)
				root.add_child(band)
			"payaso":
				# Red clown nose + pink balloon decoy dot
				var nose := Panel.new()
				nose.position = Vector2(30, 31)
				nose.size = Vector2(9, 9)
				nose.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var nose_sb := StyleBoxFlat.new()
				nose_sb.bg_color = Color("#FF2A55")
				nose_sb.set_corner_radius_all(5)
				nose.add_theme_stylebox_override("panel", nose_sb)
				root.add_child(nose)
			"dorado":
				# Golden crown / sparkle cap
				var crown := Panel.new()
				crown.position = Vector2(18, 8)
				crown.size = Vector2(32, 12)
				crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var cr_sb := StyleBoxFlat.new()
				cr_sb.bg_color = Color("#FFF176")
				cr_sb.border_color = Color("#F39C12")
				cr_sb.set_border_width_all(2)
				cr_sb.set_corner_radius_all(4)
				crown.add_theme_stylebox_override("panel", cr_sb)
				root.add_child(crown)

	return root


## Builds a pure-Godot procedural node illustration for each Store Tool.
static func build_tool_avatar_icon(tool_id: String, accent_color: Color) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(76, 76)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color("#261910")
	bg_sb.border_color = accent_color
	bg_sb.set_border_width_all(3)
	bg_sb.set_corner_radius_all(18)
	bg.add_theme_stylebox_override("panel", bg_sb)
	root.add_child(bg)

	match tool_id:
		"drill":
			# Tracked drill: caterpillar tracks + yellow hull + silver drill cone
			var tracks := Panel.new()
			tracks.position = Vector2(14, 48)
			tracks.size = Vector2(48, 12)
			tracks.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tr_sb := StyleBoxFlat.new()
			tr_sb.bg_color = Color("#2C3E50")
			tr_sb.border_color = Color("#7F8C8D")
			tr_sb.set_border_width_all(2)
			tr_sb.set_corner_radius_all(6)
			tracks.add_theme_stylebox_override("panel", tr_sb)
			root.add_child(tracks)

			var hull := Panel.new()
			hull.position = Vector2(16, 26)
			hull.size = Vector2(30, 22)
			hull.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var hu_sb := StyleBoxFlat.new()
			hu_sb.bg_color = Color("#F39C12")
			hu_sb.set_corner_radius_all(5)
			hull.add_theme_stylebox_override("panel", hu_sb)
			root.add_child(hull)

			var cone := Polygon2D.new()
			cone.polygon = PackedVector2Array([
				Vector2(46, 26),
				Vector2(66, 37),
				Vector2(46, 48),
			])
			cone.color = Color("#BDC3C7")
			root.add_child(cone)

		"air_pump":
			# Manual air pump: T-handle + piston rod + red pump cylinder
			var handle := Panel.new()
			handle.position = Vector2(20, 12)
			handle.size = Vector2(36, 8)
			handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ha_sb := StyleBoxFlat.new()
			ha_sb.bg_color = Color("#2C3E50")
			ha_sb.set_corner_radius_all(4)
			handle.add_theme_stylebox_override("panel", ha_sb)
			root.add_child(handle)

			var rod := Panel.new()
			rod.position = Vector2(35, 20)
			rod.size = Vector2(6, 14)
			rod.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ro_sb := StyleBoxFlat.new()
			ro_sb.bg_color = Color("#BDC3C7")
			rod.add_theme_stylebox_override("panel", ro_sb)
			root.add_child(rod)

			var cyl := Panel.new()
			cyl.position = Vector2(25, 32)
			cyl.size = Vector2(26, 32)
			cyl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var cy_sb := StyleBoxFlat.new()
			cy_sb.bg_color = Color("#E74C3C")
			cy_sb.border_color = Color("#FADBD8")
			cy_sb.set_border_width_all(2)
			cy_sb.set_corner_radius_all(6)
			cyl.add_theme_stylebox_override("panel", cy_sb)
			root.add_child(cyl)

		"multi_hammer":
			# 3-headed hammer: wooden handle + 3 purple/gold strike heads
			var shaft := Panel.new()
			shaft.position = Vector2(34, 34)
			shaft.size = Vector2(8, 30)
			shaft.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var sh_sb := StyleBoxFlat.new()
			sh_sb.bg_color = Color("#A04000")
			sh_sb.set_corner_radius_all(3)
			shaft.add_theme_stylebox_override("panel", sh_sb)
			root.add_child(shaft)

			for i: int in range(3):
				var head := Panel.new()
				head.position = Vector2(11 + i * 19, 16)
				head.size = Vector2(16, 20)
				head.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var hd_sb := StyleBoxFlat.new()
				hd_sb.bg_color = Color("#9B59B6")
				hd_sb.border_color = Color("#FFD700")
				hd_sb.set_border_width_all(2)
				hd_sb.set_corner_radius_all(5)
				head.add_theme_stylebox_override("panel", hd_sb)
				root.add_child(head)

		"water_hose":
			# Water balloon / splash droplet
			var drop := Polygon2D.new()
			drop.polygon = PackedVector2Array([
				Vector2(38, 12),
				Vector2(56, 38),
				Vector2(52, 56),
				Vector2(38, 62),
				Vector2(24, 56),
				Vector2(20, 38),
			])
			drop.color = Color("#3498DB")
			root.add_child(drop)

			var shine := Panel.new()
			shine.position = Vector2(28, 36)
			shine.size = Vector2(8, 14)
			shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var sn_sb := StyleBoxFlat.new()
			sn_sb.bg_color = Color("#D6EAF8")
			sn_sb.set_corner_radius_all(4)
			shine.add_theme_stylebox_override("panel", sn_sb)
			root.add_child(shine)

	return root
