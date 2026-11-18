extends Control

## Title Screen featuring topo_hero.jpg (topo1concepto3(el_mejor).jpg),
## pure-Godot styled logo badge, ambient particles, and 9-language live selector.

const MAIN_HUB_SCENE_PATH: String = "res://scenes/ui/main_hub.tscn"

@onready var hero_art: TextureRect = $BackgroundHolder/HeroArt
@onready var top_title_badge: PanelContainer = $SafeMargin/CenterWrap/CenterColumn/TopTitleBadge
@onready var main_logo_label: Label = $SafeMargin/CenterWrap/CenterColumn/TopTitleBadge/TitleVBox/MainLogoLabel
@onready var sub_logo_label: Label = $SafeMargin/CenterWrap/CenterColumn/TopTitleBadge/TitleVBox/SubLogoLabel
@onready var tagline_label: Label = $SafeMargin/CenterWrap/CenterColumn/TopTitleBadge/TitleVBox/TaglineLabel
@onready var lang_label: Label = $SafeMargin/CenterWrap/CenterColumn/TopBar/LangBox/LangLabel
@onready var lang_option: OptionButton = $SafeMargin/CenterWrap/CenterColumn/TopBar/LangBox/LanguageOptionButton
@onready var start_button: Button = $SafeMargin/CenterWrap/CenterColumn/BottomActionBox/TapToStartButton
@onready var hint_label: Label = $SafeMargin/CenterWrap/CenterColumn/BottomActionBox/PlatformHintLabel


func _ready() -> void:
	_apply_procedural_theme()
	_populate_language_selector()
	_refresh_localized_texts()
	_start_ambient_animations()

	LocalizationManager.language_changed.connect(_on_language_changed)
	start_button.pressed.connect(_on_start_pressed)
	lang_option.item_selected.connect(_on_language_selected)
	start_button.grab_focus()


func _apply_procedural_theme() -> void:
	top_title_badge.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(
			Color(0.11, 0.07, 0.04, 0.88),
			Color("#FFB800"),
			26,
			4,
			22
		)
	)

	main_logo_label.label_settings = UIThemeBuilder.make_label_settings(
		58,
		Color("#FFE047"),
		12,
		Color("#1C0E04"),
		Vector2(0, 6)
	)
	sub_logo_label.label_settings = UIThemeBuilder.make_label_settings(
		28,
		Color("#FF7A2F"),
		8,
		Color("#1C0E04"),
		Vector2(0, 4)
	)
	tagline_label.label_settings = UIThemeBuilder.make_label_settings(
		18,
		Color("#FFF5D6"),
		5,
		Color("#160C05"),
		Vector2(0, 2)
	)
	lang_label.label_settings = UIThemeBuilder.make_label_settings(
		16,
		Color("#FFE8A3"),
		4
	)
	hint_label.label_settings = UIThemeBuilder.make_label_settings(
		16,
		Color("#F5E6C8"),
		5
	)

	UIThemeBuilder.apply_arcade_button_style(
		start_button,
		Color("#FFB800"),
		Color("#B86B00"),
		Color("#FFFDF5"),
		30,
		24
	)

	lang_option.add_theme_font_override("font", UIThemeBuilder.get_ui_font())
	lang_option.add_theme_font_size_override("font_size", 16)
	var lang_sb := UIThemeBuilder.make_panel_style(
		Color(0.14, 0.09, 0.06, 0.92),
		Color("#D49B35"),
		14,
		2,
		10
	)
	lang_option.add_theme_stylebox_override("normal", lang_sb)
	lang_option.add_theme_stylebox_override("hover", lang_sb)
	lang_option.add_theme_stylebox_override("pressed", lang_sb)


func _populate_language_selector() -> void:
	lang_option.clear()
	var locales: Array[Dictionary] = LocalizationManager.get_supported_locales()
	for i: int in range(locales.size()):
		lang_option.add_item(String(locales[i]["label"]), i)
	lang_option.select(LocalizationManager.get_current_locale_index())


func _refresh_localized_texts() -> void:
	main_logo_label.text = LocalizationManager.t("GAME_TITLE_MAIN")
	sub_logo_label.text = LocalizationManager.t("GAME_TITLE_SUB")
	tagline_label.text = LocalizationManager.t("TITLE_TAGLINE")
	lang_label.text = "🌐 " + LocalizationManager.t("LBL_LANGUAGE") + ":"
	start_button.text = LocalizationManager.t("BTN_TAP_TO_START")
	hint_label.text = LocalizationManager.t("HINT_CONTROLS")


func _start_ambient_animations() -> void:
	# Gentle breathing zoom on the hero concept art
	hero_art.pivot_offset = hero_art.size * 0.5
	var bg_tween: Tween = create_tween().set_loops()
	bg_tween.tween_property(hero_art, "scale", Vector2(1.04, 1.04), 4.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bg_tween.tween_property(hero_art, "scale", Vector2(1.0, 1.0), 4.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Pulsing call-to-action start button
	var btn_tween: Tween = create_tween().set_loops()
	btn_tween.tween_property(start_button, "modulate", Color(1.08, 1.06, 0.96, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
	btn_tween.tween_property(start_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE)


func _on_language_selected(index: int) -> void:
	var locales: Array[Dictionary] = LocalizationManager.get_supported_locales()
	if index >= 0 and index < locales.size():
		LocalizationManager.set_locale(String(locales[index]["code"]), true)


func _on_language_changed(_new_locale: String) -> void:
	lang_option.select(LocalizationManager.get_current_locale_index())
	_refresh_localized_texts()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_HUB_SCENE_PATH)
