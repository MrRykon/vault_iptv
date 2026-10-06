import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/api/api_service.dart';
import '../settings/admin_settings_screen.dart';
import '../settings/vault_settings_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const ProfileScreen({super.key, required this.initialData});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String version = '0.1.0';
  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => version = '${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Center(
            child: CircleAvatar(
                radius: 48, child: Icon(Icons.person_outline, size: 48))),
        const SizedBox(height: 20),
        Text(
            widget.initialData['display_name'] ??
                widget.initialData['custom_username'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        Text('@${widget.initialData['custom_username']}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 24),
        Card(
            child: Column(children: [
          ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(widget.initialData['admin_status'] == true
                  ? 'Administrador'
                  : 'Usuario'),
              subtitle: Text('Perfil: ${widget.initialData['profile_type']}')),
          ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Vault · Películas, series y Live TV'),
              subtitle: Text('Versión $version')),
          ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Ajustes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const VaultSettingsScreen()))),
        ])),
        if (widget.initialData['admin_status'] == true)
          ValueListenableBuilder<bool>(
              valueListenable: ApiService.serverOnline,
              builder: (context, online, _) => Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: FilledButton.icon(
                    onPressed: online
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminSettingsScreen()))
                        : null,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: Text(online
                        ? 'Administrar usuarios y notificaciones'
                        : 'Administración requiere servidor'),
                  ))),
        const SizedBox(height: 24),
        OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            onPressed: () async {
              await ApiService().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false);
              }
            }),
      ]));
}
