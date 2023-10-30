extends MenuButton

var localeDict: Dictionary

var currentLocale: String


func _init() -> void:
	var index: int = 0
	get_popup().clear()

	for locale in TranslationServer.get_loaded_locales():
		get_popup().add_item("UNSET")
		get_popup().set_item_text(index, TranslationServer.get_language_name(locale))
		get_popup().set_item_metadata(index, locale)
		get_popup().set_item_id(index, index)
		localeDict[index] = locale

		index += 1


func _ready() -> void:
	currentLocale = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "language_locale", localeDict[0]
	)
	get_popup().id_pressed.connect(on_id_pressed)
	text = TranslationServer.get_language_name(currentLocale)


func on_id_pressed(id: int):
	currentLocale = localeDict[id]
	text = TranslationServer.get_language_name(currentLocale)
	TranslationServer.set_locale(currentLocale)
	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "language_locale", currentLocale)
