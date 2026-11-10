import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:milego_budget/features/reports/period_utils.dart';
import 'package:milego_budget/shared/models/models.dart';

Transaction _tx(String id, DateTime date, double amount,
        {TxType type = TxType.expense, String cat = 'nourriture'}) =>
    Transaction(
      id: id,
      title: id,
      amount: amount,
      type: type,
      categoryId: cat,
      date: date,
    );

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  group('periodRangeFor', () {
    test('semaine : du lundi (inclus) au lundi suivant (exclu)', () {
      // Mercredi 11 novembre 2026.
      final r = periodRangeFor(PeriodType.week, DateTime(2026, 11, 11, 15));
      expect(r.start, DateTime(2026, 11, 9));
      expect(r.end, DateTime(2026, 11, 16));
    });

    test('mois de décembre : se termine au 1er janvier suivant', () {
      final r = periodRangeFor(PeriodType.month, DateTime(2026, 12, 20));
      expect(r.start, DateTime(2026, 12, 1));
      expect(r.end, DateTime(2027, 1, 1));
    });

    test('année : libellé = année', () {
      final r = periodRangeFor(PeriodType.year, DateTime(2026, 5, 3));
      expect(r.start, DateTime(2026, 1, 1));
      expect(r.end, DateTime(2027, 1, 1));
      expect(r.label, '2026');
    });
  });

  test('shiftAnchor mois : pas de débordement depuis un 31', () {
    // DateTime(2026, 2, 31) déborderait sur mars : on ancre au 1er.
    expect(shiftAnchor(PeriodType.month, DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 1));
  });

  test('summarizeForPeriod : bornes [start, end[, filtre type, tri décroissant',
      () {
    final range = periodRangeFor(PeriodType.month, DateTime(2026, 11, 15));
    final txs = [
      _tx('debut', DateTime(2026, 11, 1), 100),
      _tx('fin-exclue', DateTime(2026, 12, 1), 999),
      _tx('avant', DateTime(2026, 10, 31, 23, 59), 999),
      _tx('revenu', DateTime(2026, 11, 5), 999, type: TxType.income),
      _tx('loyer', DateTime(2026, 11, 10), 300, cat: 'loyer'),
      _tx('courses', DateTime(2026, 11, 20), 50),
    ];

    final s = summarizeForPeriod(txs, range, TxType.expense);

    expect(s.total, 450);
    expect(s.byCategory.map((e) => e.key).toList(), ['loyer', 'nourriture']);
    expect(s.byCategory.first.value, 300);
    expect(s.byCategory.last.value, 150);
  });
}
