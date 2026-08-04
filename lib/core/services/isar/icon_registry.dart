import 'package:flutter/material.dart';

/// Table fixe clé → icône pour les catégories persistées en Isar.
///
/// Flutter élague les glyphes de police non référencés littéralement au
/// build release (tree-shaking des icônes) : reconstruire un [IconData]
/// depuis un code point stocké en base casserait l'affichage. On ne stocke
/// donc jamais une icône brute, seulement une clé de cette table.
class IconRegistry {
  IconRegistry._();

  static const Map<String, IconData> icons = {
    'home': Icons.home_rounded,
    'restaurant': Icons.restaurant_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'directions_bus': Icons.directions_bus_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'favorite': Icons.favorite_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'payments': Icons.payments_rounded,
    'category': Icons.category_rounded,
  };

  static IconData resolve(String key) => icons[key] ?? Icons.category_rounded;
}
