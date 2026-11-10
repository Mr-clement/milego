import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:milego_budget/core/utils/formatters.dart';
import 'package:milego_budget/features/ai_assistant/lea_responder.dart';
import 'package:milego_budget/shared/models/models.dart';
import 'package:milego_budget/shared/providers/app_providers.dart';

Category _cat(String id, String name) =>
    Category(id: id, name: name, icon: Icons.category, color: Colors.grey);

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  group('CategoryLookup.byId', () {
    // « Autres » volontairement PAS en dernière position : l'ancien repli
    // (`orElse: () => last`) aurait renvoyé « Salaire ».
    final cats = [
      _cat('loyer', 'Loyer'),
      _cat('autres', 'Autres'),
      _cat('salaire', 'Salaire'),
    ];

    test('id connu', () => expect(cats.byId('salaire').name, 'Salaire'));

    test('id inconnu : repli sur « Autres »',
        () => expect(cats.byId('inconnu').name, 'Autres'));

    test('sans « Autres » : repli sur la dernière catégorie', () {
      final sansAutres = [_cat('loyer', 'Loyer'), _cat('salaire', 'Salaire')];
      expect(sansAutres.byId('inconnu').name, 'Salaire');
    });
  });

  group('LeaResponder', () {
    const summary = MonthSummary(
      income: 340000,
      expense: 100000,
      savings: 240000,
      budget: 270000,
      byCategory: [MapEntry('loyer', 60000), MapEntry('nourriture', 40000)],
    );
    final cats = [
      _cat('loyer', 'Loyer'),
      _cat('nourriture', 'Nourriture'),
      _cat('autres', 'Autres'),
    ];

    test('question épargne : cite l’épargne possible', () {
      final r = LeaResponder.reply(
          'Combien puis-je épargner ?', summary, const [], cats);
      expect(r, contains(Money.full(240000)));
    });

    test('question dépenses : cite les catégories avec leur part', () {
      final r = LeaResponder.reply(
          'Où partent mes dépenses ?', summary, const [], cats);
      expect(r, contains('Loyer (60 %'));
      expect(r, contains('Nourriture (40 %'));
    });

    test('objectifs sans objectif défini', () {
      final r = LeaResponder.reply(
          'Mes objectifs sont-ils atteignables ?', summary, const [], cats);
      expect(r, contains("pas encore défini"));
    });
  });
}
