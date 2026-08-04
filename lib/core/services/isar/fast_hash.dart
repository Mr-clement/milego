/// FNV-1a hash utilisé pour dériver un [Id] Isar (int) à partir d'un id
/// métier (String) stable — pattern documenté par Isar pour les entités
/// identifiées par une String plutôt qu'un auto-increment.
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
