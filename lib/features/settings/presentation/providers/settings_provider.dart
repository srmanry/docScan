import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doc_sense/core/utils/tts_service.dart';
import 'package:doc_sense/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:doc_sense/features/settings/domain/entities/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsLocalDataSource _store;

  SettingsNotifier(this._store) : super(const AppSettings()) {
    _restore();
  }

  Future<void> _restore() async {
    final saved = await _store.load();
    state = saved;
    await TtsService.instance.setSpeechRate(saved.readingSpeed.rate);
  }

  Future<void> setDefaultLanguage(String? language) => _update(
    state.copyWith(
      defaultLanguage: language,
      clearDefaultLanguage: language == null,
    ),
  );

  Future<void> setReadingSpeed(ReadingSpeed speed) async {
    await TtsService.instance.setSpeechRate(speed.rate);
    await _update(state.copyWith(readingSpeed: speed));
  }

  Future<void> setTextSize(ReadingTextSize size) =>
      _update(state.copyWith(textSize: size));

  Future<void> _update(AppSettings settings) async {
    state = settings;
    await _store.save(settings);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(SettingsLocalDataSource()),
);
