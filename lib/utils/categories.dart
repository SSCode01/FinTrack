import 'package:flutter/material.dart';

class TransactionCategory {
  final String name;
  final IconData icon;
  final Color color;

  const TransactionCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<TransactionCategory> kCategories = [
  TransactionCategory(
    name: 'Food & Drinks',
    icon: Icons.restaurant,
    color: Color(0xFFFF6B6B),
  ),
  TransactionCategory(
    name: 'Transport',
    icon: Icons.directions_car,
    color: Color(0xFF4ECDC4),
  ),
  TransactionCategory(
    name: 'Entertainment',
    icon: Icons.movie,
    color: Color(0xFFFFE66D),
  ),
  TransactionCategory(
    name: 'Shopping',
    icon: Icons.shopping_bag,
    color: Color(0xFFA855F7),
  ),
  TransactionCategory(
    name: 'Rent & Bills',
    icon: Icons.home,
    color: Color(0xFF3B82F6),
  ),
  TransactionCategory(
    name: 'Travel',
    icon: Icons.flight,
    color: Color(0xFF06B6D4),
  ),
  TransactionCategory(
    name: 'Medical',
    icon: Icons.medical_services,
    color: Color(0xFFEF4444),
  ),
  TransactionCategory(
    name: 'Education',
    icon: Icons.school,
    color: Color(0xFFF97316),
  ),
  TransactionCategory(
    name: 'Other',
    icon: Icons.bookmark,
    color: Color(0xFF94A3B8),
  ),
];

TransactionCategory getCategoryByName(String name) {
  return kCategories.firstWhere(
    (c) => c.name == name,
    orElse: () => kCategories.last,
  );
}
