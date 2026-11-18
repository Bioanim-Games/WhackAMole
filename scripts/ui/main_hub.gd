extends Control

## Main Hub Screen displaying Player Rank, Points, PvZ-style 1-to-3 Lane Lawn
## progression, the 5 Mole types (+1, +2, +3, +4 unlock schedule), Play & Store
## navigation, and an interactive progression simulator.

const TITLE_SCENE_PATH: String = "res://scenes/ui/title_screen.tscn"
const STORE_SCENE_PATH: String = "res://scenes/ui/store_screen.tscn"

@onready var top_bar_panel: PanelContainer = $SafeMargin/CenterWrap/MainColumn/TopStatusBar
@onready var back_title_btn: Button = $SafeMargin/CenterWrap/MainColumn/TopStatusBar/TopHBox/BackToTitleBtn
@onready var rank_label: Label = $SafeMargin/CenterWrap/MainColumn/TopStatusBar/TopHBox/RankBadge
@onready var points_label: Label = $SafeMargin/CenterWrap/MainColumn/TopStatusBar/TopHBox/PointsBadge
@onready var matches_label: Label = $SafeMargin/CenterWrap/MainColumn/TopStatusBar/TopHBox/MatchesBadge
@onready var lang_option: OptionButton = $SafeMargin/CenterWrap/MainColumn/TopStatusBar/TopHBox/LanguageOptionButton

@onready var progression_panel: PanelContainer = $SafeMargin/CenterWrap/MainColumn/ProgressionCard
@onready var progression_title_lbl: Label = $SafeMargin/CenterWrap/MainColumn/ProgressionCard/ProgVBox/ProgressionTitle
@onready var lawn_status_lbl: Label = $SafeMargin/CenterWrap/MainColumn/ProgressionCard/ProgVBox/LawnStatusLabel
@onready var lanes_container: VBoxContainer = $SafeMargin/CenterWrap/MainColumn/ProgressionCard/ProgVBox/PvZLanesBox
@onready var moles_row: HBoxContainer = $SafeMargin/CenterWrap/MainColumn/ProgressionCard/ProgVBox/MoleRosterScroll/MoleRosterRow
@onready var next_unlock_lbl: Label = $SafeMargin/CenterWrap/MainColumn/ProgressionCard/ProgVBox/NextUnlockLabel

@onready var difficulty_panel: PanelContainer = $SafeMargin/CenterWrap/MainColumn/DifficultyCard
@onready var diff_title_lbl: Label = $SafeMargin/CenterWrap/MainColumn/DifficultyCard/DiffVBox/DiffTitleLabel
@onready var diff_info_lbl: Label = $SafeMargin/CenterWrap/MainColumn/DifficultyCard/DiffVBox/DiffInfoLabel
@onready var diff_note_lbl: Label = $SafeMargin/CenterWrap/MainColumn/DifficultyCard/DiffVBox/DiffNoteLabel

@onready var play_btn: Button = $SafeMargin/CenterWrap/MainColumn/ActionsBox/PlayMatchButton
@onready var store_btn: Button = $SafeMargin/CenterWrap/MainColumn/ActionsBox/OpenStoreButton

@onready var sim_panel: PanelContainer = $SafeMargin/CenterWrap/MainColumn/SimTestBar
@onready var sim_title_lbl: Label = $SafeMargin/CenterWrap/MainColumn/SimTestBar/SimHBox/SimTitleLabel
@onready var sim_win_btn: Button = $SafeMargin/CenterWrap/MainColumn/SimTestBar/SimHBox/SimWinButton
@onready var sim_reset_btn: Button = $SafeMargin/CenterWrap/MainColumn/SimTestBar/SimHBox/SimResetButton

@onready var preview_modal_backdrop: ColorRect = $StagePreviewBackdrop
@onready var preview_modal_card: PanelContainer = $StagePreviewBackdrop/ModalCenter/StagePreviewModal
@onready var modal_title_lbl: Label = $StagePreviewBackdrop/ModalCenter/StagePreviewModal/ModalVBox/ModalTitleLabel
@onready var modal_desc_lbl: Label = $StagePreviewBackdrop/ModalCenter/StagePreviewModal/ModalVBox/ModalDescLabel
@onready var modal_sim_win_btn: Button = $StagePreviewBackdrop/ModalCenter/StagePreviewModal/ModalVBox/ModalButtonsHBox/ModalSimVictoryBtn
@onready var modal_close_btn: Button = $StagePreviewBackdrop/ModalCenter/StagePreviewModal/ModalVBox/ModalButtonsHBox/ModalCloseBtn


func _ready() -> void:
	_apply_styles()
	_populate_language_selector()
	_refresh_all()

	LocalizationManager.language_changed.connect(_on_language_changed)
	GameManager.state_changed.connect(_refresh_all)

	back_title_btn.pressed.connect(_on_back_to_title)
	lang_option.item_selected.connect(_on_language_selected)
	play_btn.pressed.connect(_on_play_pressed)
	store_btn.pressed.connect(_on_store_pressed)
	sim_win_btn.pressed.connect(_on_sim_win_pressed)
	sim_reset_btn.pressed.connect(_on_sim_reset_pressed)
	modal_sim_win_btn.pressed.connect(_on_modal_sim_win_pressed)
	modal_close_btn.pressed.connect(_on_modal_close_pressed)

	play_btn.grab_focus()


func _apply_styles() -> void:
	top_bar_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.12, 0.08, 0.05, 0.94), Color("#D49B35"), 18, 3, 14)
	)
	progression_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.11, 0.08, 0.05, 0.92), Color("#58D68D"), 22, 3, 18)
	)
	difficulty_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.14, 0.09, 0.06, 0.92), Color("#F39C12"), 20, 3, 16)
	)
	sim_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.1, 0.12, 0.16, 0.92), Color("#5DADE2"), 16, 2, 12)
	)
	preview_modal_card.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.11, 0.07, 0.04, 0.98), Color("#FFB800"), 24, 4, 24)
	)

	rank_label.label_settings = UIThemeBuilder.make_label_settings(19, Color("#FFE066"), 5)
	points_label.label_settings = UIThemeBuilder.make_label_settings(19, Color("#58D68D"), 5)
	matches_label.label_settings = UIThemeBuilder.make_label_settings(18, Color("#D6EAF8"), 5)

	progression_title_lbl.label_settings = UIThemeBuilder.make_label_settings(22, Color("#58D68D"), 6)
	lawn_status_lbl.label_settings = UIThemeBuilder.make_label_settings(17, Color("#FFF3C4"), 5)
	next_unlock_lbl.label_settings = UIThemeBuilder.make_label_settings(17, Color("#FFB800"), 5)

	diff_title_lbl.label_settings = UIThemeBuilder.make_label_settings(20, Color("#FFB800"), 6)
	diff_info_lbl.label_settings = UIThemeBuilder.make_label_settings(17, Color("#FFFFFF"), 5)
	diff_note_lbl.label_settings = UIThemeBuilder.make_label_settings(15, Color("#E5D4B8"), 4)

	sim_title_lbl.label_settings = UIThemeBuilder.make_label_settings(15, Color("#AED6F1"), 4)
	modal_title_lbl.label_settings = UIThemeBuilder.make_label_settings(26, Color("#FFE047"), 8)
	modal_desc_lbl.label_settings = UIThemeBuilder.make_label_settings(18, Color("#FFF7E6"), 5)

	UIThemeBuilder.apply_arcade_button_style(back_title_btn, Color("#5D4037"), Color("#3E2723"), Color.WHITE, 16, 14)
	UIThemeBuilder.apply_arcade_button_style(play_btn, Color("#FFB800"), Color("#B86B00"), Color("#FFFDF5"), 26, 22)
	UIThemeBuilder.apply_arcade_button_style(store_btn, Color("#27AE60"), Color("#196F3D"), Color.WHITE, 22, 20)
	UIThemeBuilder.apply_arcade_button_style(sim_win_btn, Color("#2980B9"), Color("#1B4F72"), Color.WHITE, 15, 12)
	UIThemeBuilder.apply_arcade_button_style(sim_reset_btn, Color("#7F8C8D"), Color("#4D5656"), Color.WHITE, 15, 12)
	UIThemeBuilder.apply_arcade_button_style(modal_sim_win_btn, Color("#27AE60"), Color("#196F3D"), Color.WHITE, 20, 16)
	UIThemeBuilder.apply_arcade_button_style(modal_close_btn, Color("#C0392B"), Color("#7B241C"), Color.WHITE, 18, 16)

	lang_option.add_theme_font_override("font", UIThemeBuilder.get_ui_font())
	lang_option.add_theme_font_size_override("font_size", 15)


func _populate_language_selector() -> void:
	lang_option.clear()
	var locales: Array[Dictionary] = LocalizationManager.get_supported_locales()
	for i: int in range(locales.size()):
		lang_option.add_item(String(locales[i]["label"]), i)
	lang_option.select(LocalizationManager.get_current_locale_index())


func _refresh_all() -> void:
	var stage_num: int = GameManager.get_current_stage_number()
	var exposure_sec: float = GameManager.get_current_mole_exposure_seconds()
	var active_holes: int = GameManager.get_active_holes_count()
	var unlocked_lanes: int = GameManager.get_unlocked_lanes_count()
	var tool_name: String = GameManager.get_equipped_tool_display_name()

	back_title_btn.text = LocalizationManager.t("BTN_BACK_TITLE")
	rank_label.text = "⭐ %s: %d" % [LocalizationManager.t("LBL_RANK"), GameManager.player_rank]
	points_label.text = "🪙 %s: %d" % [LocalizationManager.t("LBL_POINTS"), GameManager.total_points]
	matches_label.text = "🎮 %s: %d" % [LocalizationManager.t("LBL_MATCHES"), GameManager.matches_completed]

	progression_title_lbl.text = LocalizationManager.t("HUB_PROGRESSION_TITLE")
	if unlocked_lanes == 1:
		lawn_status_lbl.text = LocalizationManager.t("HUB_LAWN_STATUS_1")
	elif unlocked_lanes == 2:
		lawn_status_lbl.text = LocalizationManager.t("HUB_LAWN_STATUS_2")
	else:
		lawn_status_lbl.text = LocalizationManager.t("HUB_LAWN_STATUS_3")

	_rebuild_pvz_lanes_visualizer()
	_rebuild_mole_roster_cards(exposure_sec)

	var next_info: Dictionary = GameManager.get_next_locked_mole_info()
	if next_info.is_empty():
		next_unlock_lbl.text = LocalizationManager.t("HUB_ALL_MOLES_UNLOCKED")
	else:
		var mole_def: Dictionary = next_info["mole"]
		var mole_name: String = LocalizationManager.t(String(mole_def["name_key"]))
		next_unlock_lbl.text = LocalizationManager.t(
			"HUB_NEXT_MOLE_IN",
			{"mole": mole_name, "count": int(next_info["matches_remaining"])}
		)

	diff_title_lbl.text = LocalizationManager.t("HUB_DIFFICULTY_CARD_TITLE")
	diff_info_lbl.text = LocalizationManager.t(
		"HUB_DIFFICULTY_INFO",
		{
			"time": "%.1f" % exposure_sec,
			"holes": active_holes,
			"tool": tool_name,
		}
	)
	diff_note_lbl.text = LocalizationManager.t(
		"HUB_INTRO_NOTE",
		{"time": "%.1f" % exposure_sec}
	)

	play_btn.text = LocalizationManager.t("BTN_PLAY_MATCH", {"level": stage_num})
	store_btn.text = LocalizationManager.t("BTN_OPEN_STORE")

	sim_title_lbl.text = LocalizationManager.t("SIM_BAR_TITLE")
	sim_win_btn.text = LocalizationManager.t("BTN_SIM_WIN")
	sim_reset_btn.text = LocalizationManager.t("BTN_SIM_RESET")

	# Refresh modal text as well
	var featured_mole: Dictionary = GameManager.get_featured_mole_for_current_stage()
	var featured_name: String = LocalizationManager.t(String(featured_mole["name_key"]))
	modal_title_lbl.text = LocalizationManager.t("MODAL_READY_TITLE", {"level": stage_num})
	modal_desc_lbl.text = LocalizationManager.t(
		"MODAL_READY_DESC",
		{
			"lanes": unlocked_lanes,
			"holes": active_holes,
			"featured_mole": featured_name,
			"time": "%.1f" % exposure_sec,
			"tool": tool_name,
		}
	)
	modal_sim_win_btn.text = LocalizationManager.t("BTN_MODAL_SIM_VICTORY")
	modal_close_btn.text = LocalizationManager.t("BTN_MODAL_CLOSE")


## Renders the Plants vs. Zombies style 3-row lawn matrix showing unlocked rows
## (with 3 dirt holes each) vs locked uncut-turf rows.
func _rebuild_pvz_lanes_visualizer() -> void:
	for child: Node in lanes_container.get_children():
		child.queue_free()

	var row_flags: Array[bool] = GameManager.get_active_lane_rows()
	for row_idx: int in range(3):
		var is_active: bool = row_flags[row_idx]
		var lane_panel := PanelContainer.new()
		lane_panel.custom_minimum_size = Vector2(0, 46)
		var sb := StyleBoxFlat.new()
		if is_active:
			sb.bg_color = Color("#1E6B38")
			sb.border_color = Color("#58D68D")
		else:
			sb.bg_color = Color(0.11, 0.16, 0.12, 0.78)
			sb.border_color = Color("#34495E")
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(12)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		lane_panel.add_theme_stylebox_override("panel", sb)

		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_BETWEEN
		lane_panel.add_child(hbox)

		var status_lbl := Label.new()
		status_lbl.text = (
			"🌱 #%d — %s" % [row_idx + 1, LocalizationManager.t("HUB_LANE_ACTIVE")]
			if is_active
			else "🔒 #%d — %s" % [row_idx + 1, LocalizationManager.t("HUB_LANE_LOCKED")]
		)
		status_lbl.label_settings = UIThemeBuilder.make_label_settings(
			15,
			Color("#EAFAF1") if is_active else Color("#95A5A6"),
			4
		)
		hbox.add_child(status_lbl)

		var holes_hbox := HBoxContainer.new()
		holes_hbox.add_theme_constant_override("separation", 14)
		for col_idx: int in range(3):
			var hole_dot := Panel.new()
			hole_dot.custom_minimum_size = Vector2(44, 24)
			var h_sb := StyleBoxFlat.new()
			if is_active:
				h_sb.bg_color = Color("#3B2314")
				h_sb.border_color = Color("#C4946E")
			else:
				h_sb.bg_color = Color("#1C2820")
				h_sb.border_color = Color("#2E4034")
			h_sb.set_border_width_all(2)
			h_sb.set_corner_radius_all(12)
			hole_dot.add_theme_stylebox_override("panel", h_sb)
			holes_hbox.add_child(hole_dot)
		hbox.add_child(holes_hbox)

		lanes_container.add_child(lane_panel)


## Builds the 5 Mole Progression Cards (+1, +2, +3, +4 triangular unlock schedule).
func _rebuild_mole_roster_cards(exposure_sec: float) -> void:
	for child: Node in moles_row.get_children():
		child.queue_free()

	for mole_def: Dictionary in GameManager.MOLE_DEFINITIONS:
		var mole_id: String = String(mole_def["id"])
		var unlocked: bool = GameManager.is_mole_unlocked(mole_id)
		var accent: Color = mole_def["accent_color"]

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(215, 195)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_sb := UIThemeBuilder.make_panel_style(
			Color(0.16, 0.11, 0.07, 0.95) if unlocked else Color(0.1, 0.09, 0.09, 0.85),
			accent if unlocked else Color("#4A443F"),
			16,
			3,
			12
		)
		card.add_theme_stylebox_override("panel", card_sb)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		card.add_child(vbox)

		var top_row := HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 10)
		vbox.add_child(top_row)

		var avatar: Control = UIThemeBuilder.build_mole_avatar_icon(mole_id, unlocked)
		top_row.add_child(avatar)

		var title_col := VBoxContainer.new()
		title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(title_col)

		var name_lbl := Label.new()
		name_lbl.text = LocalizationManager.t(String(mole_def["name_key"]))
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.label_settings = UIThemeBuilder.make_label_settings(
			16,
			accent.lightened(0.25) if unlocked else Color("#95A5A6"),
			4
		)
		title_col.add_child(name_lbl)

		var badge_lbl := Label.new()
		if unlocked:
			badge_lbl.text = "✓ " + LocalizationManager.t("MOLE_UNLOCKED")
			badge_lbl.label_settings = UIThemeBuilder.make_label_settings(13, Color("#58D68D"), 3)
		else:
			badge_lbl.text = "🔒 " + LocalizationManager.t(
				"MOLE_LOCKED_GAMES",
				{"game": int(mole_def["first_game_number"])}
			)
			badge_lbl.label_settings = UIThemeBuilder.make_label_settings(13, Color("#F39C12"), 3)
		title_col.add_child(badge_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = LocalizationManager.t(
			String(mole_def["desc_key"]),
			{"time": "%.1f" % exposure_sec}
		)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc_lbl.label_settings = UIThemeBuilder.make_label_settings(
			13,
			Color("#F5E6D3") if unlocked else Color("#7F8C8D"),
			3
		)
		vbox.add_child(desc_lbl)

		moles_row.add_child(card)


func _on_language_selected(index: int) -> void:
	var locales: Array[Dictionary] = LocalizationManager.get_supported_locales()
	if index >= 0 and index < locales.size():
		LocalizationManager.set_locale(String(locales[index]["code"]), true)


func _on_language_changed(_new_locale: String) -> void:
	lang_option.select(LocalizationManager.get_current_locale_index())
	_refresh_all()


func _on_back_to_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)


func _on_play_pressed() -> void:
	preview_modal_backdrop.visible = true
	modal_sim_win_btn.grab_focus()


func _on_store_pressed() -> void:
	get_tree().change_scene_to_file(STORE_SCENE_PATH)


func _on_sim_win_pressed() -> void:
	GameManager.record_match_completed(150)


func _on_sim_reset_pressed() -> void:
	GameManager.reset_progress()


func _on_modal_sim_win_pressed() -> void:
	GameManager.record_match_completed(150)
	preview_modal_backdrop.visible = false
	play_btn.grab_focus()


func _on_modal_close_pressed() -> void:
	preview_modal_backdrop.visible = false
	play_btn.grab_focus()
