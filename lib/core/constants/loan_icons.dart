import 'package:flutter/material.dart';

/// Icon data for loan categories
const Map<String, IconData> kLoanIcons = {
  'default': Icons.credit_card_rounded,
  'home': Icons.home_rounded,
  'car': Icons.directions_car_rounded,
  'edu': Icons.school_rounded,
  'tech': Icons.devices_rounded,
  'person': Icons.person_rounded,
  'business': Icons.business_center_rounded,
  'travel': Icons.flight_takeoff_rounded,
  'health': Icons.health_and_safety_rounded,
  'wedding': Icons.diamond_rounded,
  'furniture': Icons.chair_rounded,
  'phone': Icons.smartphone_rounded,
  'renovation': Icons.construction_rounded,
  'other': Icons.more_horiz_rounded,
};

/// Labels for each category
String kLoanIconLabel(String id) {
  return switch (id) {
    'default' => 'General',
    'home' => 'Home',
    'car' => 'Auto',
    'edu' => 'Education',
    'tech' => 'Technology',
    'person' => 'Personal',
    'business' => 'Business',
    'travel' => 'Travel',
    'health' => 'Health',
    'wedding' => 'Wedding',
    'furniture' => 'Furniture',
    'phone' => 'Phone',
    'renovation' => 'Renovation',
    'other' => 'Other',
    _ => 'General',
  };
}

/// Gradient colors for each icon category
class IconGradient {
  final Color start;
  final Color end;
  const IconGradient(this.start, this.end);

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [start, end],
      );
}

IconGradient kLoanIconGradient(String id) {
  return switch (id) {
    'default' => const IconGradient(Color(0xFF3B82F6), Color(0xFF2563EB)),
    'home' => const IconGradient(Color(0xFFF97316), Color(0xFFEA580C)),
    'car' => const IconGradient(Color(0xFF6366F1), Color(0xFF4F46E5)),
    'edu' => const IconGradient(Color(0xFF8B5CF6), Color(0xFF7C3AED)),
    'tech' => const IconGradient(Color(0xFF06B6D4), Color(0xFF0891B2)),
    'person' => const IconGradient(Color(0xFFEC4899), Color(0xFFDB2777)),
    'business' => const IconGradient(Color(0xFF10B981), Color(0xFF059669)),
    'travel' => const IconGradient(Color(0xFF14B8A6), Color(0xFF0D9488)),
    'health' => const IconGradient(Color(0xFFEF4444), Color(0xFFDC2626)),
    'wedding' => const IconGradient(Color(0xFFF43F5E), Color(0xFFE11D48)),
    'furniture' => const IconGradient(Color(0xFFA78BFA), Color(0xFF8B5CF6)),
    'phone' => const IconGradient(Color(0xFF22D3EE), Color(0xFF06B6D4)),
    'renovation' => const IconGradient(Color(0xFFFBBF24), Color(0xFFF59E0B)),
    'other' => const IconGradient(Color(0xFF64748B), Color(0xFF475569)),
    _ => const IconGradient(Color(0xFF3B82F6), Color(0xFF2563EB)),
  };
}

/// Builds a gradient icon container widget
Widget buildGradientIcon(String iconId, {double size = 44}) {
  final gradient = kLoanIconGradient(iconId);
  final icon = kLoanIcons[iconId] ?? Icons.credit_card_rounded;

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: gradient.gradient,
      borderRadius: BorderRadius.circular(size * 0.28),
      boxShadow: [
        BoxShadow(
          color: gradient.start.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: size * 0.5),
  );
}
