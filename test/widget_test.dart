import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:milego_budget/main.dart';

void main() {
  testWidgets('Le Bilan affiche la salutation et le solde',
      (WidgetTester tester) async {
    await initializeDateFormatting('fr_FR', null);
    await tester.pumpWidget(const ProviderScope(child: MilegoApp()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.text('Solde restant ce mois'), findsOneWidget);
  });
}
