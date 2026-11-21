import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/services/channel_preferences.dart';
import '../player/player_screen.dart';

class IptvScreen extends StatefulWidget {
  const IptvScreen({super.key});
  @override
  State<IptvScreen> createState() => _IptvScreenState();
}

class _IptvScreenState extends State<IptvScreen> with WidgetsBindingObserver {
  List<dynamic> channels = [];
  late final preferences = ChannelPreferences(ApiService.cacheKey);
  bool loading = true;
  bool fetching = false;
  String search = '';
  String category = 'Todas';
  String view = 'Todos';
  bool alphabetical = false;
  Timer? timer;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
    startTimer();
  }

  Future<void> initialize() async {
    await preferences.load();
    await refresh();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
      startTimer();
    } else {
      timer?.cancel();
    }
  }

  Future<void> refresh() async {
    if (fetching) return;
    fetching = true;
    try {
      final data = await ApiService().getIptvChannels();
      if (mounted) {
        setState(() {
          channels = data ?? [];
          loading = false;
          if (category != 'Todas' &&
              !channels.any((c) => (c['category'] ?? 'General') == category)) {
            category = 'Todas';
          }
        });
      }
    } finally {
      fetching = false;
    }
  }

  Future<void> play(dynamic channel) async {
    await preferences.markRecent(channel['channel_id'].toString());
    if (!mounted) return;
    setState(() {});
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PlayerScreen(
                streamUrl: channel['stream_url'],
                contentId: channel['channel_id'].toString(),
                contentTitle: channel['channel_name'],
                source: 'iptv',
                isKidsSafe: channel['is_kids_safe'] == true)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = channels.where((c) {
      final id = c['channel_id'].toString();
      return '${c['channel_name']} ${c['category']}'
              .toLowerCase()
              .contains(search) &&
          (category == 'Todas' || (c['category'] ?? 'General') == category) &&
          (view != 'Favoritos' || preferences.favorites.contains(id)) &&
          (view != 'Recientes' || preferences.recent.contains(id));
    }).toList();
    if (view == 'Recientes') {
      final order = {
        for (var i = 0; i < preferences.recent.length; i++)
          preferences.recent[i]: i
      };
      results.sort((a, b) => order[a['channel_id'].toString()]!
          .compareTo(order[b['channel_id'].toString()]!));
    } else if (alphabetical) {
      results.sort((a, b) => '${a['channel_name']}'
          .toLowerCase()
          .compareTo('${b['channel_name']}'.toLowerCase()));
    }
    final categories = channels
        .map((c) => (c['category'] ?? 'General').toString())
        .toSet()
        .toList()
      ..sort();
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar canal o categoría'),
              onChanged: (value) {
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    setState(() => search = value.trim().toLowerCase());
                  }
                });
              })),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            for (final label in ['Todos', 'Favoritos', 'Recientes'])
              Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                      label: Text(label),
                      selected: view == label,
                      onSelected: (_) => setState(() => view = label))),
            const SizedBox(width: 8),
            DropdownButton<String>(
                value: category,
                items: ['Todas', ...categories.where((c) => c != 'Todas')]
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c == 'Todas' ? 'Todas las categorías' : c)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => category = value ?? 'Todas')),
            IconButton(
                tooltip: 'Ordenar A–Z',
                icon: Icon(Icons.sort_by_alpha,
                    color: alphabetical ? Colors.amber : null),
                onPressed: () => setState(() => alphabetical = !alphabetical)),
          ])),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${results.length} canales',
                  style: Theme.of(context).textTheme.bodySmall))),
      Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: results.isEmpty ? 1 : results.length,
                      itemBuilder: (context, index) {
                        if (results.isEmpty) {
                          return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(channels.isEmpty
                                  ? 'No hay canales. Agrega tus listas a playlists del servidor.'
                                  : view == 'Favoritos'
                                      ? 'Marca la estrella de un canal para guardarlo aquí.'
                                      : view == 'Recientes'
                                          ? 'Aquí aparecerán los últimos canales que abras.'
                                          : 'No hay canales con estos filtros.'));
                        }
                        final channel = results[index];
                        final id = channel['channel_id'].toString();
                        final favorite = preferences.favorites.contains(id);
                        return Card(
                            key: ValueKey(id),
                            child: ListTile(
                                leading: const Icon(Icons.live_tv,
                                    color: Colors.amber),
                                title: Text(channel['channel_name'] ?? 'Canal'),
                                subtitle:
                                    Text(channel['category'] ?? 'General'),
                                trailing: IconButton(
                                    tooltip: favorite
                                        ? 'Quitar de favoritos'
                                        : 'Agregar a favoritos',
                                    icon: Icon(
                                        favorite
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: favorite ? Colors.amber : null),
                                    onPressed: () async {
                                      await preferences.toggleFavorite(id);
                                      if (mounted) setState(() {});
                                    }),
                                onTap: () => play(channel)));
                      }))),
    ]);
  }
}
