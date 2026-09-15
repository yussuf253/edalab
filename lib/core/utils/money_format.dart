/// Formats an amount in DJF without trailing zero decimals when the value is
/// a whole number (e.g. `650` instead of `650.00`), keeping 2 decimals
/// otherwise (e.g. `650.50`).
String formatDjf(num amount) {
  final value = amount.toDouble();
  final rounded = value.roundToDouble();
  final isWhole = (value - rounded).abs() < 0.005;
  return isWhole ? rounded.toStringAsFixed(0) : value.toStringAsFixed(2);
}
