import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/milego_card.dart';

/// Carte « Répartition des dépenses » : donut + légende (montants / %).
class ExpenseBreakdownCard extends StatelessWidget {
  const ExpenseBreakdownCard({
    super.key,
    required this.byCategory,
    required this.total,
    required this.categories,
    this.onTap,
  });

  /// Entrées categoryId -> montant, triées décroissant.
  final List<MapEntry<String, double>> byCategory;
  final double total;
  final List<Category> categories;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    // On garde les 4 premières catégories, le reste est agrégé en « Autres ».
    final top = byCategory.take(4).toList();
    final restSum =
        byCategory.skip(4).fold<double>(0, (s, e) => s + e.value);
    final entries = [
      ...top,
      if (restSum > 0) MapEntry('autres', restSum),
    ];

    final colors = AppColors.donut;

    return MilegoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition des dépenses',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 128,
                height: 128,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: [
                          for (var i = 0; i < entries.length; i++)
                            PieChartSectionData(
                              value: entries[i].value,
                              color: colors[i % colors.length],
                              radius: 22,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Money.compact(total),
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text('total',
                            style: TextStyle(
                                color: c.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      _LegendRow(
                        color: colors[i % colors.length],
                        label: categories.byId(entries[i].key).name,
                        percent: total == 0
                            ? 0
                            : (entries[i].value / total * 100).round(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.percent,
  });

  final Color color;
  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: c.textPrimary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
