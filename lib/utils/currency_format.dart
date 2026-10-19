// lib/utils/currency_format.dart
//
// Formats a non-negative amount as `1,234,567.89`. Hand-rolled to avoid
// `intl` (flaky network + Dart 2.19 version pinning). Negative numbers are
// not used here — the sign (+/−) is rendered separately by the tile.

String formatAmount(double amount) {
  final fixed = amount.toStringAsFixed(2);      // "12345.67"
  final dotIndex = fixed.indexOf('.');
  final intPart = fixed.substring(0, dotIndex); // "12345"
  final fracPart = fixed.substring(dotIndex);   // ".67"

  // Insert commas from the right every 3 digits.
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final remaining = intPart.length - i;
    if (i > 0 && remaining % 3 == 0) {
      buf.write(',');
    }
    buf.write(intPart[i]);
  }

  return '$buf$fracPart';                        // "12,345.67"
}