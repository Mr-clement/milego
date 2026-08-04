import 'package:intl/intl.dart';

import '../../shared/models/models.dart';

enum PeriodType { day, week, month, year }

class PeriodRange {
  const PeriodRange({required this.start, required this.end, required this.label});

  /// Inclus.
  final DateTime start;

  /// Exclu (début de la période suivante).
  final DateTime end;

  final String label;
}

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

PeriodRange periodRangeFor(PeriodType type, DateTime anchor) {
  switch (type) {
    case PeriodType.day:
      final start = _dayOnly(anchor);
      final end = start.add(const Duration(days: 1));
      final isToday = start == _dayOnly(DateTime.now());
      final label = DateFormat('d MMMM', 'fr_FR').format(start);
      return PeriodRange(
        start: start,
        end: end,
        label: isToday ? "Aujourd'hui, $label" : label,
      );

    case PeriodType.week:
      final today = _dayOnly(anchor);
      final start = today.subtract(Duration(days: today.weekday - 1));
      final end = start.add(const Duration(days: 7));
      final lastDay = end.subtract(const Duration(days: 1));
      final fmt = DateFormat('d MMM', 'fr_FR');
      return PeriodRange(
        start: start,
        end: end,
        label: 'Semaine du ${fmt.format(start)} au ${fmt.format(lastDay)}',
      );

    case PeriodType.month:
      final start = DateTime(anchor.year, anchor.month, 1);
      final end = DateTime(anchor.year, anchor.month + 1, 1);
      return PeriodRange(
        start: start,
        end: end,
        label: DateFormat('MMMM yyyy', 'fr_FR').format(start),
      );

    case PeriodType.year:
      final start = DateTime(anchor.year, 1, 1);
      final end = DateTime(anchor.year + 1, 1, 1);
      return PeriodRange(start: start, end: end, label: '${anchor.year}');
  }
}

DateTime shiftAnchor(PeriodType type, DateTime anchor, int direction) {
  switch (type) {
    case PeriodType.day:
      return anchor.add(Duration(days: direction));
    case PeriodType.week:
      return anchor.add(Duration(days: 7 * direction));
    case PeriodType.month:
      return DateTime(anchor.year, anchor.month + direction, 1);
    case PeriodType.year:
      return DateTime(anchor.year + direction, anchor.month, 1);
  }
}

class PeriodSummary {
  const PeriodSummary({required this.total, required this.byCategory});

  final double total;

  /// categoryId -> montant, trié décroissant.
  final List<MapEntry<String, double>> byCategory;
}

PeriodSummary summarizeForPeriod(
  List<Transaction> txs,
  PeriodRange range,
  TxType type,
) {
  double total = 0;
  final byCat = <String, double>{};

  for (final t in txs) {
    if (t.type != type) continue;
    if (t.date.isBefore(range.start) || !t.date.isBefore(range.end)) continue;
    total += t.amount;
    byCat.update(t.categoryId, (v) => v + t.amount, ifAbsent: () => t.amount);
  }

  final sorted = byCat.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return PeriodSummary(total: total, byCategory: sorted);
}
