import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../../features/updates/updates_screen.dart';

bool isNewerRelease(Map<String, dynamic> release, String version, int build) {
  if (release['available'] != true || release['latest_build'] is! int) {
    return false;
  }
  final remote = (release['latest_version'] as String? ?? '')
      .split('.')
      .map(int.tryParse)
      .toList();
  final local = version.split('.').map(int.tryParse).toList();
  if (remote.length != 3 ||
      local.length != 3 ||
      remote.any((v) => v == null) ||
      local.any((v) => v == null)) {
    return false;
  }
  // Android cannot install a build number downgrade even when its display version is higher.
  if ((release['latest_build'] as int) <= build) return false;
  for (var i = 0; i < 3; i++) {
    if (remote[i]! < local[i]!) return false;
    if (remote[i]! > local[i]!) return true;
  }
  return true;
}

class OtaService {
  static bool showing = false;
  static Future<void> check(BuildContext context, {bool manual = false}) async {
    if (showing) return;
    showing = true;
    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        if (manual && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Las actualizaciones APK están disponibles en Android.')));
        }
        return;
      }
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/updates/check'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw StateError('Servidor no disponible');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final info = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();
      final id = '${data['latest_version']}+${data['latest_build']}';
      if (isNewerRelease(
              data, info.version, int.tryParse(info.buildNumber) ?? 0) &&
          (manual ||
              data['force_update'] == true ||
              prefs.getString('skipped_update_version') != id)) {
        if (context.mounted) {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => UpdatesScreen(updateData: data)));
        }
      } else if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No hay una actualización nueva publicada.')));
      }
    } catch (_) {
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No se pudo comprobar la actualización. Conecta con el servidor Vault.')));
      }
    } finally {
      showing = false;
    }
  }
}
