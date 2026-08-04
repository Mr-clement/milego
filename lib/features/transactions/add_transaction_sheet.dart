import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

/// Feuille modale d'ajout (ou d'édition si [existing] est fourni) d'une
/// transaction (revenu / dépense).
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, this.existing});

  final Transaction? existing;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late final _title =
      TextEditingController(text: widget.existing?.title);
  late final _amount = TextEditingController(
      text: widget.existing?.amount.toStringAsFixed(0));
  late TxType _type = widget.existing?.type ?? TxType.expense;
  late String _categoryId = widget.existing?.categoryId ?? 'nourriture';

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amount.text.replaceAll(' ', '')) ?? 0;
    if (_title.text.trim().isEmpty || amount <= 0) return;
    final categoryId = _type == TxType.income ? 'salaire' : _categoryId;
    if (_isEditing) {
      ref.read(transactionsProvider.notifier).update(
            Transaction(
              id: widget.existing!.id,
              title: _title.text.trim(),
              amount: amount,
              type: _type,
              categoryId: categoryId,
              date: widget.existing!.date,
              note: widget.existing!.note,
            ),
          );
    } else {
      ref.read(transactionsProvider.notifier).add(
            Transaction(
              id: 'tx${DateTime.now().microsecondsSinceEpoch}',
              title: _title.text.trim(),
              amount: amount,
              type: _type,
              categoryId: categoryId,
              date: DateTime.now(),
            ),
          );
    }
    Navigator.of(context).pop();
  }

  void _delete() {
    ref.read(transactionsProvider.notifier).remove(widget.existing!.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    final expenseCats = ref
        .watch(categoriesProvider)
        .where((cat) => cat.id != 'salaire')
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_isEditing ? 'Modifier la transaction' : 'Nouvelle transaction',
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),

            // Type revenu / dépense
            Row(
              children: [
                _TypePill(
                  label: 'Dépense',
                  selected: _type == TxType.expense,
                  onTap: () => setState(() => _type = TxType.expense),
                ),
                const SizedBox(width: 10),
                _TypePill(
                  label: 'Revenu',
                  selected: _type == TxType.income,
                  onTap: () => setState(() => _type = TxType.income),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _Field(controller: _title, hint: 'Titre (ex : Courses)'),
            const SizedBox(height: 12),
            _Field(
              controller: _amount,
              hint: 'Montant (FCFA)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            if (_type == TxType.expense) ...[
              Text('Catégorie',
                  style: TextStyle(color: c.textMuted, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in expenseCats)
                    ChoiceChip(
                      label: Text(cat.name),
                      selected: _categoryId == cat.id,
                      onSelected: (_) =>
                          setState(() => _categoryId = cat.id),
                      selectedColor: AppColors.primarySoft,
                      labelStyle: TextStyle(
                        color: _categoryId == cat.id
                            ? AppColors.primaryDark
                            : c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.border),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
              child: const Text('Enregistrer',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _delete,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.expense,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Supprimer',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppColors.primary : c.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : c.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.border),
        ),
      ),
    );
  }
}
