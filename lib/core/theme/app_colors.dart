import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color royalBlue = Color(0xFF1E3A8A); // Royal Blue
  static const Color royalBlueLight = Color(0xFF3B82F6);
  
  static const Color emeraldGreen = Color(0xFF10B981); // Emerald Green
  static const Color purpleAccent = Color(0xFF8B5CF6); // Purple Accent
  static const Color softOrange = Color(0xFFF59E0B); // Soft Orange

  // Background & Surface
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
