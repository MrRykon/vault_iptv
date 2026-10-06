import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../player/player_screen.dart';

class IptvScreen extends StatefulWidget {
  const IptvScreen({super.key});
  @override
  State<IptvScreen> createState() => _IptvScreenState();
}

class _IptvScreenState extends State<IptvScreen> {
  List<dynamic> channels = [];
  bool loading = true;
  bool fetching = false;
  String search = '';
  Timer? timer;
  @override
  void initState() {
    super.initState();
    refresh();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
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
        });
      }
    } finally {
      fetching = false;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = channels
        .where((c) => '${c['channel_name']} ${c['category']}'
            .toLowerCase()
            .contains(search.toLowerCase()))
        .toList();
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar canal o categoría'),
              onChanged: (v) => setState(() => search = v))),
      Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (results.isEmpty)
                          const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                  'No hay canales. Agrega tus listas a la carpeta playlists del servidor.')),
                        for (final c in results)
                          Card(
                              child: ListTile(
                            leading:
                                const Icon(Icons.live_tv, color: Colors.amber),
                            title: Text(c['channel_name'] ?? 'Canal'),
                            subtitle: Text(c['category'] ?? 'General'),
                            trailing: const Icon(Icons.play_circle_fill),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PlayerScreen(
                                        streamUrl: c['stream_url'],
                                        contentId: c['channel_id'].toString(),
                                        contentTitle: c['channel_name'],
                                        source: 'iptv',
                                        isKidsSafe:
                                            c['is_kids_safe'] == true))),
                          )),
                      ]))),
    ]);
  }
}
