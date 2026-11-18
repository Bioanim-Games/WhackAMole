extends Node

## Manages 9-language internationalization (i18n) and automatic device locale
## detection on first install (.apk / PC / Console).
## Main default fallback locale: "es_419" (Español - Latinoamérica).

signal language_changed(new_locale: String)

const SETTINGS_PATH: String = "user://settings.cfg"
const DEFAULT_LOCALE: String = "es_419"

var current_locale: String = DEFAULT_LOCALE
var detected_device_locale: String = ""

func _ready() -> void:
	_register_all_translations()
	detected_device_locale = OS.get_locale()
	var saved_locale: String = _load_saved_locale()
	if saved_locale != "" and TranslationsData.CATALOG.has(saved_locale):
		set_locale(saved_locale, false)
	else:
		var auto_locale: String = map_os_locale_to_supported(detected_device_locale)
		set_locale(auto_locale, true)


func _register_all_translations() -> void:
	for locale_code: String in TranslationsData.CATALOG.keys():
		var translation := Translation.new()
		translation.locale = locale_code
		var dict: Dictionary = TranslationsData.CATALOG[locale_code]
		for msg_key: String in dict.keys():
			translation.add_message(msg_key, String(dict[msg_key]))
		TranslationServer.add_translation(translation)


## Maps any raw OS locale string (e.g. from Android/iOS OS.get_locale())
## to one of the 9 supported locales, defaulting to "es_419".
static func map_os_locale_to_supported(raw_locale: String) -> String:
	var clean: String = raw_locale.strip_edges().replace("-", "_")
	if clean == "":
		return DEFAULT_LOCALE

	var lower: String = clean.to_lower()

	# Exact Spain match -> es_ES; all other Spanish variants -> es_419 (Latinoamérica)
	if lower == "es_es" or lower.begins_with("es_es_"):
		return "es_ES"
	if lower == "es" or lower.begins_with("es_"):
		return "es_419"

	if lower == "pt" or lower.begins_with("pt_"):
		return "pt"
	if lower == "fr" or lower.begins_with("fr_"):
		return "fr"
	if lower == "de" or lower.begins_with("de_"):
		return "de"
	if lower == "en" or lower.begins_with("en_"):
		return "en"
	if lower == "ko" or lower.begins_with("ko_"):
		return "ko"
	if lower == "ja" or lower.begins_with("ja_"):
		return "ja"
	if lower == "zh" or lower.begins_with("zh_"):
		return "zh_CN"

	return DEFAULT_LOCALE


func set_locale(locale_code: String, save_to_disk: bool = true) -> void:
	var target: String = locale_code
	if not TranslationsData.CATALOG.has(target):
		target = DEFAULT_LOCALE

	current_locale = target
	TranslationServer.set_locale(current_locale)
	if save_to_disk:
		_save_locale(current_locale)
	language_changed.emit(current_locale)


func get_supported_locales() -> Array[Dictionary]:
	return TranslationsData.SUPPORTED_LOCALES


func get_current_locale_index() -> int:
	for i: int in range(TranslationsData.SUPPORTED_LOCALES.size()):
		if TranslationsData.SUPPORTED_LOCALES[i]["code"] == current_locale:
			return i
	return 0


## Translates a key into the active language and formats optional {placeholders}.
func t(key: String, params: Dictionary = {}) -> String:
	var lang_dict: Dictionary = TranslationsData.CATALOG.get(
		current_locale,
		TranslationsData.CATALOG[DEFAULT_LOCALE]
	)
	var text: String = ""
	if lang_dict.has(key):
		text = String(lang_dict[key])
	elif TranslationsData.CATALOG[DEFAULT_LOCALE].has(key):
		text = String(TranslationsData.CATALOG[DEFAULT_LOCALE][key])
	else:
		text = key

	if not params.is_empty():
		text = text.format(params)
	return text


func _load_saved_locale() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return ""
	return String(cfg.get_value("i18n", "locale", ""))


func _save_locale(locale_code: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("i18n", "locale", locale_code)
	cfg.set_value("i18n", "device_os_locale_at_install", detected_device_locale)
	cfg.save(SETTINGS_PATH)
