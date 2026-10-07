import 'package:flutter/material.dart';
import '../../core/theme/vault_reveal.dart';
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
  String? version;
  late final data = Map<String, dynamic>.from(widget.initialData);
  final nameEditor = TextEditingController();
  bool saving = false;
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
  void dispose() {
    nameEditor.dispose();
    super.dispose();
  }

  Future<void> editName() async {
    nameEditor.text = data['display_name'] ?? data['custom_username'];
    final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: const Text('Editar nombre'),
                  content: TextField(
                      controller: nameEditor,
                      autofocus: true,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(labelText: 'Nombre visible'),
                      onChanged: (_) => update(() {})),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: nameEditor.text.trim().isEmpty
                            ? null
                            : () => Navigator.pop(
                                dialogContext, nameEditor.text.trim()),
                        child: const Text('Guardar'))
                  ],
                )));
    if (name == null || !mounted) return;
    setState(() => saving = true);
    try {
      final success = await ApiService().editProfile(name, null);
      if (!mounted) return;
      if (success) {
        await ApiService().getProfile();
        if (mounted) setState(() => data['display_name'] = name);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(success
                ? 'Nombre actualizado.'
                : 'No se pudo guardar el nombre.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo conectar con Vault.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        VaultReveal(
            child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF382B52), Color(0xFF18212D)])),
                child: const Column(children: [
                  CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF6C548E),
                      child: Icon(Icons.person_outline,
                          size: 40, color: Colors.white)),
                  SizedBox(height: 12),
                  Text('TU ESPACIO PERSONAL',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Color(0xFFDBC7FF))),
                ]))),
        const SizedBox(height: 20),
        Text(data['display_name'] ?? data['custom_username'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        Text('@${data['custom_username']}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
            valueListenable: ApiService.serverOnline,
            builder: (context, online, _) => Center(
                child: TextButton.icon(
                    onPressed: online && !saving ? editName : null,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(saving ? 'Guardando…' : 'Editar nombre')))),
        const SizedBox(height: 16),
        Card(
            child: Column(children: [
          ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(
                  data['admin_status'] == true ? 'Administrador' : 'Usuario'),
              subtitle: Text('Perfil: ${data['profile_type']}')),
          ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Vault · Películas, series y Live TV'),
              subtitle: Text(version == null
                  ? 'Consultando versión…'
                  : 'Versión $version')),
          ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Ajustes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const VaultSettingsScreen()))),
        ])),
        if (data['admin_status'] == true)
          ValueListenableBuilder<bool>(
              valueListenable: ApiService.serverOnline,
              builder: (context, online, _) => Card(
                    color: const Color(0xFF302A20),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CENTRO DE ADMINISTRACIÓN',
                                  style: TextStyle(
                                      color: Color(0xFFFFD58C),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                              Text(online
                                  ? 'Gestiona tu comunidad Vault'
                                  : 'Conecta el servidor para administrar'),
                              for (final item in [
                                (
                                  Icons.people_outline,
                                  'Usuarios y acceso',
                                  'Crear cuentas, perfiles infantiles y vigencia'
                                ),
                                (
                                  Icons.campaign_outlined,
                                  'Publicar avisos',
                                  'Comunícate con todos tus usuarios'
                                ),
                                (
                                  Icons.sync,
                                  'Sincronizar IPTV',
                                  'Actualizar las fuentes del servidor'
                                )
                              ].indexed)
                                ListTile(
                                    enabled: online,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(item.$2.$1,
                                        color: const Color(0xFFFFD58C)),
                                    title: Text(item.$2.$2),
                                    subtitle: Text(item.$2.$3),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: online
                                        ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    AdminSettingsScreen(
                                                        initialTab: item.$1)))
                                        : null),
                            ])),
                  )),
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
