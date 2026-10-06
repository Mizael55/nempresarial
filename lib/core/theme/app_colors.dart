import 'package:flutter/material.dart';

/// Centralized Design System Colors for NUBIKO
class AppColors {
  AppColors._();

  // Primary Palette: Electric Indigo & Blue
  static const Color primary50 = Color(0xFFEFF6FF);
  static const Color primary100 = Color(0xFFDBEAFE);
  static const Color primary200 = Color(0xFFBFDBFE);
  static const Color primary300 = Color(0xFF93C5FD);
  static const Color primary400 = Color(0xFF60A5FA);
  static const Color primary500 = Color(0xFF3B82F6); // Brand Primary
  static const Color primary600 = Color(0xFF2563EB); // Deep Brand
  static const Color primary700 = Color(0xFF1D4ED8);
  static const Color primary800 = Color(0xFF1E40AF);
  static const Color primary900 = Color(0xFF1E3A8A);

  // Design Tokens Aliases
  static const Color primary = primary500;
  static const Color success = emerald500;
  static const Color warning = amber500;
  static const Color error = rose500;
  static const Color darkTextSecondary = slate400;
  static const Color lightTextSecondary = slate500;

  // Growth & Success Palette: Emerald
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981); // Success Brand
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);

  // Warning & Caution Palette: Amber
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);

  // Danger & Error Palette: Rose
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color rose400 = Color(0xFFFB7185);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose700 = Color(0xFFBE123C);

  // Info Palette: Sky
  static const Color sky500 = Color(0xFF0EA5E9);

  // Dark Neutral (Slate) - For Dark Mode & High Contrast Typography
  static const Color slate950 = Color(0xFF020617);
  static const Color slate900 = Color(0xFF0F172A); // Dark Scaffold Background
  static const Color slate850 = Color(0xFF141F36);
  static const Color slate800 = Color(0xFF1E293B); // Dark Surface / Cards
  static const Color slate700 = Color(0xFF334155); // Dark Borders & Dividers
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B); // Muted Text
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0); // Light Borders
  static const Color slate100 = Color(0xFFF1F5F9); // Light Hover / Neutral
  static const Color slate50 = Color(0xFFF8FAFC);  // Light Background

  // Light Mode Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark Mode Surfaces
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1A2234);
  static const Color darkBorder = Color(0xFF263248);

  // Glassmorphism overlays
  static const Color darkOverlay = Color(0x66000000);
  static const Color lightOverlay = Color(0x33000000);
}
