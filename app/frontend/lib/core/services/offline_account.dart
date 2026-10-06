import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// PBKDF2-HMAC-SHA256. Work runs outside the UI isolate on Android.
String deriveVerifier(Map<String, String> input) {
  final salt = base64Decode(input['salt']!);
  final hmac = Hmac(sha256, utf8.encode(input['password']!));
  var previous = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final result = List<int>.from(previous);
  for (var i = 1; i < 120000; i++) {
    previous = hmac.convert(previous).bytes;
    for (var j = 0; j < result.length; j++) {
      result[j] ^= previous[j];
    }
  }
  return base64Encode(result);
}

class OfflineAccount {
  static const storage = FlutterSecureStorage();
  static String key(String server, String user) =>
      'account_${sha256.convert(utf8.encode('$server\n$user'))}';

  static Future<void> remember(String server, String user, String password,
      Map<String, dynamic> profile, String token) async {
    final random = Random.secure();
    final salt = base64Encode(List.generate(32, (_) => random.nextInt(256)));
    final verifier =
        await compute(deriveVerifier, {'password': password, 'salt': salt});
    await storage.write(
        key: key(server, user),
        value: jsonEncode({
          'salt': salt,
          'verifier': verifier,
          'profile': profile,
          'token': token,
        }));
  }

  static Future<Map<String, dynamic>?> verify(
      String server, String user, String password) async {
    final raw = await storage.read(key: key(server, user));
    if (raw == null) return null;
    final record = jsonDecode(raw) as Map<String, dynamic>;
    final profile = record['profile'] as Map<String, dynamic>;
    final expiry =
        DateTime.tryParse(profile['access_expires_at']?.toString() ?? '');
    if (profile['account_status'] != 'active' ||
        (expiry != null && expiry.isBefore(DateTime.now().toUtc()))) {
      return null;
    }
    final derived = await compute(deriveVerifier,
        {'password': password, 'salt': record['salt'] as String});
    final expected = record['verifier'] as String;
    var difference = derived.length ^ expected.length;
    for (var i = 0; i < derived.length && i < expected.length; i++) {
      difference |= derived.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return difference == 0 ? record : null;
  }

  static Future<void> refreshProfile(
      String server, String user, Map<String, dynamic> profile) async {
    final raw = await storage.read(key: key(server, user));
    if (raw == null) return;
    final record = jsonDecode(raw) as Map<String, dynamic>;
    record['profile'] = profile;
    await storage.write(key: key(server, user), value: jsonEncode(record));
  }

  static Future<void> forget(String server, String user) =>
      storage.delete(key: key(server, user));
}
