import 'package:flutter_test/flutter_test.dart';
import 'package:vault/core/services/playlist_parser.dart';
import 'package:vault/core/services/ota_service.dart';
import 'package:vault/core/services/offline_account.dart';

void main() {
  test('M3U attribute order, comma in category and unsafe schemes', () {
    final channels = parsePlaylist(
        '#EXTM3U\n#EXTINF:-1 group-title="Kids, Family" tvg-name="Cartoon",Other\nhttps://example.org/live\n#EXTINF:-1,Unsafe\nfile:///private\n');
    expect(channels, hasLength(1));
    expect(channels.first['channel_name'], 'Cartoon');
    expect(channels.first['is_kids_safe'], true);
  });
  test('OTA requires a newer Android build and prevents version downgrade', () {
    expect(
        isNewerRelease(
            {'available': true, 'latest_version': '0.2.0', 'latest_build': 2},
            '0.1.0',
            1),
        true);
    expect(
        isNewerRelease(
            {'available': true, 'latest_version': '0.2.0', 'latest_build': 1},
            '0.1.0',
            1),
        false);
    expect(
        isNewerRelease(
            {'available': true, 'latest_version': '0.0.9', 'latest_build': 9},
            '0.1.0',
            1),
        false);
    expect(isNewerRelease({'available': false}, '0.1.0', 1), false);
  });
  test('PBKDF2 verifier matches authoritative Python hashlib output', () {
    expect(
        deriveVerifier(
            {'password': 'vault-test', 'salt': 'AAECAwQFBgcICQoLDA0ODw=='}),
        'eoUqPywArdvvMxShaRGY9Dy+gazC/H0T3j0S3b/zyOc=');
  });
  test('Offline accounts are separated by server and username', () {
    expect(OfflineAccount.key('https://one', 'user'),
        isNot(OfflineAccount.key('https://two', 'user')));
    expect(OfflineAccount.key('https://one', 'admin'),
        isNot(OfflineAccount.key('https://one', 'user')));
  });
}
