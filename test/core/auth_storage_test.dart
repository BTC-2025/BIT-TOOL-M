import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/auth/auth_storage_io.dart';

void main() {
  group('AuthStorage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'TEST 4: token persistence - save, retrieve, hasToken, and remove',
      () async {
        final storage = AuthStorageIo();

        expect(await storage.hasToken(), false);
        expect(await storage.getToken(), isNull);

        const testToken = 'BNX_AUTH_TOKEN_TEST_12345';
        await storage.saveToken(testToken);

        expect(await storage.hasToken(), true);
        expect(await storage.getToken(), testToken);

        // Verify exact key is used
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(AuthStorage.tokenKey), testToken);

        await storage.removeToken();
        expect(await storage.hasToken(), false);
        expect(await storage.getToken(), isNull);
      },
    );

    test('hasToken returns false for empty or whitespace-only token', () async {
      final storage = AuthStorageIo();
      await storage.saveToken('   ');
      expect(await storage.hasToken(), false);
    });
  });
}
