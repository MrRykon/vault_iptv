import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/services/ota_service.dart';
import '../../core/services/library_preferences.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../iptv/iptv_screen.dart';
import '../xtream/xtream_screen.dart';
import '../player/player_screen.dart';
import 'library_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final api = ApiService();
  late final preferences = LibraryPreferences(ApiService.cacheKey);
  final searchController = TextEditingController();
  Timer? timer;
  Timer? debounce;
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
  String query = '';
  String type = 'all';
  bool savedOnly = false;
  int tab = 0;
  bool loading = true;
  bool refreshing = false;
  List<dynamic> get unread => notifications
      .where((note) => !preferences.readNotices.contains(noticeId(note)))
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
    startTimer();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => OtaService.check(context));
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

  Future<void> inbox() async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
            builder: (context, updateSheet) => SafeArea(
                child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * .7,
                    child: Column(children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(children: [
                            const Expanded(
                                child: Text('Tus avisos',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold))),
                            TextButton(
                                onPressed: unread.isEmpty
                                    ? null
                                    : () async {
                                        await preferences.markRead(
                                            notifications.map(noticeId));
                                        if (mounted) setState(() {});
                                        if (sheetContext.mounted) {
                                          updateSheet(() {});
                                        }
                                      },
                                child: const Text('Leer todos')),
                          ])),
                      Expanded(
                          child: notifications.isEmpty
                              ? const Center(
                                  child: Text('No hay avisos por ahora.'))
                              : ListView.builder(
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final note = notifications[index];
                                    final read = preferences.readNotices
                                        .contains(noticeId(note));
                                    return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 10),
                                        leading: Icon(read
                                            ? Icons.mark_email_read_outlined
                                            : Icons.mark_email_unread_outlined),
                                        title: Text(note['subject'] ?? 'Vault'),
                                        subtitle: Text(note['content'] ?? ''),
                                        trailing: read
                                            ? null
                                            : const Icon(Icons.circle,
                                                size: 8,
                                                color: Color(0xFFB49EFF)),
                                        onTap: () async {
                                          await preferences
                                              .markRead([noticeId(note)]);
                                          if (mounted) setState(() {});
                                          if (sheetContext.mounted) {
                                            updateSheet(() {});
                                          }
                                        });
                                  })),
                    ])))));
  }

  Future<void> toggleSaved(dynamic item) async {
    await preferences.toggleSaved(libraryItemId(item));
    if (mounted) setState(() {});
  }

  Widget hero(bool online) {
    final mobile = MediaQuery.sizeOf(context).width <= 450;
    return Container(
        padding: EdgeInsets.all(mobile ? 20 : 24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
                colors: [Color(0xFF392A54), Color(0xFF171A2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('TU ESPACIO DE ENTRETENIMIENTO',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: Color(0xFFD1BEFF))),
                const SizedBox(height: 12),
                Text('Tu próxima historia\nempieza aquí.',
                    style: TextStyle(
                        fontSize: mobile ? 24 : 27,
                        height: 1.1,
                        fontWeight: FontWeight.w800)),
                if (!mobile) ...[
                  const SizedBox(height: 10),
                  Text(
                      online
                          ? 'Películas, series y televisión a tu ritmo.'
                          : 'Mientras vuelve el servidor, sigue con Live TV.',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                    onPressed: () => setState(() => tab = 1),
                    icon: const Icon(Icons.live_tv, size: 18),
                    label: const Text('Explorar Live TV')),
              ])),
          if (MediaQuery.sizeOf(context).width > 450)
            const Padding(
                padding: EdgeInsets.only(left: 24),
                child: Icon(Icons.auto_awesome,
                    size: 80, color: Color(0xFF8B75B1))),
        ]));
  }

  Widget libraryView(bool online) {
    final results =
        filterLibrary(library, query, type, savedOnly, preferences.saved);
    final latest = unread.isNotEmpty
        ? unread.first
        : (notifications.isNotEmpty ? notifications.first : null);
    return RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(
            key: const PageStorageKey('vault-library'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            'Hola, ${profile?['display_name'] ?? 'bienvenido'}',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 6),
                        const Text('Haz espacio para lo que te gusta.',
                            style: TextStyle(color: Colors.white60)),
                        const SizedBox(height: 20),
                        if (!preferences.compact) ...[
                          hero(online),
                          const SizedBox(height: 18)
                        ],
                        Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                                leading: const Icon(Icons.campaign_outlined),
                                title: Text(
                                    latest == null
                                        ? 'No hay avisos por ahora.'
                                        : '${latest['subject']}\n${latest['content']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: inbox)),
                        const SizedBox(height: 22),
                        Row(children: [
                          const Expanded(
                              child: Text('Películas y series',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold))),
                          IconButton(
                              tooltip: preferences.compact
                                  ? 'Vista cómoda'
                                  : 'Vista compacta',
                              icon: Icon(preferences.compact
                                  ? Icons.view_comfortable_outlined
                                  : Icons.grid_view),
                              onPressed: () async {
                                await preferences
                                    .setCompact(!preferences.compact);
                                if (mounted) setState(() {});
                              })
                        ]),
                        const SizedBox(height: 12),
                        TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                                hintText: 'Buscar películas y series',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Limpiar búsqueda',
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          debounce?.cancel();
                                          searchController.clear();
                                          setState(() => query = '');
                                        })),
                            onChanged: (value) {
                              debounce?.cancel();
                              debounce =
                                  Timer(const Duration(milliseconds: 180), () {
                                if (mounted) setState(() => query = value);
                              });
                            }),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              for (final entry in {
                                'all': 'Todo',
                                'movie': 'Películas',
                                'show': 'Series'
                              }.entries)
                                Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                        label: Text(entry.value),
                                        selected: type == entry.key,
                                        onSelected: (_) =>
                                            setState(() => type = entry.key))),
                              FilterChip(
                                  label: const Text('Mi lista'),
                                  avatar: const Icon(Icons.bookmark_border,
                                      size: 16),
                                  selected: savedOnly,
                                  onSelected: (value) =>
                                      setState(() => savedOnly = value)),
                            ])),
                        const SizedBox(height: 10),
                        Text('${results.length} títulos',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        if (!online)
                          const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                  'Conecta con Vault para abrir tu biblioteca Plex.')),
                        if (error != null)
                          Text(error!,
                              style:
                                  const TextStyle(color: Colors.orangeAccent)),
                        if (loading) const LinearProgressIndicator(),
                      ]))),
              if (results.isEmpty && !loading)
                const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(children: [
                          Icon(Icons.movie_filter_outlined,
                              size: 40, color: Colors.white38),
                          SizedBox(height: 12),
                          Text(
                              'No hay títulos con estos filtros. Guarda títulos con el marcador para crear Mi lista.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white60))
                        ]))),
              SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: preferences.compact ? 190 : 290,
                          childAspectRatio: .69,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = results[index];
                        return LibraryCard(
                            key: ValueKey(libraryItemId(item)),
                            item: item,
                            index: index,
                            posterUrl:
                                item['mock'] != true && item['poster'] != null
                                    ? '${ApiService.baseUrl}${item['poster']}'
                                    : null,
                            token: token,
                            saved:
                                preferences.saved.contains(libraryItemId(item)),
                            enabled: online,
                            onOpen: () => openPlex(context, item),
                            onSave: () => toggleSaved(item));
                      }, childCount: results.length))),
            ]));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
      valueListenable: ApiService.serverOnline,
      builder: (context, online, _) {
        final wide = MediaQuery.sizeOf(context).width >= 1000;
        return Scaffold(
            appBar: AppBar(
                title: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFB49EFF)),
                  SizedBox(width: 10),
                  Text('VAULT',
                      style: TextStyle(
                          letterSpacing: 4, fontWeight: FontWeight.w800))
                ]),
                actions: [
                  IconButton(
                      tooltip: 'Avisos',
                      onPressed: inbox,
                      icon: Badge(
                          isLabelVisible: unread.isNotEmpty,
                          label: Text('${unread.length}'),
                          child: const Icon(Icons.notifications_none))),
                  IconButton(
                      tooltip: 'Mi perfil',
                      icon: const CircleAvatar(
                          radius: 17,
                          child: Icon(Icons.person_outline, size: 20)),
                      onPressed: profile == null
                          ? null
                          : () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProfileScreen(
                                          initialData: profile!)));
                              refresh();
                            }),
                  const SizedBox(width: 8),
                ]),
            body: SafeArea(
                child: Row(children: [
              if (wide)
                NavigationRail(
                    selectedIndex: tab,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (value) =>
                        setState(() => tab = value),
                    destinations: const [
                      NavigationRailDestination(
                          icon: Icon(Icons.movie_outlined),
                          label: Text('Inicio')),
                      NavigationRailDestination(
                          icon: Icon(Icons.live_tv), label: Text('Live TV')),
                      NavigationRailDestination(
                          icon: Icon(Icons.hub_outlined), label: Text('Xtream'))
                    ]),
              Expanded(
                  child: Column(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    color: online
                        ? const Color(0xFF13251F)
                        : const Color(0xFF302519),
                    child: Row(children: [
                      Icon(
                          online
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined,
                          size: 16,
                          color: online
                              ? const Color(0xFF94CBAF)
                              : Colors.orangeAccent),
                      const SizedBox(width: 9),
                      Expanded(
                          child: Text(
                              online
                                  ? 'Servidor conectado'
                                  : 'Servidor desconectado · Live TV disponible',
                              style: const TextStyle(fontSize: 11))),
                      IconButton(
                          tooltip: 'Reconectar',
                          onPressed: refreshing ? null : refresh,
                          icon: const Icon(Icons.refresh, size: 19))
                    ])),
                Expanded(
                    child: IndexedStack(index: tab, children: [
                  libraryView(online),
                  const IptvScreen(),
                  const XtreamScreen()
                ])),
              ])),
            ])),
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: tab,
                    onDestinationSelected: (value) =>
                        setState(() => tab = value),
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
                      ]));
      });
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
