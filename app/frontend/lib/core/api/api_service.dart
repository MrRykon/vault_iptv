import 'dart:async';
import 'package:flutter/services.dart';
import '../services/offline_account.dart';
import '../services/playlist_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static http.Client transport = http.Client();
  static String _serverUrl = const String.fromEnvironment('VAULT_SERVER_URL',
      defaultValue: 'http://localhost:8000');
  static final serverOnline = ValueNotifier<bool>(false);
  static Map<String, dynamic>? _sessionProfile;
  static String? _sessionUser;
  static bool sessionRejected = false;
  static String get baseUrl => kIsWeb ? Uri.base.origin : _serverUrl;
  static String get cacheKey =>
      'iptv_${OfflineAccount.key(baseUrl, _sessionUser ?? '')}';

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('vault_server_url') ?? _serverUrl;
  }

  static Future<void> setServerUrl(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException(
          'Usa http://direccion:8000 o una dirección HTTPS');
    }
    _serverUrl = value.trim().replaceFirst(RegExp(r'/$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vault_server_url', _serverUrl);
    _sessionProfile = null;
    _sessionUser = null;
    await const FlutterSecureStorage().delete(key: 'jwt');
    serverOnline.value = false;
  }

  Future<bool> checkServer() async {
    try {
      final response = await transport
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      serverOnline.value = response.statusCode == 200 &&
          jsonDecode(response.body)['service'] == 'vault';
    } catch (_) {
      serverOnline.value = false;
    }
    return serverOnline.value;
  }

  final _storage = const FlutterSecureStorage();
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt');
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null && serverOnline.value) {
      try {
        await transport.post(Uri.parse('$baseUrl/auth/logout'), headers: {
          'Authorization': 'Bearer $token'
        }).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    await deleteToken();
    _sessionProfile = null;
    _sessionUser = null;
    sessionRejected = false;
  }

  Future<String?> _offlineLogin(String username, String password) async {
    final record = await OfflineAccount.verify(baseUrl, username, password);
    if (record == null) {
      return 'Sin servidor: credenciales incorrectas o cuenta no validada antes en este dispositivo. El primer acceso requiere conexión.';
    }
    _sessionProfile = Map<String, dynamic>.from(record['profile']);
    _sessionUser = username;
    await saveToken(record['token'] as String);
    return null;
  }

  Future<String?> login(String username, String password) async {
    username = username.trim();
    sessionRejected = false;
    if (!await checkServer()) return _offlineLogin(username, password);
    try {
      final response = await transport.post(Uri.parse('$baseUrl/auth/login'),
          body: {
            'username': username,
            'password': password
          }).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        await OfflineAccount.forget(baseUrl, username);
        return 'Inicio de sesión rechazado. Comprueba tus credenciales y el estado de tu cuenta.';
      }
      final token = jsonDecode(response.body)['access_token'] as String;
      final profileResponse = await transport.get(Uri.parse('$baseUrl/auth/me'),
          headers: {
            'Authorization': 'Bearer $token'
          }).timeout(const Duration(seconds: 5));
      if (profileResponse.statusCode != 200) {
        return 'No se pudo validar el perfil.';
      }
      final profile = jsonDecode(profileResponse.body) as Map<String, dynamic>;
      await OfflineAccount.remember(
          baseUrl, username, password, profile, token);
      await saveToken(token);
      _sessionProfile = profile;
      _sessionUser = username;
      return null;
    } on SocketException {
      serverOnline.value = false;
      return _offlineLogin(username, password);
    } on http.ClientException {
      serverOnline.value = false;
      return _offlineLogin(username, password);
    } on TimeoutException {
      serverOnline.value = false;
      return _offlineLogin(username, password);
    }
  }

  Future<String?> register(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'custom_username': username,
              'password': password,
              'account_status': 'active',
              'profile_type': 'standard',
              'display_name': username,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return null; // success
      }
      return 'Registration Error: ${response.body}';
    } catch (e) {
      return 'Network Error: $e';
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await transport.get(Uri.parse('$baseUrl/auth/me'),
          headers: {
            'Authorization': 'Bearer $token'
          }).timeout(const Duration(seconds: 4));
      serverOnline.value = true;
      if (response.statusCode == 200) {
        _sessionProfile = jsonDecode(response.body) as Map<String, dynamic>;
        if (_sessionUser != null) {
          await OfflineAccount.refreshProfile(
              baseUrl, _sessionUser!, _sessionProfile!);
        }
        return _sessionProfile;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        sessionRejected = true;
        if (_sessionUser != null) {
          await OfflineAccount.forget(baseUrl, _sessionUser!);
        }
        _sessionProfile = null;
        await deleteToken();
      }
      return null;
    } catch (_) {
      serverOnline.value = false;
      return _sessionProfile;
    }
  }

  Future<dynamic> requestJson(String path, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    final response = await (body == null
            ? transport.get(Uri.parse('$baseUrl$path'), headers: headers)
            : transport.post(Uri.parse('$baseUrl$path'),
                headers: headers, body: jsonEncode(body)))
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      String message =
          'El servicio no está disponible (${response.statusCode}).';
      try {
        message = jsonDecode(response.body)['detail'].toString();
      } catch (_) {}
      throw StateError(message);
    }
    return jsonDecode(response.body);
  }

  Future<List<dynamic>?> getUsers() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await transport
          .get(Uri.parse('${ApiService.baseUrl}/admin/users'), headers: {
        'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {/* Report failure to the caller. */}
    return null;
  }

  Future<bool> editProfile(String displayName, String? avatarUrl) async {
    final token = await getToken();
    if (token == null) return false;
    final Map<String, dynamic> bodyPayload = {'display_name': displayName};
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      bodyPayload['avatar_url'] = avatarUrl;
    }
    final res = await transport.put(
        Uri.parse('${ApiService.baseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(bodyPayload));
    return res.statusCode == 200;
  }

  Future<bool> setExpirationDays(int userId, int? days) async {
    try {
      final token = await getToken();
      if (token == null) return false;
      final response = await transport.put(
        Uri.parse('$baseUrl/admin/users/$userId/expiration'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({"days": days}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Could not update account expiration.');
      return false;
    }
  }

  Future<bool> selfChangePassword(String newPassword) async {
    final token = await getToken();
    if (token == null) return false;
    final res = await transport.put(
        Uri.parse('${ApiService.baseUrl}/users/profile/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'password': newPassword}));
    return res.statusCode == 200;
  }

  Future<bool> deleteUser(int userId) async {
    final token = await getToken();
    if (token == null) return false;
    final res = await transport.delete(
        Uri.parse('${ApiService.baseUrl}/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token'
        }).timeout(const Duration(seconds: 8));
    return res.statusCode == 200;
  }

  Future<bool> adminChangeUsername(int userId, String newUsername) async {
    final token = await getToken();
    if (token == null) return false;
    final res = await transport.put(
        Uri.parse('${ApiService.baseUrl}/admin/users/$userId/username'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'custom_username': newUsername}));
    return res.statusCode == 200;
  }

  Future<bool> toggleSuspension(int userId, String action) async {
    final token = await getToken();
    if (token == null) return false;
    final res = await transport.put(
        Uri.parse('${ApiService.baseUrl}/admin/users/$userId/$action'),
        headers: {
          'Authorization': 'Bearer $token'
        }).timeout(const Duration(seconds: 8));
    return res.statusCode == 200;
  }

  Future<void> recordHistory(String source, String id, String title,
      double position, bool isKidsSafe) async {
    final token = await getToken();
    if (token == null) return;
    await transport.post(Uri.parse('${ApiService.baseUrl}/history/record'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'content_source': source,
          'content_id': id,
          'content_title': title,
          'position_seconds': position,
          'is_kids_safe': isKidsSafe
        }));
  }

  Future<bool> createUser(
      String username, String password, String profileType) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await transport.post(
        Uri.parse('${ApiService.baseUrl}/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'custom_username': username,
          'password': password,
          'account_status': 'active',
          'profile_type': profileType,
          'display_name': username,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetPassword(int userId, String newPassword) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await transport.put(
        Uri.parse('${ApiService.baseUrl}/admin/users/$userId/reset-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'password': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>?> getIptvChannels() async {
    if (sessionRejected || _sessionProfile == null) return null;
    final prefs = await SharedPreferences.getInstance();
    if (serverOnline.value) {
      try {
        final data = await requestJson('/iptv/channels') as List<dynamic>;
        await prefs.setString(cacheKey, jsonEncode(data));
        return data;
      } catch (_) {}
    }
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final data = jsonDecode(cached) as List<dynamic>;
      return _sessionProfile?['profile_type'] == 'kids'
          ? data.where((c) => c['is_kids_safe'] == true).toList()
          : data;
    }
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final channels = <Map<String, dynamic>>[];
    for (final path in manifest.listAssets().where((p) =>
        p.startsWith('assets/playlists/') &&
        (p.endsWith('.m3u') || p.endsWith('.m3u8')))) {
      channels.addAll(parsePlaylist(await rootBundle.loadString(path)));
    }
    return _sessionProfile?['profile_type'] == 'kids'
        ? channels.where((c) => c['is_kids_safe'] == true).toList()
        : channels;
  }

  Future<List<dynamic>?> getVodCatalog() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final res = await transport
          .get(Uri.parse('${ApiService.baseUrl}/iptv/vod'), headers: {
        'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  Future<String?> uploadAvatar(File imageFile) async {
    final token = await getToken();
    if (token == null) return "Authentication Failure";
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('${ApiService.baseUrl}/users/profile/avatar'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));
      var res = await request.send();
      if (res.statusCode == 200) return null; // success
      return "Upload failed: ${res.statusCode}";
    } catch (e) {
      return "Network Error: $e";
    }
  }

  Future<Map<String, dynamic>?> fetchLastWatchedIptv() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final res = await transport
          .get(Uri.parse('${ApiService.baseUrl}/history/last_iptv'), headers: {
        'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['stream_url'] != null) return data;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> reportBug(String message) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final res = await transport.post(
          Uri.parse('${ApiService.baseUrl}/bugs/report'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'message': message}));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getGlobalNotifications() async {
    final token = await getToken();
    if (token == null) return [];
    try {
      final res = await transport
          .get(Uri.parse('${ApiService.baseUrl}/notifications/'), headers: {
        'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  Future<bool> sendGlobalNotification(String subject, String content) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final res = await transport.post(
          Uri.parse(
              '${ApiService.baseUrl}/notifications/?subject=${Uri.encodeComponent(subject)}&content=${Uri.encodeComponent(content)}'),
          headers: {
            'Authorization': 'Bearer $token'
          }).timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getActiveBugs() async {
    final token = await getToken();
    if (token == null) return [];
    try {
      final res = await transport
          .get(Uri.parse('${ApiService.baseUrl}/bugs/active'), headers: {
        'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }
}
