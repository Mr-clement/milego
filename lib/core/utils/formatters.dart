import 'package:intl/intl.dart';

/// Formatage des montants en FCFA et des dates (fr).
class Money {
  Money._();

  static final NumberFormat _full = NumberFormat.decimalPattern('fr_FR');

  /// Ex : `185 400 FCFA`
  static String full(num value) => '${_full.format(value.round())} FCFA';

  /// Ex : `340k` — format compact pour les statistiques.
  static String compact(num value) {
    final v = value.abs();
    String out;
    if (v >= 1000000) {
      out = '${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M';
    } else if (v >= 1000) {
      out = '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
    } else {
      out = v.toStringAsFixed(0);
    }
    return value < 0 ? '-$out' : out;
  }
}

class Dates {
  Dates._();
  static String dayMonth(DateTime d) =>
      DateFormat('d MMM', 'fr_FR').format(d);
  static String full(DateTime d) =>
      DateFormat('EEEE d MMMM', 'fr_FR').format(d);
}
