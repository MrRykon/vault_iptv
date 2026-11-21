import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/services/ota_service.dart';

class VaultSettingsScreen extends StatelessWidget {
  const VaultSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(children: [
        ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Servidor Vault'),
            subtitle: Text(ApiService.baseUrl)),
        ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Actualizaciones OTA'),
            subtitle: const Text(
                'Buscar un APK nuevo publicado por el administrador'),
            onTap: () => OtaService.check(context, manual: true)),
        const ListTile(
            leading: Icon(Icons.live_tv),
            title: Text('Listas IPTV'),
            subtitle: Text(
                'Se actualizan automáticamente al conectar con Vault. Sin servidor se usan las últimas listas guardadas.')),
      ]));
}
