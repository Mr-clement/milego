import 'package:flutter/material.dart';

/// Palette Milego Budget — variante bleue (carte solde sombre).
/// Inspirée de la maquette `design2` : fond clair, hero sombre, accent bleu roi.
class AppColors {
  AppColors._();

  // Accent principal
  static const Color primary = Color(0xFF3D5AFE);
  static const Color primaryDark = Color(0xFF2B41C9);
  static const Color primarySoft = Color(0xFFE7ECFF);

  // Hero card (solde) — presque noir bleuté
  static const Color heroTop = Color(0xFF161A25);
  static const Color heroBottom = Color(0xFF0E111A);

  // Dégradé du donut (du foncé au clair) pour les catégories
  static const Color donutColor0 = Color(0xFF2B3A9E);
  static const Color donutColor1 = Color(0xFF3D5AFE);
  static const Color donutColor2 = Color(0xFF6D82FF);
  static const Color donutColor3 = Color(0xFF9DACFF);
  static const Color donutColor4 = Color(0xFFC9D2FF);
  static const List<Color> donut = [
    donutColor0,
    donutColor1,
    donutColor2,
    donutColor3,
    donutColor4,
  ];

  // Sémantique
  static const Color income = Color(0xFF16B364); // vert = revenus / épargne
  static const Color expense = Color(0xFFF04438); // corail = dépenses / alertes

  // ----- Thème clair -----
  static const Color lightBg = Color(0xFFEFF1F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF5F6FA);
  static const Color lightTextPrimary = Color(0xFF14171F);
  static const Color lightTextMuted = Color(0xFF8B92A1);
  static const Color lightBorder = Color(0xFFE6E8EF);

  // ----- Thème sombre -----
  static const Color darkBg = Color(0xFF0B0E16);
  static const Color darkSurface = Color(0xFF161A25);
  static const Color darkSurfaceAlt = Color(0xFF1E2331);
  static const Color darkTextPrimary = Color(0xFFF2F4FA);
  static const Color darkTextMuted = Color(0xFF9AA1B2);
  static const Color darkBorder = Color(0xFF262B3A);
}
