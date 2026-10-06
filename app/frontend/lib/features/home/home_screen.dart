import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/services/ota_service.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../iptv/iptv_screen.dart';
import '../xtream/xtream_screen.dart';
import '../player/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final api = ApiService();
  Timer? timer;
  Map<String, dynamic>? profile;
  String? token;
  List<dynamic> library = [
    {
      'id': 'mock_movie_1',
      'title': 'Cosmic Adventure',
      'type': 'movie',
      'mock': true,
      'is_kids_safe': false
    },
    {
      'id': 'mock_movie_2',
      'title': 'Dark Thriller',
      'type': 'movie',
      'mock': true,
      'is_kids_safe': false
    },
    {
      'id': 'mock_show_1',
      'title': 'Cartoon Funtime',
      'type': 'show',
      'mock': true,
      'is_kids_safe': true
    },
  ];
  List<dynamic> notifications = [];
  String? error;
  int tab = 0;
  bool loading = true;
  bool refreshing = false;
  @override
  void initState() {
    super.initState();
    refresh();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    WidgetsBinding.instance
        .addPostFrameCallback((_) => OtaService.check(context));
  }

  Future<void> refresh() async {
    if (refreshing) return;
    refreshing = true;
    try {
      final user = await api.getProfile();
      if (!mounted) return;
      if (user == null && ApiService.sessionRejected) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false);
        return;
      }
      profile = user;
      if (user?['profile_type'] == 'kids') {
        library =
            library.where((item) => item['is_kids_safe'] == true).toList();
      }
      token = await api.getToken();
      error = null;
      if (ApiService.serverOnline.value && user != null) {
        try {
          library = await api.requestJson('/plex/library') as List<dynamic>;
        } catch (_) {
          error = 'Plex no está disponible. Live TV sigue disponible.';
          library = [];
        }
        notifications = await api.getGlobalNotifications();
        if (mounted) OtaService.check(context);
      }
      if (mounted) setState(() => loading = false);
    } finally {
      refreshing = false;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ApiService.serverOnline,
      builder: (context, online, _) => Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text('VAULT',
              style: TextStyle(letterSpacing: 5, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
                tooltip: 'Mi perfil',
                icon: const CircleAvatar(child: Icon(Icons.person_outline)),
                onPressed: profile == null
                    ? null
                    : () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProfileScreen(initialData: profile!)));
                        refresh();
                      })
          ],
        ),
        body: Column(children: [
          Material(
              color: online ? const Color(0xFF123029) : const Color(0xFF33241A),
              child: ListTile(
                dense: true,
                leading: Icon(
                    online
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    color: online ? Colors.greenAccent : Colors.orangeAccent),
                title: Text(online
                    ? 'Servidor conectado'
                    : 'Servidor desconectado · Live TV disponible'),
                subtitle: online
                    ? null
                    : const Text(
                        'Se usan las últimas listas guardadas. Plex y Xtream requieren el servidor.'),
                trailing: IconButton(
                    tooltip: 'Reconectar',
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh)),
              )),
          Expanded(
              child: IndexedStack(index: tab, children: [
            RefreshIndicator(
                onRefresh: refresh,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Text('Hola, ${profile?['display_name'] ?? 'bienvenido'}',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1C1628),
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.campaign_outlined,
                                  color: Colors.amber),
                              SizedBox(width: 10),
                              Text('Notificaciones del administrador')
                            ]),
                            const SizedBox(height: 8),
                            if (notifications.isEmpty)
                              const Text('No hay avisos por ahora.',
                                  style: TextStyle(color: Colors.white60)),
                            for (final note in notifications)
                              Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                      '${note['subject']}\n${note['content']}')),
                          ])),
                  const SizedBox(height: 24),
                  const Text('Películas y series',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (!online)
                    const Text(
                        'Conecta con Vault para abrir tu biblioteca Plex.'),
                  if (error != null)
                    Text(error!,
                        style: const TextStyle(color: Colors.orangeAccent)),
                  if (loading) const LinearProgressIndicator(),
                  if (!loading && library.isEmpty && online && error == null)
                    const Text('Tu biblioteca Plex está vacía.'),
                  const SizedBox(height: 16),
                  if (library.isNotEmpty)
                    GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.sizeOf(context).width > 700 ? 5 : 2,
                            childAspectRatio: .72,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14),
                        itemCount: library.length,
                        itemBuilder: (context, i) {
                          final item = library[i];
                          return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: !online
                                  ? null
                                  : () => openPlex(context, item),
                              child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            i.isEven
                                                ? const Color(0xFF422D67)
                                                : const Color(0xFF153B51),
                                            const Color(0xFF111118)
                                          ])),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child: item['mock'] != true &&
                                                    item['poster'] != null
                                                ? Image.network(
                                                    '${ApiService.baseUrl}${item['poster']}',
                                                    headers: {
                                                      'Authorization':
                                                          'Bearer $token'
                                                    },
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        const Icon(Icons.movie_outlined,
                                                            size: 64,
                                                            color:
                                                                Colors.white54))
                                                : Center(
                                                    child: Icon(
                                                        item['type'] == 'show'
                                                            ? Icons
                                                                .video_library_outlined
                                                            : Icons.movie_outlined,
                                                        size: 64,
                                                        color: Colors.white54))),
                                        if (item['mock'] == true)
                                          const Text('PRÓXIMAMENTE · PLEX',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.amber)),
                                        const SizedBox(height: 8),
                                        Text(item['title'] ?? 'Plex',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                            item['type'] == 'show'
                                                ? 'Serie'
                                                : 'Película',
                                            style: const TextStyle(
                                                color: Colors.white60)),
                                      ])));
                        }),
                ])),
            const IptvScreen(),
            const XtreamScreen(),
          ])),
        ]),
        bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.movie_outlined),
                  selectedIcon: Icon(Icons.movie),
                  label: 'Inicio'),
              NavigationDestination(
                  icon: Icon(Icons.live_tv_outlined),
                  selectedIcon: Icon(Icons.live_tv),
                  label: 'Live TV'),
              NavigationDestination(
                  icon: Icon(Icons.hub_outlined),
                  selectedIcon: Icon(Icons.hub),
                  label: 'Xtream'),
            ]),
      ),
    );
  }
}

Future<void> openPlex(BuildContext context, dynamic item) async {
  if (!ApiService.serverOnline.value) return;
  if (item['mock'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Vista de demostración. Configura tu servidor Plex para reproducir películas y series.')));
    return;
  }
  if (item['type'] == 'show' || item['type'] == 'season') {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PlexChildrenScreen(
                id: item['id'].toString(), title: item['title'])));
    return;
  }
  final token = await ApiService().getToken();
  if (!context.mounted || !ApiService.serverOnline.value) return;
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PlayerScreen(
              streamUrl: '${ApiService.baseUrl}${item['stream_url']}',
              contentId: item['id'].toString(),
              contentTitle: item['title'],
              source: 'plex',
              isKidsSafe: item['is_kids_safe'] == true,
              headers: {'Authorization': 'Bearer $token'})));
}

class PlexChildrenScreen extends StatefulWidget {
  final String id;
  final String title;
  const PlexChildrenScreen({super.key, required this.id, required this.title});
  @override
  State<PlexChildrenScreen> createState() => _PlexChildrenScreenState();
}

class _PlexChildrenScreenState extends State<PlexChildrenScreen> {
  late final Future<dynamic> items =
      ApiService().requestJson('/plex/children/${widget.id}');
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<dynamic>(
          future: items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('No se pudo abrir la serie. Comprueba Plex.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data as List<dynamic>;
            return ListView(children: [
              for (final item in data)
                ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(item['title']),
                    onTap: () => openPlex(context, item))
            ]);
          }));
}
