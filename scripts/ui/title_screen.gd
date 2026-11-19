extends Control

## Title Screen featuring topo_hero.jpg, enlarged 92px/46px typography,
## giant 160px tall Start button, and a big-text Settings Modal (Language, Music, SFX).

const MAIN_HUB_SCENE_PATH: String = "res://scenes/ui/main_hub.tscn"

@onready var safe_margin: MarginContainer = $SafeMargin
@onready var hero_art: TextureRect = $BackgroundHolder/HeroArt
@onready var open_settings_btn: Button = $SafeMargin/CenterWrap/CenterColumn/TopBar/OpenSettingsButton
@onready var top_title_badge: PanelContainer = $SafeMargin/CenterWrap/CenterColumn/TopTitleBadge
@onready var main_logo_label: Label = $SafeMargin/CenterWrap/CenterColumn/TopTitleBadge/TitleVBox/MainLogoLabel
@onready var sub_logo_label: Label = $SafeMargin/CenterWrap/CenterColumn/TopTitleBadge/TitleVBox/SubLogoLabel
@onready var tagline_label: Label = $SafeMargin/CenterWrap/CenterColumn/TopTitleBadge/TitleVBox/TaglineLabel
@onready var start_button: Button = $SafeMargin/CenterWrap/CenterColumn/BottomActionBox/TapToStartButton
@onready var hint_label: Label = $SafeMargin/CenterWrap/CenterColumn/BottomActionBox/PlatformHintLabel

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
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_procedural_theme()
	_populate_language_selector()
	_sync_audio_controls()
	_refresh_localized_texts()
	_start_ambient_animations()

	LocalizationManager.language_changed.connect(_on_language_changed)
	GameManager.state_changed.connect(_on_state_changed)

	start_button.pressed.connect(_on_start_pressed)
	open_settings_btn.pressed.connect(_on_open_settings_pressed)
	close_settings_btn.pressed.connect(_on_close_settings_pressed)
	lang_option.item_selected.connect(_on_language_selected)
	music_toggle_btn.pressed.connect(_on_music_toggle_pressed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_toggle_btn.pressed.connect(_on_sfx_toggle_pressed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	start_button.grab_focus()


func _apply_safe_area() -> void:
	UIThemeBuilder.apply_device_safe_area(safe_margin, 36, 36, 36, 52)


func _apply_procedural_theme() -> void:
	top_title_badge.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(
			Color(0.11, 0.07, 0.04, 0.90),
			Color("#FFB800"),
			30,
			5,
			28
		)
	)
	settings_modal.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(
			Color(0.12, 0.08, 0.05, 0.98),
			Color("#FFB800"),
			30,
			5,
			32
		)
	)

	main_logo_label.label_settings = UIThemeBuilder.make_label_settings(
		92,
		Color("#FFE047"),
		16,
		Color("#1C0E04"),
		Vector2(0, 8)
	)
	sub_logo_label.label_settings = UIThemeBuilder.make_label_settings(
		46,
		Color("#FF7A2F"),
		10,
		Color("#1C0E04"),
		Vector2(0, 5)
	)
	tagline_label.label_settings = UIThemeBuilder.make_label_settings(
		30,
		Color("#FFF5D6"),
		7,
		Color("#160C05"),
		Vector2(0, 3)
	)
	hint_label.label_settings = UIThemeBuilder.make_label_settings(
		28,
		Color("#FFF3C4"),
		7
	)

	settings_title_lbl.label_settings = UIThemeBuilder.make_label_settings(46, Color("#FFE047"), 10)
	lang_title_lbl.label_settings = UIThemeBuilder.make_label_settings(34, Color("#FFF3C4"), 7)
	music_label.label_settings = UIThemeBuilder.make_label_settings(34, Color("#58D68D"), 7)
	sfx_label.label_settings = UIThemeBuilder.make_label_settings(34, Color("#5DADE2"), 7)

	UIThemeBuilder.apply_arcade_button_style(
		open_settings_btn,
		Color("#34495E"),
		Color("#1F2E3D"),
		Color("#FFFDF5"),
		32,
		22,
		8
	)
	UIThemeBuilder.apply_arcade_button_style(
		start_button,
		Color("#FFB800"),
		Color("#B86B00"),
		Color("#FFFDF5"),
		50,
		30,
		12
	)
	UIThemeBuilder.apply_arcade_button_style(
		close_settings_btn,
		Color("#E74C3C"),
		Color("#922B21"),
		Color.WHITE,
		38,
		24,
		10
	)

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


func _refresh_localized_texts() -> void:
	open_settings_btn.text = LocalizationManager.t("BTN_HUB_SETTINGS") + " / 🌐"
	main_logo_label.text = LocalizationManager.t("GAME_TITLE_MAIN")
	sub_logo_label.text = LocalizationManager.t("GAME_TITLE_SUB")
	tagline_label.text = LocalizationManager.t("TITLE_TAGLINE")
	start_button.text = LocalizationManager.t("BTN_TAP_TO_START")
	hint_label.text = LocalizationManager.t("HINT_CONTROLS")

	settings_title_lbl.text = LocalizationManager.t("SETTINGS_TITLE")
	lang_title_lbl.text = "🌐 " + LocalizationManager.t("LBL_LANGUAGE") + ":"
	music_label.text = LocalizationManager.t("LBL_MUSIC")
	sfx_label.text = LocalizationManager.t("LBL_SFX")
	close_settings_btn.text = LocalizationManager.t("BTN_CLOSE")
	_refresh_audio_toggle_buttons()


func _start_ambient_animations() -> void:
	hero_art.pivot_offset = hero_art.size * 0.5
	var bg_tween: Tween = create_tween().set_loops()
	bg_tween.tween_property(hero_art, "scale", Vector2(1.04, 1.04), 4.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bg_tween.tween_property(hero_art, "scale", Vector2(1.0, 1.0), 4.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var btn_tween: Tween = create_tween().set_loops()
	btn_tween.tween_property(start_button, "modulate", Color(1.08, 1.06, 0.96, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
	btn_tween.tween_property(start_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE)


func _on_open_settings_pressed() -> void:
	settings_backdrop.visible = true
	close_settings_btn.grab_focus()


func _on_close_settings_pressed() -> void:
	settings_backdrop.visible = false
	start_button.grab_focus()


func _on_language_selected(index: int) -> void:
	var locales: Array[Dictionary] = LocalizationManager.get_supported_locales()
	if index >= 0 and index < locales.size():
		LocalizationManager.set_locale(String(locales[index]["code"]), true)


func _on_language_changed(_new_locale: String) -> void:
	lang_option.select(LocalizationManager.get_current_locale_index())
	_refresh_localized_texts()


func _on_state_changed() -> void:
	_sync_audio_controls()


func _on_music_toggle_pressed() -> void:
	GameManager.set_music_enabled(not GameManager.music_enabled)


func _on_music_slider_changed(val: float) -> void:
	GameManager.set_music_volume(val / 100.0)


func _on_sfx_toggle_pressed() -> void:
	GameManager.set_sfx_enabled(not GameManager.sfx_enabled)


func _on_sfx_slider_changed(val: float) -> void:
	GameManager.set_sfx_volume(val / 100.0)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_HUB_SCENE_PATH)
