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
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
    _tts.setErrorHandler((_) => _speaking = false);
  }

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  bool get isSpeaking => _speaking;

  Future<void> speak(String text, {String? languageOrCode}) async {
    await stop();
    if (text.trim().isEmpty) return;

    final locale = ttsLocales[languageOrCode?.toLowerCase()];
    if (locale != null) {
      await _tts.setLanguage(locale);
    }

    _speaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
  }
}
