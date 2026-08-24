/// Read-aloud pace. The rates are what flutter_tts expects (0–1 on Android,
/// where ~0.5 sounds like normal speech).
enum ReadingSpeed {
  slow('Slow', 0.35),
  normal('Normal', 0.5),
  fast('Fast', 0.7);

  const ReadingSpeed(this.label, this.rate);
  final String label;
  final double rate;
}

/// Scales document and AI text without touching the rest of the UI.
enum ReadingTextSize {
  small('Small', 0.9),
  medium('Medium', 1.0),
  large('Large', 1.2);

  const ReadingTextSize(this.label, this.scale);
  final String label;
  final double scale;
}

class AppSettings {
  /// Language used for Translate/Summarize without asking. Null means the
  /// language picker opens every time.
  final String? defaultLanguage;

  final ReadingSpeed readingSpeed;
  final ReadingTextSize textSize;

  const AppSettings({
    this.defaultLanguage,
    this.readingSpeed = ReadingSpeed.normal,
    this.textSize = ReadingTextSize.medium,
  });

  AppSettings copyWith({
    String? defaultLanguage,
    bool clearDefaultLanguage = false,
    ReadingSpeed? readingSpeed,
    ReadingTextSize? textSize,
  }) {
    return AppSettings(
      defaultLanguage: clearDefaultLanguage
          ? null
          : (defaultLanguage ?? this.defaultLanguage),
      readingSpeed: readingSpeed ?? this.readingSpeed,
      textSize: textSize ?? this.textSize,
    );
  }
}
