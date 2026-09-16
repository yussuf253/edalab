/// Formats an amount in DJF with no decimal places (e.g. `650` instead of
/// `650.00`). Sub-cent remains are rounded away so whole-number DJF amounts
/// never render with a trailing `.0`/`.00`.
String formatDjf(num amount) {
  final value = amount.toDouble();
  final rounded = value.roundToDouble();
  final isWhole = (value - rounded).abs() < 0.005;
  return isWhole ? rounded.toStringAsFixed(0) : value.toStringAsFixed(0);
}

/// Formats any numeric amount as a whole-number string (no `.0`/`.00`
/// suffix). Use this for inline price interpolations outside the DJF
/// helpers, e.g. `'DJF ${money(value)}'`.
String money(num amount) => formatDjf(amount);
