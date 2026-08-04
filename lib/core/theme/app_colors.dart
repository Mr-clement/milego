import 'package:flutter/material.dart';

/// Palette Milego Budget — style « Mixx / Yas » :
/// fond blanc épuré, texte bleu marine, icônes marine + accent jaune.
class AppColors {
  AppColors._();

  // Accent principal (bleu marine)
  static const Color primary = Color(0xFF0B2E6E);
  static const Color primaryDark = Color(0xFF082352);
  static const Color primarySoft = Color(0xFFE8EEF8);

  // Accent secondaire (jaune / or — logo, scan, élément actif)
  static const Color accent = Color(0xFFFFC400);
  static const Color accentDark = Color(0xFFE0A800);

  // Bleu clair pour les liens / numéros secondaires
  static const Color link = Color(0xFF5B9BD5);

  // Hero card (solde) — dégradé marine
  static const Color heroTop = Color(0xFF103A86);
  static const Color heroBottom = Color(0xFF0A2657);

  // Dégradé du donut : marine → bleus → jaune (pop de marque)
  static const Color donutColor0 = Color(0xFF0B2E6E);
  static const Color donutColor1 = Color(0xFF2F5AA8);
  static const Color donutColor2 = Color(0xFF5B9BD5);
  static const Color donutColor3 = Color(0xFF9BC1E8);
  static const Color donutColor4 = Color(0xFFFFC400);
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

  // ----- Thème clair (fond blanc, cartes gris-bleu très clair) -----
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF2F5FA);
  static const Color lightSurfaceAlt = Color(0xFFE9EEF6);
  static const Color lightTextPrimary = Color(0xFF0B2E6E); // marine
  static const Color lightTextMuted = Color(0xFF8390A6);
  static const Color lightBorder = Color(0xFFE2E8F1);

  // ----- Thème sombre -----
  static const Color darkBg = Color(0xFF071022);
  static const Color darkSurface = Color(0xFF0F1D3A);
  static const Color darkSurfaceAlt = Color(0xFF16264A);
  static const Color darkTextPrimary = Color(0xFFEDF1F8);
  static const Color darkTextMuted = Color(0xFF93A0BA);
  static const Color darkBorder = Color(0xFF22324F);
}
