import 'package:doc_sense/core/config/local_secrets.dart';

/// API keys are injected at build time via --dart-define (see run.sh), and
/// fall back to [LocalSecrets] when the app is launched without them (e.g.
/// an IDE's plain Run button), never hardcoded here or committed.
class ApiConfig {
  ApiConfig._();

  static const String _cloudVisionFromDefine = String.fromEnvironment('CLOUD_VISION_API_KEY');
  static const String _geminiFromDefine = String.fromEnvironment('GEMINI_API_KEY');

  static final String cloudVisionApiKey =
      _cloudVisionFromDefine.isNotEmpty ? _cloudVisionFromDefine : LocalSecrets.cloudVisionApiKey;
  static final String geminiApiKey =
      _geminiFromDefine.isNotEmpty ? _geminiFromDefine : LocalSecrets.geminiApiKey;

  static bool get hasCloudVisionKey => cloudVisionApiKey.isNotEmpty;
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
