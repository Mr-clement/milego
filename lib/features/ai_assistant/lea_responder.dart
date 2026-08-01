import '../../core/utils/formatters.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

/// Générateur de réponses de Léa basé sur des règles simples.
///
/// Sert de doublure locale au microservice Python (FastAPI + LangChain + OpenAI)
/// décrit dans le cahier des charges. La signature reste orientée « contexte »
/// pour faciliter le remplacement par un vrai appel réseau plus tard.
class LeaResponder {
  static String reply(
    String question,
    MonthSummary s,
    List<SavingGoal> goals,
  ) {
    final q = question.toLowerCase();

    if (_matches(q, ['épargn', 'economis', 'économis', 'mettre de côté'])) {
      return 'Ce mois-ci, vos revenus sont de ${Money.full(s.income)} et vos '
          'dépenses de ${Money.full(s.expense)}. Vous pouvez donc épargner '
          'environ ${Money.full(s.savings)}. En réduisant vos dépenses non '
          'essentielles de 10 %, vous atteindriez ${Money.full(s.savings + s.expense * 0.1)}.';
    }

    if (_matches(q, ['dépense', 'depense', 'partent', 'catégor', 'categor'])) {
      if (s.byCategory.isEmpty) {
        return 'Je n\'ai pas encore assez de dépenses enregistrées ce mois-ci pour établir une répartition.';
      }
      final top = s.byCategory.take(3).map((e) {
        final pct = (e.value / s.expense * 100).round();
        return '${MockData.categoryById(e.key).name} ($pct %, ${Money.full(e.value)})';
      }).join(', ');
      return 'Vos principales dépenses du mois : $top. C\'est le poste le plus '
          'important qui offre le meilleur levier d\'économie.';
    }

    if (_matches(q, ['objectif', 'atteign', 'but', 'projet'])) {
      if (goals.isEmpty) return 'Vous n\'avez pas encore défini d\'objectif d\'épargne.';
      final buf = StringBuffer('Voici l\'état de vos objectifs :\n');
      for (final g in goals) {
        final restant = g.targetAmount - g.currentAmount;
        final mois = s.savings <= 0 ? null : (restant / s.savings).ceil();
        buf.writeln('• ${g.name} : ${(g.progress * 100).round()} % atteint'
            '${mois == null ? '' : ', ~$mois mois au rythme actuel'}.');
      }
      return buf.toString().trim();
    }

    if (_matches(q, ['budget', 'reste', 'restant', 'solde'])) {
      final pct = (s.budgetUsedRatio * 100).round();
      return 'Vous avez utilisé $pct % de votre budget de ${Money.full(s.budget)}. '
          'Il vous reste ${Money.full(s.remaining)} pour le reste du mois.';
    }

    if (_matches(q, ['bonjour', 'salut', 'coucou', 'hello', 'merci'])) {
      return 'Avec plaisir 😊 Je suis là pour vous aider à mieux gérer votre argent. '
          'Demandez-moi par exemple combien vous pouvez épargner ce mois-ci.';
    }

    return 'Bonne question ! Voici un aperçu : revenus ${Money.full(s.income)}, '
        'dépenses ${Money.full(s.expense)}, épargne possible ${Money.full(s.savings)}. '
        'Précisez si vous voulez parler d\'épargne, de budget, de vos dépenses par '
        'catégorie ou de vos objectifs. (Réponses détaillées via le service IA une fois connecté.)';
  }

  static bool _matches(String text, List<String> keys) =>
      keys.any(text.contains);
}
