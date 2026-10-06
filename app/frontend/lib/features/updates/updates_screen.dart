import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_service.dart';

class UpdatesScreen extends StatefulWidget {
  final Map<String, dynamic> updateData;
  const UpdatesScreen({super.key, required this.updateData});
  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool downloading = false;
  double? progress;
  String status = 'Actualización lista para descargar.';
  final cancel = CancelToken();
  Future<void> install() async {
    setState(() {
      downloading = true;
      status = 'Descargando APK…';
    });
    File? file;
    try {
      final digest = widget.updateData['apk_sha256']?.toString() ?? '';
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
        throw StateError('Falta la firma de integridad');
      }
      final url = Uri.parse(widget.updateData['apk_download_url']);
      if (url.origin != Uri.parse(ApiService.baseUrl).origin) {
        throw StateError('Servidor de actualización incorrecto');
      }
      final permission = await Permission.requestInstallPackages.request();
      if (!permission.isGranted) {
        throw StateError(
            'Autoriza la instalación desde Vault en los ajustes de Android');
      }
      final dir = await getTemporaryDirectory();
      file = File('${dir.path}/vault-update.apk');
      await Dio().download(url.toString(), file.path,
          cancelToken: cancel, options: Options(followRedirects: false),
          onReceiveProgress: (received, total) {
        if (mounted) {
          setState(() => progress = total > 0 ? received / total : null);
        }
      });
      final actual = await sha256.bind(file.openRead()).first;
      if (actual.toString() != digest) {
        await file.delete();
        throw StateError(
            'El APK no coincide con su SHA-256. Descarga rechazada.');
      }
      final result = await OpenFile.open(file.path,
          type: 'application/vnd.android.package-archive');
      if (result.type != ResultType.done) {
        throw StateError('No se pudo abrir el instalador de Android');
      }
      if (mounted) {
        setState(() => status = 'Confirma la instalación en Android.');
      }
    } catch (_) {
      if (file != null && await file.exists()) await file.delete();
      if (mounted) {
        setState(() => status =
            'No se pudo instalar. Revisa el permiso de instalación, el servidor y la integridad del APK.');
      }
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  @override
  void dispose() {
    cancel.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !downloading && widget.updateData["force_update"] != true,
      child: Scaffold(
        appBar: AppBar(title: const Text('Actualizar Vault')),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.system_update, size: 72),
                  const SizedBox(height: 20),
                  Text(
                      'Vault ${widget.updateData['latest_version']} · build ${widget.updateData['latest_build']}',
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 16),
                  Text(widget.updateData['release_notes'] ?? ''),
                  const SizedBox(height: 16),
                  Text(status),
                  const SizedBox(height: 24),
                  if (downloading)
                    LinearProgressIndicator(value: progress)
                  else
                    FilledButton(
                        onPressed: install,
                        child: const Text('Descargar e instalar')),
                  if (!downloading && widget.updateData["force_update"] != true)
                    TextButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('skipped_update_version',
                              '${widget.updateData['latest_version']}+${widget.updateData['latest_build']}');
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Más tarde')),
                ]))),
      ));
}
