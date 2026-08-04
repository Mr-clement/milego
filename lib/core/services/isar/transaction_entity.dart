import 'package:isar_community/isar.dart';

import '../../../shared/models/models.dart';
import 'fast_hash.dart';

part 'transaction_entity.g.dart';

@collection
class TransactionEntity {
  Id get isarId => fastHash(txId);

  late String txId;
  late String title;
  late double amount;
  @enumerated
  late TxType type;
  late String categoryId;
  late DateTime date;
  String? note;

  Transaction toDomain() => Transaction(
        id: txId,
        title: title,
        amount: amount,
        type: type,
        categoryId: categoryId,
        date: date,
        note: note,
      );

  static TransactionEntity fromDomain(Transaction t) => TransactionEntity()
    ..txId = t.id
    ..title = t.title
    ..amount = t.amount
    ..type = t.type
    ..categoryId = t.categoryId
    ..date = t.date
    ..note = t.note;
}
