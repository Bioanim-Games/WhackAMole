extends Control

## Illustrated Village Main Hub featuring village_hub_bg.jpg, front-camera safe-area
## detection, rustic oak Top Bar with Points (🏆) & Coins (🪙), and compact
## rustic timber/tavern-sign buttons nestled inside the bottom sandy clearing.

const TITLE_SCENE_PATH: String = "res://scenes/ui/title_screen.tscn"
const STORE_SCENE_PATH: String = "res://scenes/ui/store_screen.tscn"
const ARENA_SCENE_PATH: String = "res://scenes/game/arena_2_5d.tscn"
const VILLAGE_BG_PATH: String = "res://assets/art/village_hub_bg.jpg"

@onready var village_hero_art: TextureRect = $VillageHeroArt
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var top_bar_panel: PanelContainer = $SafeMargin/CenterWrap/MainColumn/TopStatusBar
@onready var back_title_btn: Button = $SafeMargin/CenterWrap/MainColumn/TopStatusBar/TopHBox/BackToTitleBtn
@onready var points_badge_panel: PanelContainer = $SafeMargin/CenterWrap/MainColumn/TopStatusBar/TopHBox/PointsBadgePanel
@onready var points_label: Label = $SafeMargin/CenterWrap/MainColumn/TopStatusBar/TopHBox/PointsBadgePanel/PointsBadge
@onready var coins_badge_panel: PanelContainer = $SafeMargin/CenterWrap/MainColumn/TopStatusBar/TopHBox/CoinsBadgePanel
@onready var coins_label: Label = $SafeMargin/CenterWrap/MainColumn/TopStatusBar/TopHBox/CoinsBadgePanel/CoinsBadge

@onready var play_btn: Button = $SafeMargin/CenterWrap/MainColumn/ClearingButtonsWrap/MenuButtonsBox/PlayMatchButton
@onready var store_btn: Button = $SafeMargin/CenterWrap/MainColumn/ClearingButtonsWrap/MenuButtonsBox/OpenStoreButton
@onready var profile_btn: Button = $SafeMargin/CenterWrap/MainColumn/ClearingButtonsWrap/MenuButtonsBox/SecondaryRowHBox/OpenProfileButton
@onready var settings_btn: Button = $SafeMargin/CenterWrap/MainColumn/ClearingButtonsWrap/MenuButtonsBox/SecondaryRowHBox/OpenSettingsButton

@onready var info_modal_backdrop: ColorRect = $InfoModalBackdrop
@onready var info_modal_card: PanelContainer = $InfoModalBackdrop/ModalCenter/InfoModalCard
@onready var info_title_lbl: Label = $InfoModalBackdrop/ModalCenter/InfoModalCard/ModalVBox/InfoTitleLabel
@onready var info_desc_lbl: Label = $InfoModalBackdrop/ModalCenter/InfoModalCard/ModalVBox/InfoDescLabel
@onready var info_reward_btn: Button = $InfoModalBackdrop/ModalCenter/InfoModalCard/ModalVBox/InfoRewardBtn
@onready var info_close_btn: Button = $InfoModalBackdrop/ModalCenter/InfoModalCard/ModalVBox/InfoCloseBtn

@onready var settings_backdrop: ColorRect = $SettingsBackdrop
@onready var settings_modal: PanelContainer = $SettingsBackdrop/ModalCenter/SettingsModal
@onready var settings_title_lbl: Label = $SettingsBackdrop/ModalCenter/SettingsModal/SettingsVBox/SettingsTitleLabel
@onready var lang_title_lbl: Label = $SettingsBackdrop/ModalCenter/SettingsModal/SettingsVBox/LangRow/LangTitleLabel
@onready var lang_option: OptionButton = $SettingsBackdrop/ModalCenter/SettingsModal/SettingsVBox/LangRow/LanguageOptionButton
@onready var music_label: Label = $SettingsBackdrop/ModalCenter/SettingsModal/SettingsVBox/MusicRow/MusicHeaderHBox/MusicLabel
@onready var music_toggle_btn: Button = $SettingsBackdrop/ModalCenter/SettingsModal/SettingsVBox/MusicRow/MusicHeaderHBox/MusicToggleBtn
@onready var music_slider: HSlider = $SettingsBackdrop/ModalCenter/SettingsModal/SettingsVBox/MusicRow/MusicSlider
@onready var sfx_label: Label = $SettingsBackdrop/ModalCenter/SettingsModal/SettingsVBox/SfxRow/SfxHeaderHBox/SfxLabel
@onready var sfx_toggle_btn: Button = $SettingsBackdrop/ModalCenter/SettingsModal/SettingsVBox/SfxRow/SfxHeaderHBox/SfxToggleBtn
@onready var sfx_slider: HSlider = $SettingsBackdrop/ModalCenter/SettingsModal/SettingsVBox/SfxRow/SfxSlider
@onready var close_settings_btn: Button = $SettingsBackdrop/ModalCenter/SettingsModal/SettingsVBox/CloseSettingsButton


func _ready() -> void:
	if ResourceLoader.exists(VILLAGE_BG_PATH):
		village_hero_art.texture = ResourceLoader.load(VILLAGE_BG_PATH) as Texture2D
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_styles()
	_populate_language_selector()
	_sync_audio_controls()
	_refresh_all()

	LocalizationManager.language_changed.connect(_on_language_changed)
	GameManager.state_changed.connect(_on_state_changed)

	back_title_btn.pressed.connect(_on_back_to_title)
	play_btn.pressed.connect(_on_play_pressed)
	store_btn.pressed.connect(_on_store_pressed)
	profile_btn.pressed.connect(_on_profile_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)

	info_reward_btn.pressed.connect(_on_info_reward_pressed)
	info_close_btn.pressed.connect(_on_info_close_pressed)

	close_settings_btn.pressed.connect(_on_close_settings_pressed)
	lang_option.item_selected.connect(_on_language_selected)
	music_toggle_btn.pressed.connect(_on_music_toggle_pressed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_toggle_btn.pressed.connect(_on_sfx_toggle_pressed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	play_btn.grab_focus()


func _apply_safe_area() -> void:
	UIThemeBuilder.apply_device_safe_area(safe_margin, 28, 36, 28, 48)


func _apply_styles() -> void:
	top_bar_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.17, 0.09, 0.04, 0.92), Color("#D99B26"), 26, 4, 14)
	)
	points_badge_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.26, 0.15, 0.08, 0.96), Color("#E5A93B"), 22, 3, 12)
	)
	coins_badge_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.26, 0.15, 0.08, 0.96), Color("#FFB800"), 22, 3, 12)
	)
	info_modal_card.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.14, 0.08, 0.04, 0.98), Color("#FFB800"), 30, 5, 32)
	)
	settings_modal.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.14, 0.08, 0.04, 0.98), Color("#FFB800"), 30, 5, 32)
	)

	points_label.label_settings = UIThemeBuilder.make_label_settings(32, Color("#FFF3C4"), 8, Color("#231208"))
	coins_label.label_settings = UIThemeBuilder.make_label_settings(32, Color("#FFE066"), 8, Color("#231208"))

	info_title_lbl.label_settings = UIThemeBuilder.make_label_settings(44, Color("#FFE047"), 10)
	info_desc_lbl.label_settings = UIThemeBuilder.make_label_settings(32, Color("#FFF7E6"), 7)

	settings_title_lbl.label_settings = UIThemeBuilder.make_label_settings(46, Color("#FFE047"), 10)
	lang_title_lbl.label_settings = UIThemeBuilder.make_label_settings(34, Color("#FFF3C4"), 7)
	music_label.label_settings = UIThemeBuilder.make_label_settings(34, Color("#58D68D"), 7)
	sfx_label.label_settings = UIThemeBuilder.make_label_settings(34, Color("#5DADE2"), 7)

	# Floating 3D Golden/Amber Comic Letters without rectangle boxes (matched to start_button.jpg)
	UIThemeBuilder.apply_floating_letter_button_style(back_title_btn, 36, Color("#FFE600"), Color("#5E1904"), 14)
	UIThemeBuilder.apply_floating_letter_button_style(play_btn, 76, Color("#FFE600"), Color("#7A1F04"), 22)
	UIThemeBuilder.apply_floating_letter_button_style(store_btn, 58, Color("#FFCC00"), Color("#6E1B04"), 18)
	UIThemeBuilder.apply_floating_letter_button_style(profile_btn, 42, Color("#FFE666"), Color("#5E1904"), 15)
	UIThemeBuilder.apply_floating_letter_button_style(settings_btn, 42, Color("#FFE666"), Color("#5E1904"), 15)

	UIThemeBuilder.apply_arcade_button_style(info_reward_btn, Color("#27AE60"), Color("#196F3D"), Color.WHITE, 34, 22, 9)
	UIThemeBuilder.apply_arcade_button_style(info_close_btn, Color("#E74C3C"), Color("#922B21"), Color.WHITE, 36, 22, 9)
	UIThemeBuilder.apply_arcade_button_style(close_settings_btn, Color("#E74C3C"), Color("#922B21"), Color.WHITE, 38, 24, 10)

	UIThemeBuilder.style_option_button(lang_option, 34)
	UIThemeBuilder.style_slider(music_slider)
	UIThemeBuilder.style_slider(sfx_slider)


func _populate_language_selector() -> void:
	lang_option.clear()
	var locales: Array[Dictionary] = LocalizationManager.get_supported_locales()
	for i: int in range(locales.size()):
		lang_option.add_item(String(locales[i]["label"]), i)
	lang_option.select(LocalizationManager.get_current_locale_index())


func _sync_audio_controls() -> void:
	music_slider.set_value_no_signal(GameManager.music_volume * 100.0)
	sfx_slider.set_value_no_signal(GameManager.sfx_volume * 100.0)
	_refresh_audio_toggle_buttons()


func _refresh_audio_toggle_buttons() -> void:
	var m_on: bool = GameManager.music_enabled
	music_toggle_btn.text = (
		"✓ " + LocalizationManager.t("LBL_ON")
		if m_on
		else "✖ " + LocalizationManager.t("LBL_OFF")
	)
	UIThemeBuilder.apply_arcade_button_style(
		music_toggle_btn,
		Color("#27AE60") if m_on else Color("#7F8C8D"),
		Color("#196F3D") if m_on else Color("#4D5656"),
		Color.WHITE,
		30,
		18,
		7
	)

	var s_on: bool = GameManager.sfx_enabled
	sfx_toggle_btn.text = (
		"✓ " + LocalizationManager.t("LBL_ON")
		if s_on
		else "✖ " + LocalizationManager.t("LBL_OFF")
	)
	UIThemeBuilder.apply_arcade_button_style(
		sfx_toggle_btn,
		Color("#2980B9") if s_on else Color("#7F8C8D"),
		Color("#1B4F72") if s_on else Color("#4D5656"),
		Color.WHITE,
		30,
		18,
		7
	)


func _refresh_all() -> void:
	back_title_btn.text = LocalizationManager.t("BTN_BACK_TITLE")
	points_label.text = "🏆 %s: %d" % [LocalizationManager.t("LBL_POINTS"), GameManager.total_points]
	coins_label.text = "🪙 %s: %d" % [LocalizationManager.t("LBL_COINS"), GameManager.total_coins]

	play_btn.text = LocalizationManager.t("BTN_HUB_PLAY")
	store_btn.text = LocalizationManager.t("BTN_HUB_STORE")
	profile_btn.text = LocalizationManager.t("BTN_HUB_PROFILE")
	settings_btn.text = LocalizationManager.t("BTN_HUB_SETTINGS")

	settings_title_lbl.text = LocalizationManager.t("SETTINGS_TITLE")
	lang_title_lbl.text = "🌐 " + LocalizationManager.t("LBL_LANGUAGE") + ":"
	music_label.text = LocalizationManager.t("LBL_MUSIC")
	sfx_label.text = LocalizationManager.t("LBL_SFX")
	close_settings_btn.text = LocalizationManager.t("BTN_CLOSE")
	_refresh_audio_toggle_buttons()
	_refresh_info_modal_texts()


func _refresh_info_modal_texts() -> void:
	info_close_btn.text = LocalizationManager.t("BTN_CLOSE")
	info_title_lbl.text = LocalizationManager.t("PROFILE_SOON_TITLE")
	info_desc_lbl.text = LocalizationManager.t(
		"PROFILE_SOON_DESC",
		{
			"points": GameManager.total_points,
			"coins": GameManager.total_coins,
			"rank": GameManager.player_rank,
		}
	)
	info_reward_btn.visible = true
	if GameManager.matches_completed < 10:
		info_reward_btn.text = LocalizationManager.t("BTN_UNLOCK_ALL_TEST")
	else:
		info_reward_btn.text = LocalizationManager.t("BTN_SIM_WIN_REWARD")


func _on_back_to_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(ARENA_SCENE_PATH)


func _on_store_pressed() -> void:
	get_tree().change_scene_to_file(STORE_SCENE_PATH)


func _on_profile_pressed() -> void:
	_refresh_info_modal_texts()
	info_modal_backdrop.visible = true
	info_close_btn.grab_focus()


func _on_settings_pressed() -> void:
	settings_backdrop.visible = true
	close_settings_btn.grab_focus()


func _on_info_reward_pressed() -> void:
	if GameManager.matches_completed < 10:
		GameManager.unlock_all_moles_for_testing()
	else:
		GameManager.record_match_completed(100, 150)
	_refresh_info_modal_texts()


func _on_info_close_pressed() -> void:
	info_modal_backdrop.visible = false
	play_btn.grab_focus()


func _on_close_settings_pressed() -> void:
	settings_backdrop.visible = false
	settings_btn.grab_focus()


func _on_language_selected(index: int) -> void:
	var locales: Array[Dictionary] = LocalizationManager.get_supported_locales()
	if index >= 0 and index < locales.size():
		LocalizationManager.set_locale(String(locales[index]["code"]), true)


func _on_language_changed(_new_locale: String) -> void:
	lang_option.select(LocalizationManager.get_current_locale_index())
	_refresh_all()


func _on_state_changed() -> void:
	_sync_audio_controls()
	_refresh_all()


func _on_music_toggle_pressed() -> void:
	GameManager.set_music_enabled(not GameManager.music_enabled)


func _on_music_slider_changed(val: float) -> void:
	GameManager.set_music_volume(val / 100.0)


func _on_sfx_toggle_pressed() -> void:
	GameManager.set_sfx_enabled(not GameManager.sfx_enabled)


func _on_sfx_slider_changed(val: float) -> void:
	GameManager.set_sfx_volume(val / 100.0)
