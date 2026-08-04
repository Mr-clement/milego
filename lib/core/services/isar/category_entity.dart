import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';

import '../../../shared/models/models.dart';
import 'fast_hash.dart';
import 'icon_registry.dart';

part 'category_entity.g.dart';

@collection
class CategoryEntity {
  Id get isarId => fastHash(categoryId);

  late String categoryId;
  late String name;
  late String iconKey;
  late int colorValue;

  Category toDomain() => Category(
        id: categoryId,
        name: name,
        icon: IconRegistry.resolve(iconKey),
        color: Color(colorValue),
      );
}
