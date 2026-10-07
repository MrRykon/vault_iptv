import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vault/core/services/channel_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('favorites persist and stay isolated between server/account scopes',
      () async {
    final user = ChannelPreferences('server-one-user');
    await user.load();
    await user.toggleFavorite('channel');
    final restored = ChannelPreferences('server-one-user');
    await restored.load();
    expect(restored.favorites, {'channel'});
    final other = ChannelPreferences('server-two-user');
    await other.load();
    expect(other.favorites, isEmpty);
    await restored.toggleFavorite('channel');
    await user.load();
    expect(user.favorites, isEmpty);
  });
  test('recents are unique, persist in order and keep only the latest 20 IDs',
      () async {
    final user = ChannelPreferences('account');
    for (var i = 0; i < 25; i++) {
      await user.markRecent('channel-$i');
    }
    await user.markRecent('channel-10');
    final restored = ChannelPreferences('account');
    await restored.load();
    expect(restored.recent, hasLength(20));
    expect(restored.recent.first, 'channel-10');
    expect(restored.recent.toSet(), hasLength(20));
    expect(restored.recent, isNot(contains('channel-0')));
  });
}
