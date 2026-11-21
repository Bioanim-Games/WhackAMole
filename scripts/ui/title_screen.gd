extends Control

## Redesigned Title Screen featuring res://assets/art/title_screen.jpg with the
## custom illustrated "Topo Smash" logo, a carved-timber & molten-amber subtitle
## plaque ("CAOS CON CASCO" / GAME_TITLE_SUB) nestled right beneath the painted logo,
## a matching 3D molten-amber & dark-timber Start button ("¡JUGAR!"), and 9-language Settings Modal.

const MAIN_HUB_SCENE_PATH: String = "res://scenes/ui/main_hub.tscn"
const HERO_ART_PATH: String = "res://assets/art/title_screen.jpg"
const FALLBACK_HERO_ART_PATH: String = "res://assets/art/topo_hero.jpg"

@onready var safe_margin: MarginContainer = $SafeMargin
@onready var hero_art: TextureRect = $BackgroundHolder/HeroArt
@onready var logo_clearance_spacer: Control = $SafeMargin/CenterWrap/CenterColumn/LogoClearanceSpacer
@onready var open_settings_btn: Button = $SafeMargin/CenterWrap/CenterColumn/TopBar/OpenSettingsButton
@onready var subtitle_plaque: PanelContainer = $SafeMargin/CenterWrap/CenterColumn/SubtitleCenterRow/SubtitlePlaque
@onready var sub_logo_label: Label = $SafeMargin/CenterWrap/CenterColumn/SubtitleCenterRow/SubtitlePlaque/SubLogoLabel
@onready var start_button: Button = $SafeMargin/CenterWrap/CenterColumn/BottomActionBox/StartButtonRow/TapToStartButton

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
	if ResourceLoader.exists(HERO_ART_PATH):
		hero_art.texture = ResourceLoader.load(HERO_ART_PATH) as Texture2D
	elif ResourceLoader.exists(FALLBACK_HERO_ART_PATH):
		hero_art.texture = ResourceLoader.load(FALLBACK_HERO_ART_PATH) as Texture2D

	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_procedural_theme()
	_populate_language_selector()
	_sync_audio_controls()
	_refresh_localized_texts()
	_start_button_pulse()

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
	# HeroArt uses STRETCH_KEEP_ASPECT_COVERED with Title screen wide.jpg (4:3 wide master artwork):
	# On both Pixel 5 (9:16 portrait) and Pixel 10 Fold (unfolded ~1:1), the full vertical height
	# is always fitted and centered, cropping only the extra left/right pine trees equally!
	hero_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	var window_size: Vector2i = DisplayServer.window_get_size()
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		vp_size = Vector2(1080.0, 1920.0)
	var scale_y: float = vp_size.y / float(maxi(1, window_size.y))
	var bottom_raw: int = maxi(0, window_size.y - (safe_rect.position.y + safe_rect.size.y))
	var bottom_inset: int = roundi(float(bottom_raw) * scale_y)

	# Keep the subtitle locked right below the centered "Topo Smash" logo at any viewport height
	var height_ratio: float = vp_size.y / 1920.0
	logo_clearance_spacer.custom_minimum_size = Vector2(0.0, roundf(650.0 * height_ratio))

	safe_margin.add_theme_constant_override("margin_top", 10)
	safe_margin.add_theme_constant_override("margin_bottom", maxi(64, bottom_inset + 44))
	safe_margin.add_theme_constant_override("margin_left", 36)
	safe_margin.add_theme_constant_override("margin_right", 36)


func _apply_procedural_theme() -> void:
	# 1. Floating 3D Clear-Rock Letters for Subtitle ("CAOS CON CASCO") right below the painted "Topo Smash" logo
	subtitle_plaque.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var rock_ls := LabelSettings.new()
	var rock_font := SystemFont.new()
	rock_font.font_names = UIThemeBuilder.get_ui_font().font_names
	rock_font.font_weight = 900
	rock_ls.font = rock_font
	rock_ls.font_size = 50
	rock_ls.font_color = Color("#E6E1DA")
	rock_ls.outline_size = 16
	rock_ls.outline_color = Color("#2C2623")
	rock_ls.shadow_size = 10
	rock_ls.shadow_color = Color(0.08, 0.07, 0.06, 0.85)
	rock_ls.shadow_offset = Vector2(0, 7)
	sub_logo_label.label_settings = rock_ls

	# 2. Settings Modal Panel
	settings_modal.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(
			Color(0.13, 0.08, 0.04, 0.98),
			Color("#FF8C1A"),
			30,
			5,
			32
		)
	)

	settings_title_lbl.label_settings = UIThemeBuilder.make_label_settings(46, Color("#FFE047"), 10)
	lang_title_lbl.label_settings = UIThemeBuilder.make_label_settings(34, Color("#FFF3C4"), 7)
	music_label.label_settings = UIThemeBuilder.make_label_settings(34, Color("#58D68D"), 7)
	sfx_label.label_settings = UIThemeBuilder.make_label_settings(34, Color("#5DADE2"), 7)

	# 3. Top-right Floating 3D Letters Settings Button (higher up, no rectangle)
	UIThemeBuilder.apply_floating_letter_button_style(
		open_settings_btn,
		38,
		Color("#FFE600"),
		Color("#5E1904"),
		14
	)

	# 4. Giant 3D Golden Floating Letters Start Button ("¡JUGAR!" matched to start_button.jpg)
	UIThemeBuilder.apply_floating_letter_button_style(
		start_button,
		98,
		Color("#FFE600"),
		Color("#7A1F04"),
		24
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


func _apply_hero_start_button_style(btn: Button) -> void:
	btn.add_theme_font_override("font", UIThemeBuilder.get_ui_font())
	btn.add_theme_font_size_override("font_size", 56)
	btn.add_theme_color_override("font_color", Color("#FFFDF2"))
	btn.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	btn.add_theme_color_override("font_pressed_color", Color("#FFE8A3"))
	btn.add_theme_color_override("font_focus_color", Color("#FFFDF2"))
	btn.add_theme_color_override("font_outline_color", Color("#210D04"))
	btn.add_theme_constant_override("outline_size", 14)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#F97316")
	normal.border_color = Color("#3B1908")
	normal.border_width_left = 6
	normal.border_width_top = 6
	normal.border_width_right = 6
	normal.border_width_bottom = 16
	normal.set_corner_radius_all(38)
	normal.shadow_color = Color(0.09, 0.04, 0.01, 0.72)
	normal.shadow_size = 18
	normal.shadow_offset = Vector2(0, 8)
	normal.content_margin_left = 36
	normal.content_margin_right = 36
	normal.content_margin_top = 14
	normal.content_margin_bottom = 20

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#FB923C")
	hover.border_color = Color("#4A210B")

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color("#EA580C")
	pressed.border_width_bottom = 6
	pressed.content_margin_top = 24
	pressed.content_margin_bottom = 10

	var focus: StyleBoxFlat = hover.duplicate()
	focus.border_color = Color("#FFE066")
	focus.border_width_left = 6
	focus.border_width_top = 6
	focus.border_width_right = 6
	focus.border_width_bottom = 16

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)


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
	sub_logo_label.text = LocalizationManager.t("GAME_TITLE_SUB")
	start_button.text = LocalizationManager.t("BTN_TAP_TO_START")

	settings_title_lbl.text = LocalizationManager.t("SETTINGS_TITLE")
	lang_title_lbl.text = "🌐 " + LocalizationManager.t("LBL_LANGUAGE") + ":"
	music_label.text = LocalizationManager.t("LBL_MUSIC")
	sfx_label.text = LocalizationManager.t("LBL_SFX")
	close_settings_btn.text = LocalizationManager.t("BTN_CLOSE")
	_refresh_audio_toggle_buttons()


func _start_button_pulse() -> void:
	start_button.pivot_offset = Vector2(340.0, 78.0)
	var btn_tween: Tween = create_tween().set_loops()
	btn_tween.tween_property(start_button, "scale", Vector2(1.035, 1.035), 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	btn_tween.parallel().tween_property(start_button, "modulate", Color(1.08, 1.05, 0.96, 1.0), 0.95).set_trans(Tween.TRANS_SINE)
	btn_tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	btn_tween.parallel().tween_property(start_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.95).set_trans(Tween.TRANS_SINE)


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
