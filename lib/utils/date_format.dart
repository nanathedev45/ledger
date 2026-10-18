// lib/utils/date_format.dart
//
// Tiny date formatter — avoids the `intl` package (flaky network + Dart 2.19
// pinning pain). Format: `yyyy-MM-dd HH:mm` (24-hour).
// Add more formats here when reports need them; keep it pure & testable.

String _two(int n) => n.toString().padLeft(2, '0');

String formatDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final mo = _two(dt.month);
  final d = _two(dt.day);
  final h = _two(dt.hour);
  final mi = _two(dt.minute);
  return '$y-$mo-$d $h:$mi';
}