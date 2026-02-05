import 'package:flutter/material.dart';

// Map of icon IDs to Icons
final Map<String, IconData> kLoanIcons = {
  'default': Icons.credit_card_rounded,
  'home': Icons.home_rounded,
  'car': Icons.directions_car_rounded,
  'edu': Icons.school_rounded,
  'tech': Icons.computer_rounded,
  'person': Icons.person_rounded,
  'business': Icons.business_center_rounded,
  'travel': Icons.flight_takeoff_rounded,
  'health': Icons.medical_services_rounded,
};

final Map<String, String> kLoanIconLabels = {
  'default': 'General',
  'home': 'Home',
  'car': 'Car',
  'edu': 'Education',
  'tech': 'Tech',
  'person': 'Personal',
  'business': 'Business',
  'travel': 'Travel',
  'health': 'Health',
};

final Map<String, Color> kIconColors = {
  'default': const Color(0xFF1B63ED),
  'home': const Color(0xFF10B981),
  'car': const Color(0xFFF59E0B),
  'edu': const Color(0xFF8B5CF6),
  'tech': const Color(0xFF6366F1),
  'person': const Color(0xFFEC4899),
  'business': const Color(0xFF3B82F6),
  'travel': const Color(0xFF0EA5E9),
  'health': const Color(0xFFEF4444),
};
