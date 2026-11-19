extends Control

## Enlarged, easy-to-read In-Game Store Screen using Coins (🪙) currency
## for buying and equipping the 4 Anti-Mole Tools and selecting Multimartillo patterns.

const MAIN_HUB_SCENE_PATH: String = "res://scenes/ui/main_hub.tscn"

@onready var safe_margin: MarginContainer = $SafeMargin
@onready var header_panel: PanelContainer = $SafeMargin/CenterWrap/StoreColumn/StoreHeader
@onready var back_btn: Button = $SafeMargin/CenterWrap/StoreColumn/StoreHeader/HeaderHBox/BackHubBtn
@onready var title_lbl: Label = $SafeMargin/CenterWrap/StoreColumn/StoreHeader/HeaderHBox/TitleVBox/StoreTitleLabel
@onready var subtitle_lbl: Label = $SafeMargin/CenterWrap/StoreColumn/StoreHeader/HeaderHBox/TitleVBox/StoreSubtitleLabel
@onready var points_badge_lbl: Label = $SafeMargin/CenterWrap/StoreColumn/StoreHeader/HeaderHBox/PointsBalanceLabel

@onready var pattern_panel: PanelContainer = $SafeMargin/CenterWrap/StoreColumn/PatternCard
@onready var pattern_title_lbl: Label = $SafeMargin/CenterWrap/StoreColumn/PatternCard/PatternVBox/PatternTitleLabel
@onready var pattern_buttons_hbox: HBoxContainer = $SafeMargin/CenterWrap/StoreColumn/PatternCard/PatternVBox/PatternButtonsHBox

@onready var tools_list_vbox: VBoxContainer = $SafeMargin/CenterWrap/StoreColumn/ToolsScroll/ToolsListVBox


func _ready() -> void:
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_styles()
	_refresh_store()

	LocalizationManager.language_changed.connect(_on_language_changed)
	GameManager.state_changed.connect(_refresh_store)
	back_btn.pressed.connect(_on_back_pressed)
	back_btn.grab_focus()


func _apply_safe_area() -> void:
	UIThemeBuilder.apply_device_safe_area(safe_margin, 30, 30, 30, 36)


func _apply_styles() -> void:
	header_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.12, 0.08, 0.05, 0.95), Color("#2ECC71"), 26, 4, 20)
	)
	pattern_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.14, 0.09, 0.16, 0.94), Color("#9B59B6"), 24, 4, 18)
	)

	title_lbl.label_settings = UIThemeBuilder.make_label_settings(40, Color("#58D68D"), 9)
	subtitle_lbl.label_settings = UIThemeBuilder.make_label_settings(24, Color("#E8F8F5"), 6)
	points_badge_lbl.label_settings = UIThemeBuilder.make_label_settings(36, Color("#FFE066"), 8)
	pattern_title_lbl.label_settings = UIThemeBuilder.make_label_settings(28, Color("#E8DAEF"), 7)

	UIThemeBuilder.apply_arcade_button_style(back_btn, Color("#6E4726"), Color("#422813"), Color.WHITE, 30, 20, 8)


func _refresh_store() -> void:
	back_btn.text = LocalizationManager.t("BTN_BACK_HUB")
	title_lbl.text = LocalizationManager.t("STORE_TITLE")
	subtitle_lbl.text = LocalizationManager.t("STORE_SUBTITLE")
	points_badge_lbl.text = "🪙 %s: %d" % [LocalizationManager.t("LBL_COINS"), GameManager.total_coins]
	pattern_title_lbl.text = "🔨 " + LocalizationManager.t("STORE_HAMMER_PATTERN_LABEL")

	_rebuild_pattern_selector()
	_rebuild_tool_cards()


func _rebuild_pattern_selector() -> void:
	for child: Node in pattern_buttons_hbox.get_children():
		child.queue_free()

	for p_def: Dictionary in GameManager.HAMMER_PATTERNS:
		var pat_id: String = String(p_def["id"])
		var is_selected: bool = (GameManager.multihammer_pattern == pat_id)

		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 74)
		btn.text = ("✓ " if is_selected else "") + LocalizationManager.t(String(p_def["label_key"]))
		UIThemeBuilder.apply_arcade_button_style(
			btn,
			Color("#8E44AD") if is_selected else Color("#3B2C42"),
			Color("#5B2C6F") if is_selected else Color("#241A29"),
			Color("#FFF59D") if is_selected else Color("#D7BDE2"),
			23,
			16,
			7
		)
		btn.pressed.connect(func() -> void:
			GameManager.set_hammer_pattern(pat_id)
		)
		pattern_buttons_hbox.add_child(btn)


func _rebuild_tool_cards() -> void:
	for child: Node in tools_list_vbox.get_children():
		child.queue_free()

	for tool_def: Dictionary in GameManager.TOOL_DEFINITIONS:
		var tool_id: String = String(tool_def["id"])
		var cost: int = int(tool_def["cost"])
		var accent: Color = tool_def["accent_color"]
		var owned: bool = GameManager.is_tool_owned(tool_id)
		var equipped: bool = (GameManager.equipped_tool == tool_id)
		var affordable: bool = GameManager.can_afford_tool(tool_id)

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 195)
		var border_col: Color = Color("#58D68D") if equipped else (accent if owned else Color("#8D6E63"))
		card.add_theme_stylebox_override(
			"panel",
			UIThemeBuilder.make_panel_style(
				Color(0.14, 0.10, 0.07, 0.96),
				border_col,
				26,
				4,
				22
			)
		)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 22)
		card.add_child(hbox)

		var icon_node: Control = UIThemeBuilder.build_tool_avatar_icon(tool_id, accent)
		icon_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(icon_node)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 10)
		hbox.add_child(info_vbox)

		var name_lbl := Label.new()
		name_lbl.text = LocalizationManager.t(String(tool_def["name_key"]))
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.label_settings = UIThemeBuilder.make_label_settings(38, accent.lightened(0.25), 8)
		info_vbox.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = LocalizationManager.t(String(tool_def["desc_key"]))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.label_settings = UIThemeBuilder.make_label_settings(27, Color("#FFF3E0"), 6)
		info_vbox.add_child(desc_lbl)

		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(285, 112)
		action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		if not owned:
			if affordable:
				action_btn.text = "🪙 " + LocalizationManager.t("BTN_BUY", {"cost": cost})
				UIThemeBuilder.apply_arcade_button_style(
					action_btn,
					Color("#FFB800"),
					Color("#B86B00"),
					Color("#FFFDF5"),
					32,
					22,
					9
				)
				action_btn.pressed.connect(func() -> void:
					GameManager.buy_tool(tool_id)
				)
			else:
				action_btn.text = "🪙 " + LocalizationManager.t("LBL_NOT_ENOUGH_PTS", {"cost": cost})
				action_btn.disabled = true
				UIThemeBuilder.apply_arcade_button_style(
					action_btn,
					Color("#4A443F"),
					Color("#2C2825"),
					Color("#BDC3C7"),
					28,
					22,
					8
				)
		else:
			if equipped:
				action_btn.text = LocalizationManager.t("BTN_EQUIPPED")
				UIThemeBuilder.apply_arcade_button_style(
					action_btn,
					Color("#27AE60"),
					Color("#196F3D"),
					Color.WHITE,
					32,
					22,
					9
				)
				action_btn.pressed.connect(func() -> void:
					GameManager.equip_tool("")
				)
			else:
				action_btn.text = LocalizationManager.t("BTN_EQUIP")
				UIThemeBuilder.apply_arcade_button_style(
					action_btn,
					Color("#2980B9"),
					Color("#1B4F72"),
					Color.WHITE,
					34,
					22,
					9
				)
				action_btn.pressed.connect(func() -> void:
					GameManager.equip_tool(tool_id)
				)

		hbox.add_child(action_btn)
		tools_list_vbox.add_child(card)


func _on_language_changed(_new_locale: String) -> void:
	_refresh_store()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_HUB_SCENE_PATH)
