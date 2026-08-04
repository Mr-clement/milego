import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/confirm_delete_dialog.dart';
import '../../shared/widgets/milego_card.dart';
import 'add_transaction_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    final txs = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final filtered = txs.where((t) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          categories.byId(t.categoryId).name.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Row(
              children: [
                Text(
                  'Transactions',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openAddSheet(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Rechercher (titre, catégorie)…',
                prefixIcon: Icon(Icons.search_rounded, color: c.textMuted),
                filled: true,
                fillColor: c.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: c.border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucune transaction',
                      style: TextStyle(color: c.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _TxTile(tx: filtered[i])
                        .animate()
                        .fadeIn(
                          duration: 220.ms,
                          delay: (i * 25).clamp(0, 200).ms,
                        )
                        .slideY(begin: 0.06, curve: Curves.easeOut),
                  ),
          ),
        ],
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }
}

class _TxTile extends ConsumerWidget {
  const _TxTile({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.milego;
    final cat = ref.watch(categoriesProvider).byId(tx.categoryId);
    final isIncome = tx.type == TxType.income;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(tx.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) =>
            confirmDelete(context, message: 'Supprimer « ${tx.title} » ?'),
        onDismissed: (_) =>
            ref.read(transactionsProvider.notifier).remove(tx.id),
        background: Container(
          margin: const EdgeInsets.only(bottom: 0),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: AppColors.expense,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: MilegoCard(
          padding: const EdgeInsets.all(14),
          radius: 18,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddTransactionSheet(existing: tx),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cat.name} · ${Dates.dayMonth(tx.date)}',
                      style: TextStyle(color: c.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${Money.full(tx.amount)}',
                style: TextStyle(
                  color: isIncome ? AppColors.income : c.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
