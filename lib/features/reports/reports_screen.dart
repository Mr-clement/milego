import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/type_pill.dart';
import '../bilan/widgets/expense_breakdown_card.dart';
import 'period_utils.dart';

enum BalanceView { monthly, total }

/// Écran « Rapports » : solde Total/Mensuel + répartition Dépenses/Revenus
/// par période (jour/semaine/mois/année). Accessible depuis le Bilan.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  BalanceView _view = BalanceView.monthly;
  PeriodType _periodType = PeriodType.day;
  DateTime _anchor = DateTime.now();
  TxType _txType = TxType.expense;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    final monthSummary = ref.watch(monthSummaryProvider);
    final globalBalance = ref.watch(globalBalanceProvider);
    final categories = ref.watch(categoriesProvider);
    final txs = ref.watch(transactionsProvider);

    final range = periodRangeFor(_periodType, _anchor);
    final summary = summarizeForPeriod(txs, range, _txType);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Rapports', style: TextStyle(color: c.textPrimary)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            PopupMenuButton<BalanceView>(
              onSelected: (v) => setState(() => _view = v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: BalanceView.monthly, child: Text('Ce mois')),
                PopupMenuItem(value: BalanceView.total, child: Text('Total')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _view == BalanceView.monthly ? 'Ce mois' : 'Total',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded,
                        color: AppColors.primaryDark, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                Money.full(
                  _view == BalanceView.monthly
                      ? monthSummary.remaining
                      : globalBalance,
                ),
                key: ValueKey(_view),
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TypePill(
                  label: 'Dépenses',
                  selected: _txType == TxType.expense,
                  onTap: () => setState(() => _txType = TxType.expense),
                ),
                const SizedBox(width: 10),
                TypePill(
                  label: 'Revenus',
                  selected: _txType == TxType.income,
                  onTap: () => setState(() => _txType = TxType.income),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final type in PeriodType.values) ...[
                  _PeriodTab(
                    label: _periodLabel(type),
                    selected: _periodType == type,
                    onTap: () => setState(() => _periodType = type),
                  ),
                  const SizedBox(width: 16),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(
                      () => _anchor = shiftAnchor(_periodType, _anchor, -1)),
                  icon: Icon(Icons.chevron_left_rounded, color: c.textMuted),
                ),
                Text(range.label,
                    style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: () => setState(
                      () => _anchor = shiftAnchor(_periodType, _anchor, 1)),
                  icon: Icon(Icons.chevron_right_rounded, color: c.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey('${_periodType}_${range.start}_$_txType'),
                child: summary.byCategory.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text(
                            _txType == TxType.expense
                                ? "Aucune dépense sur cette période"
                                : "Aucun revenu sur cette période",
                            style: TextStyle(color: c.textMuted),
                          ),
                        ),
                      )
                    : ExpenseBreakdownCard(
                        title: _txType == TxType.expense
                            ? 'Répartition des dépenses'
                            : 'Répartition des revenus',
                        byCategory: summary.byCategory,
                        total: summary.total,
                        categories: categories,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(PeriodType type) {
    switch (type) {
      case PeriodType.day:
        return 'Jour';
      case PeriodType.week:
        return 'Semaine';
      case PeriodType.month:
        return 'Mois';
      case PeriodType.year:
        return 'Année';
    }
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : c.textMuted,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}
