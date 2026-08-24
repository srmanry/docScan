import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Maps the language names used in the UI's language pickers to TTS locale
/// codes, and BCP-47-ish OCR-detected codes (e.g. from Cloud Vision) too.
const Map<String, String> ttsLocales = {
  'english': 'en-US',
  'bangla': 'bn-BD',
  'hindi': 'hi-IN',
  'arabic': 'ar-SA',
  'spanish': 'es-ES',
  'french': 'fr-FR',
  'en': 'en-US',
  'bn': 'bn-BD',
  'hi': 'hi-IN',
  'ar': 'ar-SA',
  'es': 'es-ES',
  'fr': 'fr-FR',
};

/// Thin wrapper around [FlutterTts] shared across the app so only one
/// utterance plays at a time.
class TtsService {
  TtsService._() {
    _tts.setCompletionHandler(() => _setSpeaking(false));
    _tts.setCancelHandler(() => _setSpeaking(false));
    _tts.setErrorHandler((_) => _setSpeaking(false));
  }

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  double _rate = 0.5;

  /// Whether speech is playing. A listenable so the speaker button also
  /// settles down when an utterance finishes on its own.
  final ValueNotifier<bool> speakingListenable = ValueNotifier(false);

  bool get isSpeaking => speakingListenable.value;

  void _setSpeaking(bool value) => speakingListenable.value = value;

  /// Read-aloud pace, kept here so every future utterance uses it.
  Future<void> setSpeechRate(double rate) async {
    _rate = rate;
    await _tts.setSpeechRate(rate);
  }

  Future<void> speak(String text, {String? languageOrCode}) async {
    await stop();
    if (text.trim().isEmpty) return;

    final locale = ttsLocales[languageOrCode?.toLowerCase()];
    if (locale != null) {
      await _tts.setLanguage(locale);
    }

    await _tts.setSpeechRate(_rate);
    _setSpeaking(true);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _setSpeaking(false);
  }
}
