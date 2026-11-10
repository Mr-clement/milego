import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentification locale simple (compte stocké sur l'appareil, non
/// synchronisé) — en attendant une vraie intégration Firebase Auth
/// (cahier des charges §5.1, chantier séparé bloqué sur la création d'un
/// projet Firebase côté utilisateur). Un seul compte possible (app
/// mono-utilisateur).
///
/// Mot de passe : PBKDF2-HMAC-SHA256 salé (sel aléatoire par compte),
/// calculé hors du thread UI via [compute] (isolate ; repli sur le thread
/// principal sur le web) pour ne pas figer l'interface. Les comptes créés avant
/// (SHA-256 nu, sans sel) restent valides et sont migrés à la première
/// connexion réussie.
class AuthService {
  AuthService(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboardingSeen = 'onboarding_seen';
  static const _kIsLoggedIn = 'is_logged_in';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';
  static const _kPasswordHash = 'password_hash';
  static const _kPasswordSalt = 'password_salt';

  /// Coût PBKDF2. Rend une attaque par force brute sur le hash extrait de
  /// l'appareil environ 10⁵ fois plus lente qu'avec un SHA-256 nu.
  static const _iterations = 100000;

  bool get hasSeenOnboarding => _prefs.getBool(_kOnboardingSeen) ?? false;
  Future<void> markOnboardingSeen() => _prefs.setBool(_kOnboardingSeen, true);

  bool get isLoggedIn => _prefs.getBool(_kIsLoggedIn) ?? false;
  String? get userName => _prefs.getString(_kUserName);

  /// Un compte local existe déjà (l'inscription ne doit pas l'écraser :
  /// sinon « S'inscrire » contournerait la connexion).
  bool get hasAccount => _prefs.getString(_kPasswordHash) != null;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final salt = _randomSalt();
    final hash = await _derive(password, salt);
    await _prefs.setString(_kUserName, name);
    await _prefs.setString(_kUserEmail, email.trim().toLowerCase());
    await _prefs.setString(_kPasswordSalt, salt);
    await _prefs.setString(_kPasswordHash, hash);
    await _prefs.setBool(_kIsLoggedIn, true);
  }

  Future<bool> logIn({required String email, required String password}) async {
    final storedEmail = _prefs.getString(_kUserEmail);
    final storedHash = _prefs.getString(_kPasswordHash);
    if (storedEmail == null || storedHash == null) return false;
    if (storedEmail != email.trim().toLowerCase()) return false;

    final salt = _prefs.getString(_kPasswordSalt);
    if (salt == null) {
      // Compte hérité : SHA-256 sans sel. On vérifie puis on migre.
      if (!_constantTimeEquals(storedHash, _legacyHash(password))) {
        return false;
      }
      final newSalt = _randomSalt();
      await _prefs.setString(_kPasswordSalt, newSalt);
      await _prefs.setString(_kPasswordHash, await _derive(password, newSalt));
    } else if (!_constantTimeEquals(storedHash, await _derive(password, salt))) {
      return false;
    }

    await _prefs.setBool(_kIsLoggedIn, true);
    return true;
  }

  Future<void> logOut() => _prefs.setBool(_kIsLoggedIn, false);

  static String _randomSalt() {
    final rnd = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => rnd.nextInt(256)));
  }

  static Future<String> _derive(String password, String salt) =>
      compute(_pbkdf2Entry, (password, salt));

  static String _pbkdf2Entry((String, String) args) =>
      pbkdf2Sha256(args.$1, args.$2, _iterations);

  static String _legacyHash(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// PBKDF2-HMAC-SHA256 (RFC 8018), un seul bloc de 32 octets — suffisant
/// pour un hash de vérification de mot de passe. Renvoie le hex du dérivé.
/// Public pour pouvoir être testé contre les vecteurs RFC 7914 §11.
String pbkdf2Sha256(String password, String salt, int iterations) {
  final hmac = Hmac(sha256, utf8.encode(password));
  // U1 = HMAC(P, S || INT_32_BE(1))
  final block1 = Uint8List.fromList([...utf8.encode(salt), 0, 0, 0, 1]);
  var u = hmac.convert(block1).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
