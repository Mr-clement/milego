import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Palette fixe icône+couleur assignée par rotation aux nouveaux objectifs
/// (pas de sélecteur en v1). [GoalEntity] ne stocke que l'index dans cette
/// liste — jamais l'icône elle-même (voir [IconRegistry] pour le pourquoi).
class GoalPalette {
  GoalPalette._();

  static const entries = <(IconData, Color)>[
    (Icons.savings_rounded, AppColors.primary),
    (Icons.flag_rounded, Color(0xFF6D82FF)),
    (Icons.emoji_events_rounded, Color(0xFF16B364)),
    (Icons.star_rounded, AppColors.donutColor2),
  ];
}
