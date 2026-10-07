import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

String libraryItemId(dynamic item) => '${item['id'] ?? item['title']}';
String noticeId(dynamic note) =>
    note['id']?.toString() ??
    sha256
        .convert(utf8.encode('${note['subject']}\n${note['content']}'))
        .toString();

List<dynamic> filterLibrary(List<dynamic> library, String query, String type,
    bool savedOnly, Set<String> saved) {
  final normalized = query.trim().toLowerCase();
  return library
      .where((item) =>
          '${item['title'] ?? ''}'.toLowerCase().contains(normalized) &&
          (type == 'all' || item['type'] == type) &&
          (!savedOnly || saved.contains(libraryItemId(item))))
      .toList();
}

/// Device preferences contain IDs only and never grant access to a title.
class LibraryPreferences {
  final String scope;
  final Set<String> saved = {};
  final Set<String> readNotices = {};
  bool compact = false;
  LibraryPreferences(this.scope);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    saved
      ..clear()
      ..addAll(prefs.getStringList('${scope}_watchlist') ?? []);
    readNotices
      ..clear()
      ..addAll(prefs.getStringList('${scope}_read_notices') ?? []);
    compact = prefs.getBool('${scope}_compact_library') ?? false;
  }

  Future<void> toggleSaved(String id) async {
    if (!saved.remove(id)) saved.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${scope}_watchlist', saved.toList());
  }

  Future<void> markRead(Iterable<String> ids) async {
    readNotices.addAll(ids);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${scope}_read_notices', readNotices.toList());
  }

  Future<void> setCompact(bool value) async {
    compact = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${scope}_compact_library', value);
  }
}
