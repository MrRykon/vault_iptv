import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  final int initialTab;
  const AdminSettingsScreen({super.key, this.initialTab = 0});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final api = ApiService();
  List<dynamic> users = [];
  String query = "";
  bool loading = true;
  bool allowed = false;
  bool busy = false;
  String? error;
  final search = TextEditingController();
  final subject = TextEditingController();
  final content = TextEditingController();
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final profile = await api.getProfile();
    final authorized =
        ApiService.serverOnline.value && profile?['admin_status'] == true;
    final data = authorized ? await api.getUsers() : null;
    if (mounted) {
      setState(() {
        allowed = authorized;
        users = data ?? [];
        loading = false;
        error = authorized && data == null
            ? 'No se pudo cargar la lista de usuarios.'
            : null;
      });
    }
  }

  Future<void> run(Future<bool> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    bool ok = false;
    try {
      ok = await action();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Cambios guardados.'
            : 'No se pudo guardar. Comprueba el servidor.')));
    if (ok) await refresh();
  }

  Future<void> createUser() async {
    final username = TextEditingController();
    final password = TextEditingController();
    String profileType = 'standard';
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, change) => AlertDialog(
                  title: const Text('Crear usuario'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: username,
                        decoration:
                            const InputDecoration(labelText: 'Usuario')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: password,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'Contraseña')),
                    DropdownButton<String>(
                        value: profileType,
                        items: const [
                          DropdownMenuItem(
                              value: 'standard', child: Text('Normal')),
                          DropdownMenuItem(
                              value: 'kids', child: Text('Infantil'))
                        ],
                        onChanged: (v) => change(() => profileType = v!)),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () {
                          if (username.text.trim().isNotEmpty &&
                              password.text.isNotEmpty) {
                            Navigator.pop(context, true);
                          }
                        },
                        child: const Text('Crear'))
                  ],
                )));
    if (result == true) {
      await run(() =>
          api.createUser(username.text.trim(), password.text, profileType));
    }
  }

  Future<void> resetPassword(dynamic user) async {
    final password = TextEditingController();
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Contraseña de ${user['custom_username']}'),
                content: TextField(
                    controller: password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Nueva contraseña')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () {
                        if (password.text.isNotEmpty) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text('Guardar'))
                ]));
    if (result == true) {
      await run(() => api.resetPassword(user['id'], password.text));
    }
  }

  Future<void> refreshPlaylists() async {
    await run(() async {
      final result = await api.requestJson('/iptv/refresh', body: {});
      return result['success'] == true;
    });
  }

  @override
  void dispose() {
    search.dispose();
    subject.dispose();
    content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab,
      child: Scaffold(
          appBar: AppBar(
              title: const Text('Centro de administración'),
              bottom: const TabBar(isScrollable: true, tabs: [
                Tab(text: 'Usuarios', icon: Icon(Icons.people_outline)),
                Tab(text: 'Avisos', icon: Icon(Icons.campaign_outlined)),
                Tab(text: 'Sistema', icon: Icon(Icons.tune))
              ])),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : !allowed
                  ? const Center(
                      child: Text(
                          'Necesitas una cuenta admin y el servidor conectado.'))
                  : Builder(
                      builder: (context) => ListenableBuilder(
                          listenable: DefaultTabController.of(context),
                          builder: (context, _) {
                            final tab = DefaultTabController.of(context).index;
                            return ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  if (busy) const LinearProgressIndicator(),
                                  if (error != null)
                                    Text(error!,
                                        style: const TextStyle(
                                            color: Colors.orangeAccent)),
                                  if (tab == 1) ...[
                                    const Text('Notificaciones',
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    TextField(
                                        controller: subject,
                                        decoration: const InputDecoration(
                                            labelText: 'Título')),
                                    const SizedBox(height: 12),
                                    TextField(
                                        controller: content,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                            labelText:
                                                'Mensaje para todos los usuarios')),
                                    const SizedBox(height: 12),
                                    FilledButton.icon(
                                        onPressed: busy
                                            ? null
                                            : () {
                                                if (subject.text
                                                        .trim()
                                                        .isNotEmpty &&
                                                    content.text
                                                        .trim()
                                                        .isNotEmpty) {
                                                  run(() => api
                                                      .sendGlobalNotification(
                                                          subject.text.trim(),
                                                          content.text.trim()));
                                                }
                                              },
                                        icon:
                                            const Icon(Icons.campaign_outlined),
                                        label: const Text('Enviar aviso')),
                                    const SizedBox(height: 24),
                                  ],
                                  if (tab == 2) ...[
                                    const Text('Listas IPTV',
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold)),
                                    const Text(
                                        'Se leen de la carpeta playlists cada 30 segundos.'),
                                    TextButton.icon(
                                        onPressed:
                                            busy ? null : refreshPlaylists,
                                        icon: const Icon(Icons.sync),
                                        label: const Text('Sincronizar ahora')),
                                    const SizedBox(height: 24),
                                  ],
                                  if (tab == 0) ...[
                                    Card(
                                        child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Text(
                                                "${users.length} cuentas · ${users.where((u) => u['account_status'] == 'active').length} activas",
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold)))),
                                    const SizedBox(height: 12),
                                    TextField(
                                        controller: search,
                                        decoration: const InputDecoration(
                                            labelText: "Buscar usuario",
                                            prefixIcon: Icon(Icons.search)),
                                        onChanged: (value) => setState(() =>
                                            query =
                                                value.toLowerCase().trim())),
                                    Row(children: [
                                      const Expanded(
                                          child: Text('Usuarios',
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      IconButton(
                                          tooltip: 'Crear usuario',
                                          onPressed: busy ? null : createUser,
                                          icon: const Icon(
                                              Icons.person_add_outlined))
                                    ]),
                                    for (final user in users.where((u) =>
                                        u['custom_username']
                                            .toString()
                                            .toLowerCase()
                                            .contains(query)))
                                      Card(
                                          child: Column(children: [
                                        ListTile(
                                            leading: Icon(
                                                user['admin_status'] == true
                                                    ? Icons.admin_panel_settings
                                                    : Icons.person_outline),
                                            title:
                                                Text(user['custom_username']),
                                            subtitle: Text(
                                                '${user['profile_type']} · ${user['account_status']}')),
                                        Wrap(spacing: 8, children: [
                                          TextButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => resetPassword(user),
                                              child: const Text(
                                                  'Cambiar contraseña')),
                                          if (user['admin_status'] != true) ...[
                                            TextButton(
                                                onPressed: busy
                                                    ? null
                                                    : () => run(() async {
                                                          await api.requestJson(
                                                              '/admin/users/${user['id']}/profile-type',
                                                              method: 'PUT',
                                                              body: {
                                                                'profile_type':
                                                                    user['profile_type'] ==
                                                                            'kids'
                                                                        ? 'standard'
                                                                        : 'kids'
                                                              });
                                                          return true;
                                                        }),
                                                child: Text(
                                                    user['profile_type'] ==
                                                            'kids'
                                                        ? 'Cambiar a normal'
                                                        : 'Perfil infantil')),
                                            TextButton(
                                                onPressed: busy
                                                    ? null
                                                    : () async {
                                                        final confirmed = await showDialog<
                                                                bool>(
                                                            context: context,
                                                            builder: (context) =>
                                                                AlertDialog(
                                                                    title: const Text(
                                                                        '¿Cerrar sus sesiones?'),
                                                                    content:
                                                                        const Text(
                                                                            'Tendrá que iniciar sesión de nuevo cuando se conecte al servidor. El acceso offline no se puede revocar a distancia.'),
                                                                    actions: [
                                                                      TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              context,
                                                                              false),
                                                                          child:
                                                                              const Text('Cancelar')),
                                                                      FilledButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              context,
                                                                              true),
                                                                          child:
                                                                              const Text('Cerrar sesiones'))
                                                                    ]));
                                                        if (confirmed == true) {
                                                          await run(() async {
                                                            await api.requestJson(
                                                                '/admin/users/${user['id']}/revoke-sessions',
                                                                body: {});
                                                            return true;
                                                          });
                                                        }
                                                      },
                                                child: const Text(
                                                    'Cerrar sesiones')),
                                            PopupMenuButton<int>(
                                                tooltip: 'Vigencia de acceso',
                                                onSelected: (days) => run(() =>
                                                    api.setExpirationDays(
                                                        user['id'],
                                                        days == 0
                                                            ? null
                                                            : days)),
                                                itemBuilder: (_) => const [
                                                      PopupMenuItem(
                                                          value: 7,
                                                          child: Text(
                                                              'Acceso por 7 días')),
                                                      PopupMenuItem(
                                                          value: 30,
                                                          child: Text(
                                                              'Acceso por 30 días')),
                                                      PopupMenuItem(
                                                          value: 0,
                                                          child: Text(
                                                              'Sin vencimiento'))
                                                    ],
                                                child: const Padding(
                                                    padding: EdgeInsets.all(12),
                                                    child: Text('Vigencia'))),
                                            TextButton(
                                                onPressed: busy
                                                    ? null
                                                    : () => run(() =>
                                                        api.toggleSuspension(
                                                            user['id'],
                                                            user['account_status'] ==
                                                                    'suspended'
                                                                ? 'activate'
                                                                : 'suspend')),
                                                child: Text(
                                                    user['account_status'] ==
                                                            'suspended'
                                                        ? 'Activar'
                                                        : 'Suspender')),
                                          ],
                                        ]),
                                      ])),
                                  ],
                                ]);
                          }))));
}
