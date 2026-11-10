import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/env.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;
  @override
  String toString() => 'GeminiException: $message';
}

/// Client Gemini pour l'assistante Léa. Doublure du microservice Python
/// prévu au cahier des charges (§3.2) — même rôle (conseillère financière
/// alimentée par le contexte de l'utilisateur), appelé directement depuis
/// Flutter pour l'instant.
class GeminiService {
  GeminiService._();

  static const _model = 'gemini-3.1-flash-lite';
  // La clé passe en en-tête (x-goog-api-key) et non en query string : une
  // URL finit dans les logs (proxy, http, crash reports), pas un en-tête.
  static final _endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent');

  /// Nombre max de messages d'historique envoyés : borne le coût en tokens
  /// et la latence quand la conversation s'allonge.
  static const _maxHistory = 10;

  static Future<String> reply({
    required String question,
    required MonthSummary summary,
    required List<SavingGoal> goals,
    required List<Category> categories,
    required List<ChatMessage> history,
  }) async {
    final response = await http
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': geminiApiKey,
          },
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': _systemPrompt(summary, goals, categories)},
              ],
            },
            'contents': [
              for (final m in history.length > _maxHistory
                  ? history.sublist(history.length - _maxHistory)
                  : history)
                {
                  'role': m.role == ChatRole.user ? 'user' : 'model',
                  'parts': [
                    {'text': m.content},
                  ],
                },
              {
                'role': 'user',
                'parts': [
                  {'text': question},
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw GeminiException('HTTP ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text is! String || text.trim().isEmpty) {
      throw GeminiException('Réponse vide ou inattendue');
    }
    return text.trim();
  }

  static String _systemPrompt(
    MonthSummary s,
    List<SavingGoal> goals,
    List<Category> categories,
  ) {
    final categoryLines = s.byCategory.map((e) {
      final cat = categories.byId(e.key);
      final pct = s.expense == 0 ? 0 : (e.value / s.expense * 100).round();
      return '- ${cat.name} : ${Money.full(e.value)} ($pct %)';
    }).join('\n');

    final goalLines = goals.map((g) {
      final pct = (g.progress * 100).round();
      return '- ${g.name} : ${Money.full(g.currentAmount)} / '
          '${Money.full(g.targetAmount)} ($pct %), échéance ${Dates.dayMonth(g.deadline)}';
    }).join('\n');

    return '''
Tu es Léa, l'assistante financière intégrée à l'application Milego Budget. Tu joues le rôle d'une conseillère financière humaine, bienveillante et directe — comme le ferait un comptable/conseiller personnel.

Règles :
- Réponds toujours en français, de façon concise (quelques phrases maximum), sans jargon inutile.
- Base tes réponses UNIQUEMENT sur les données financières ci-dessous (mois en cours).
- Donne des conseils concrets et chiffrés quand c'est pertinent (économie possible en FCFA, délai pour atteindre un objectif au rythme actuel...).
- Ne donne jamais de conseil d'investissement risqué (bourse, crypto) ; reste sur la gestion budgétaire personnelle.
- Si la question sort du cadre financier personnel, recentre poliment la conversation.

Situation financière du mois en cours :
- Revenus : ${Money.full(s.income)}
- Dépenses : ${Money.full(s.expense)}
- Budget mensuel : ${Money.full(s.budget)} (${(s.budgetUsedRatio * 100).round()} % utilisé, reste ${Money.full(s.remaining)})
- Épargne possible ce mois-ci : ${Money.full(s.savings)}

Répartition des dépenses par catégorie :
${categoryLines.isEmpty ? '(aucune dépense enregistrée ce mois-ci)' : categoryLines}

Objectifs d'épargne :
${goalLines.isEmpty ? '(aucun objectif défini)' : goalLines}
''';
  }
}
