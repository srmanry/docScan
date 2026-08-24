import 'package:shared_preferences/shared_preferences.dart';

import 'package:doc_sense/features/settings/domain/entities/app_settings.dart';

/// Settings live in SharedPreferences — a handful of small values that must
/// survive a restart, with no need for the documents database.
class SettingsLocalDataSource {
  static const _languageKey = 'settings_default_language';
  static const _speedKey = 'settings_reading_speed';
  static const _textSizeKey = 'settings_text_size';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString(_languageKey);

    return AppSettings(
      defaultLanguage: (language == null || language.isEmpty) ? null : language,
      readingSpeed: _byName(
        ReadingSpeed.values,
        prefs.getString(_speedKey),
        ReadingSpeed.normal,
      ),
      textSize: _byName(
        ReadingTextSize.values,
        prefs.getString(_textSizeKey),
        ReadingTextSize.medium,
      ),
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_speedKey, settings.readingSpeed.name);
    await prefs.setString(_textSizeKey, settings.textSize.name);

    final language = settings.defaultLanguage;
    if (language == null) {
      await prefs.remove(_languageKey);
    } else {
      await prefs.setString(_languageKey, language);
    }
  }

  T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
