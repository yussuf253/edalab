String? rideCategoryImagePath(String name, {String? id}) {
  final value = name.toLowerCase();
  if (value.contains('same day') || value.contains('sameday')) {
    return 'assets/images/ride/SameDayDelivery.png';
  }
  if (value.contains('deliver')) {
    return 'assets/images/ride/InstDelivry.png';
  }
  if (value.contains('elect')) {
    return 'assets/images/ride/ElectRide.png';
  }
  if (value.contains('quid')) {
    return 'assets/images/ride/InstaQuid.png';
  }
  if (value.contains('mega') || value.contains('xl')) {
    return 'assets/images/ride/InstaMega.png';
  }
  if (value.contains('mini') ||
      value.contains('economy') ||
      value.contains('eco')) {
    return 'assets/images/ride/InstaMini.png';
  }
  if (value.contains('premium')) {
    return 'assets/images/ride/InstaQuid.png';
  }
  if (!['r1', 'r2', 'r3'].contains(id) && value.contains('ride')) {
    return 'assets/images/ride/InstaRide.png';
  }

  return switch (id) {
    'r1' => 'assets/images/ride/InstaMini.png',
    'r2' => 'assets/images/ride/InstaQuid.png',
    'r3' => 'assets/images/ride/InstaMega.png',
    _ => null,
  };
}
