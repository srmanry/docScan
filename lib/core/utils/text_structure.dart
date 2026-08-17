/// Lightweight, dependency-free structuring of raw OCR/extracted text for
/// display. Only acts on lines that match an unambiguous signal (a bullet
/// marker, a "Label: value" pattern, or a known section-header phrase) —
/// anything else is left as plain text, so a misclassification never hides
/// or corrupts content, it just renders unstyled.
sealed class TextBlock {
  const TextBlock();
}

class HeadingBlock extends TextBlock {
  final String text;
  const HeadingBlock(this.text);
}

class BulletBlock extends TextBlock {
  final String text;
  const BulletBlock(this.text);
}

class KeyValueBlock extends TextBlock {
  final String label;
  final String value;
  const KeyValueBlock(this.label, this.value);
}

class LineBlock extends TextBlock {
  final String text;
  const LineBlock(this.text);
}

// Common section titles across resumes, forms and reports — the only lines
// ever promoted to a heading, so plain short lines (a name, a city) never
// get misread as one.
const _headingKeywords = {
  'career objective', 'objective', 'summary', 'professional summary', 'profile', 'about me',
  'personal info', 'personal information', 'contact', 'contact info', 'contact information',
  'present address', 'permanent address', 'address',
  'language', 'languages',
  'education', 'qualifications', 'academic background',
  'experience', 'work experience', 'employment history', 'professional experience',
  'skills', 'technical skills', 'core competencies',
  'certifications', 'certificates', 'licenses',
  'projects', 'references', 'achievements', 'awards', 'hobbies', 'interests', 'declaration',
};

final _bulletPattern = RegExp(r'^[•\-\*]\s*(.+)$');
final _keyValuePattern = RegExp(r'^([A-Za-z][A-Za-z0-9 /&.]{1,40}):\s+(.+)$');

List<TextBlock> parseDocumentText(String source) {
  final blocks = <TextBlock>[];

  for (final raw in source.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    final bulletMatch = _bulletPattern.firstMatch(line);
    if (bulletMatch != null) {
      blocks.add(BulletBlock(bulletMatch.group(1)!.trim()));
      continue;
    }

    final headingKey = line.toLowerCase().replaceAll(RegExp(r':$'), '').trim();
    if (_headingKeywords.contains(headingKey)) {
      blocks.add(HeadingBlock(line.replaceAll(RegExp(r':$'), '')));
      continue;
    }

    final kvMatch = _keyValuePattern.firstMatch(line);
    if (kvMatch != null) {
      blocks.add(KeyValueBlock(kvMatch.group(1)!.trim(), kvMatch.group(2)!.trim()));
      continue;
    }

    blocks.add(LineBlock(line));
  }

  return blocks;
}
