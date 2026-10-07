import 'package:shared_preferences/shared_preferences.dart';

/// Stores only channel IDs, scoped to the current server and account.
class ChannelPreferences {
  final String scope;
  final Set<String> favorites = {};
  final List<String> recent = [];
  ChannelPreferences(this.scope);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    favorites
      ..clear()
      ..addAll(prefs.getStringList('${scope}_favorites') ?? []);
    recent
      ..clear()
      ..addAll((prefs.getStringList('${scope}_recent') ?? []).take(20));
  }

  Future<void> toggleFavorite(String id) async {
    if (!favorites.remove(id)) favorites.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${scope}_favorites', favorites.toList());
  }

  Future<void> markRecent(String id) async {
    recent.remove(id);
    recent.insert(0, id);
    if (recent.length > 20) recent.removeRange(20, recent.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${scope}_recent', recent);
  }
}
