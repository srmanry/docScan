const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Today" / "Yesterday" / "20 Apr" — the day-group label used to bucket a
/// document list, independent of the time-of-day portion.
String formatDateGroup(DateTime dateTime) {
  final now = DateTime.now();
  final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final today = DateTime(now.year, now.month, now.day);
  final difference = today.difference(date).inDays;

  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return '${dateTime.day} ${_months[dateTime.month - 1]}';
}

String _formatTimeOfDay(DateTime dateTime) {
  final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final meridiem = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $meridiem';
}

/// "Today, 9:43 AM" / "Yesterday, 4:20 PM" / "20 Apr, 8:15 PM" — no `intl`
/// dependency in this project, so this stays hand-rolled and minimal.
String formatDocumentTimestamp(DateTime dateTime) {
  return '${formatDateGroup(dateTime)}, ${_formatTimeOfDay(dateTime)}';
}

String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 KB';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
