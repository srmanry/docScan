class AppConstants {
  AppConstants._();

  static const String appName = 'DocAI';

  // Local storage keys
  static const String hiveDocumentsBox = 'documents_box';
  static const String hiveHistoryBox = 'history_box';
  static const String prefsThemeMode = 'theme_mode';
  static const String prefsAuthToken = 'auth_token';

  // Limits (free tier)
  static const int freeOcrDailyLimit = 5;
  static const int freeAiDailyLimit = 3;
  static const int freeMaxPdfPages = 20;
}
