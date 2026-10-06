import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_service.dart';
import '../player/player_screen.dart';

class XtreamScreen extends StatefulWidget {
  const XtreamScreen({super.key});
  @override
  State<XtreamScreen> createState() => _XtreamScreenState();
}

class _XtreamScreenState extends State<XtreamScreen> {
  final server = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final storage = const FlutterSecureStorage();
  List<dynamic> items = [];
  String section = 'live';
  String? error;
  bool loading = false;
  bool remember = true;
  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    final raw = await storage.read(key: 'xtream_${ApiService.cacheKey}');
    if (raw != null && mounted) {
      final saved = jsonDecode(raw);
      server.text = saved['server'];
      username.text = saved['username'];
      password.text = saved['password'];
    }
  }

  Map<String, dynamic> get credentials => {
        'server': server.text.trim(),
        'username': username.text.trim(),
        'password': password.text,
        'section': section
      };
  Future<void> load({int? seriesId}) async {
    if (!ApiService.serverOnline.value || loading) return;
    setState(() {
      loading = true;
      error = null;
      items = [];
    });
    try {
      final data = await ApiService().requestJson(
          seriesId == null ? '/xtream/catalog' : '/xtream/episodes',
          body: {...credentials, if (seriesId != null) 'series_id': seriesId});
      if (remember) {
        await storage.write(
            key: 'xtream_${ApiService.cacheKey}',
            value: jsonEncode(credentials));
      } else {
        await storage.delete(key: 'xtream_${ApiService.cacheKey}');
      }
      if (mounted) setState(() => items = data['items'] as List<dynamic>);
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'No se pudo abrir Xtream. Comprueba el servidor, las credenciales y tu proveedor.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    server.dispose();
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
      valueListenable: ApiService.serverOnline,
      builder: (context, online, _) {
        if (!online) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'Xtream requiere el servidor Vault conectado. Puedes seguir usando Live TV.')));
        }
        return ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Xtream Codes',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const Text(
              'Tu proveedor tiene su propio catálogo, separado de Plex y Live TV.'),
          const SizedBox(height: 16),
          TextField(
              controller: server,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'Servidor del proveedor',
                  hintText: 'https://proveedor:puerto')),
          const SizedBox(height: 12),
          TextField(
              controller: username,
              decoration: const InputDecoration(labelText: 'Usuario Xtream')),
          const SizedBox(height: 12),
          TextField(
              controller: password,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Contraseña Xtream')),
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: remember,
              onChanged: (v) => setState(() => remember = v!),
              title: const Text('Guardar en este dispositivo')),
          DropdownButton<String>(
              value: section,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'live', child: Text('TV en vivo')),
                DropdownMenuItem(value: 'vod', child: Text('Películas')),
                DropdownMenuItem(value: 'series', child: Text('Series'))
              ],
              onChanged: loading
                  ? null
                  : (v) {
                      setState(() {
                        section = v!;
                        items = [];
                      });
                    }),
          ElevatedButton.icon(
              onPressed: loading ? null : () => load(),
              icon: const Icon(Icons.link),
              label: const Text('Conectar / cargar catálogo')),
          TextButton(
              onPressed: () async {
                await storage.delete(key: 'xtream_${ApiService.cacheKey}');
                password.clear();
                if (mounted) setState(() => items = []);
              },
              child: const Text('Olvidar credenciales')),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.orangeAccent)),
          for (final item in items)
            ListTile(
                leading: Icon(item['type'] == 'series'
                    ? Icons.video_library
                    : Icons.play_circle_outline),
                title: Text(item['title']),
                onTap: () {
                  if (!ApiService.serverOnline.value) return;
                  if (item['type'] == 'series') {
                    load(seriesId: int.parse(item['id']));
                    return;
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                              streamUrl: item['stream_url'],
                              contentId: item['id'],
                              contentTitle: item['title'],
                              source: 'xtream',
                              isKidsSafe: false)));
                }),
        ]);
      });
}
