import 'package:flutter_test/flutter_test.dart';
import 'package:milego_budget/core/services/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pbkdf2Sha256 (vecteurs PBKDF2-HMAC-SHA256 de référence)', () {
    test('P="password", S="salt", c=1', () {
      expect(pbkdf2Sha256('password', 'salt', 1),
          '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
    });

    test('P="password", S="salt", c=4096', () {
      expect(pbkdf2Sha256('password', 'salt', 4096),
          'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a');
    });
  });

  group('AuthService', () {
    test('inscription puis connexion (bon / mauvais mot de passe)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = AuthService(prefs);

      expect(auth.hasAccount, isFalse);
      await auth.signUp(name: 'Awa', email: ' Awa@Mail.com ', password: 'secret123');
      expect(auth.hasAccount, isTrue);
      expect(prefs.getString('password_salt'), isNotNull);

      await auth.logOut();
      expect(await auth.logIn(email: 'awa@mail.com', password: 'mauvais'), isFalse);
      expect(auth.isLoggedIn, isFalse);
      expect(await auth.logIn(email: 'AWA@mail.com', password: 'secret123'), isTrue);
      expect(auth.isLoggedIn, isTrue);
    });

    test('deux comptes avec le même mot de passe : sels et hash différents',
        () async {
      SharedPreferences.setMockInitialValues({});
      final p1 = await SharedPreferences.getInstance();
      await AuthService(p1).signUp(name: 'A', email: 'a@a.a', password: 'secret123');
      final hash1 = p1.getString('password_hash');

      SharedPreferences.setMockInitialValues({});
      final p2 = await SharedPreferences.getInstance();
      await AuthService(p2).signUp(name: 'B', email: 'b@b.b', password: 'secret123');

      expect(p2.getString('password_hash'), isNot(hash1));
    });

    test('compte hérité (SHA-256 sans sel) : connexion acceptée puis migré',
        () async {
      // sha256("secret123"), format de l'ancienne version.
      const legacyHash =
          'fcf730b6d95236ecd3c9fc2d92d7b6b2bb061514961aec041d6c7a7192f592e4';
      SharedPreferences.setMockInitialValues({
        'user_name': 'Awa',
        'user_email': 'awa@mail.com',
        'password_hash': legacyHash,
      });
      final prefs = await SharedPreferences.getInstance();
      final auth = AuthService(prefs);

      expect(await auth.logIn(email: 'awa@mail.com', password: 'faux'), isFalse);
      expect(prefs.getString('password_salt'), isNull,
          reason: 'pas de migration sur un échec');

      expect(await auth.logIn(email: 'awa@mail.com', password: 'secret123'), isTrue);
      expect(prefs.getString('password_salt'), isNotNull);
      expect(prefs.getString('password_hash'), isNot(legacyHash));

      // Après migration, le même mot de passe fonctionne toujours.
      await auth.logOut();
      expect(await auth.logIn(email: 'awa@mail.com', password: 'secret123'), isTrue);
    });
  });
}
