import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vault/core/services/library_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'watchlist, read notices and compact mode persist per account and server',
      () async {
    final preferences = LibraryPreferences('server-user');
    await preferences.toggleSaved('movie');
    await preferences.markRead(['notice']);
    await preferences.setCompact(true);
    final restored = LibraryPreferences('server-user');
    await restored.load();
    expect(restored.saved, {'movie'});
    expect(restored.readNotices, {'notice'});
    expect(restored.compact, true);
    final other = LibraryPreferences('another-server-user');
    await other.load();
    expect(other.saved, isEmpty);
    expect(other.readNotices, isEmpty);
    expect(other.compact, false);
  });
  test('library filtering cannot restore removed or unauthorized saved titles',
      () {
    final library = [
      {'id': 'movie', 'title': 'Cosmic Adventure', 'type': 'movie'},
      {'id': 'show', 'title': 'Cartoon Funtime', 'type': 'show'},
    ];
    expect(
        filterLibrary(
                library, ' COSMIC ', 'movie', true, {'movie', 'unavailable'})
            .length,
        1);
    expect(filterLibrary(library, '', 'show', true, {'movie'}), isEmpty);
    expect(filterLibrary([library.last], '', 'all', true, {'movie'}), isEmpty);
  });
  test('all selected notices are marked read and missing IDs are deterministic',
      () async {
    final preferences = LibraryPreferences('account');
    await preferences.markRead(List.generate(600, (index) => '$index'));
    expect(preferences.readNotices.length, 600);
    expect(preferences.readNotices, contains('0'));
    expect(noticeId({'subject': 'A', 'content': 'B'}),
        noticeId({'subject': 'A', 'content': 'B'}));
    expect(noticeId({'subject': 'A', 'content': 'B'}),
        isNot(noticeId({'subject': 'A', 'content': 'C'})));
  });
}
