import 'package:flutter/material.dart';

/// Modèles de données de l'app (MVP en mémoire — voir cahier des charges §6).

enum TxType { income, expense, transfer }

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
}

extension CategoryLookup on List<Category> {
  Category byId(String id) =>
      firstWhere((c) => c.id == id, orElse: () => last);
}

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
  });

  final String id;
  final String title;
  final double amount; // toujours positif ; le signe est porté par [type]
  final TxType type;
  final String categoryId;
  final DateTime date;
  final String? note;

  double get signedAmount => type == TxType.expense ? -amount : amount;
}

@immutable
class SavingGoal {
  const SavingGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final IconData icon;
  final Color color;

  double get progress =>
      targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);
}

enum InsightType { alerte, conseil, projection }

@immutable
class AiInsight {
  const AiInsight({
    required this.type,
    required this.content,
    this.title = 'Conseil de Léa, votre assistante',
  });

  final InsightType type;
  final String title;
  final String content;
}

enum ChatRole { user, assistant }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final ChatRole role;
  final String content;
  final DateTime timestamp;
}
