import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentification locale simple (compte stocké sur l'appareil, non
/// synchronisé) — en attendant une vraie intégration Firebase Auth
/// (cahier des charges §5.1, chantier séparé bloqué sur la création d'un
/// projet Firebase côté utilisateur). Un seul compte possible (app
/// mono-utilisateur).
class AuthService {
  AuthService(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboardingSeen = 'onboarding_seen';
  static const _kIsLoggedIn = 'is_logged_in';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';
  static const _kPasswordHash = 'password_hash';

  bool get hasSeenOnboarding => _prefs.getBool(_kOnboardingSeen) ?? false;
  Future<void> markOnboardingSeen() => _prefs.setBool(_kOnboardingSeen, true);

  bool get isLoggedIn => _prefs.getBool(_kIsLoggedIn) ?? false;
  String? get userName => _prefs.getString(_kUserName);

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _prefs.setString(_kUserName, name);
    await _prefs.setString(_kUserEmail, email.trim().toLowerCase());
    await _prefs.setString(_kPasswordHash, _hash(password));
    await _prefs.setBool(_kIsLoggedIn, true);
  }

  Future<bool> logIn({required String email, required String password}) async {
    final storedEmail = _prefs.getString(_kUserEmail);
    final storedHash = _prefs.getString(_kPasswordHash);
    if (storedEmail == null || storedHash == null) return false;
    if (storedEmail != email.trim().toLowerCase()) return false;
    if (storedHash != _hash(password)) return false;
    await _prefs.setBool(_kIsLoggedIn, true);
    return true;
  }

  Future<void> logOut() => _prefs.setBool(_kIsLoggedIn, false);

  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();
}
