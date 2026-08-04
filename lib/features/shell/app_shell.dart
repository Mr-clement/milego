import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Coquille principale : bottom navigation + bouton flottant Assistant IA.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (_NavItem(Icons.pie_chart_rounded, 'Bilan')),
    (_NavItem(Icons.receipt_long_rounded, 'Transactions')),
    (_NavItem(Icons.flag_rounded, 'Objectifs')),
    (_NavItem(Icons.settings_rounded, 'Réglages')),
  ];

  void _go(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: const _EndFloatRaised(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat-fab',
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => context.push('/chat'),
        child: const Icon(Icons.chat_bubble_rounded, size: 22),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: _items[i],
                      selected: i == navigationShell.currentIndex,
                      onTap: () => _go(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Position du bouton flottant : comme `endFloat` (bas-droite au-dessus de la
/// barre de nav), mais remonté de 18 px pour un espacement plus propre.
class _EndFloatRaised extends FloatingActionButtonLocation {
  const _EndFloatRaised();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final base = FloatingActionButtonLocation.endFloat.getOffset(geometry);
    return Offset(base.dx, base.dy - 18);
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.accent : Colors.white.withValues(alpha: 0.65);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
