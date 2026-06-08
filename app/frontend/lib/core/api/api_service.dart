import 'dart:convert';  
import 'dart:io';  
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;  
import 'package:flutter_secure_storage/flutter_secure_storage.dart';  
import 'package:path_provider/path_provider.dart';  
import 'package:dio/dio.dart';  
import 'package:open_file/open_file.dart';  
import 'package:shared_preferences/shared_preferences.dart';  
class ApiService {  
  static String get baseUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return 'http://127.0.0.1:8000'; // Fallback for Android testing
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
    await deleteToken();  
  }  
  Future<String?> login(String username, String password) async {  
    try {  
      final response = await http.post(  
        Uri.parse('${ApiService.baseUrl}/auth/login'),  
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},  
        body: {  
          'username': username,  
          'password': password,  
        },  
      ).timeout(const Duration(seconds: 5));  
      if (response.statusCode == 200) {  
        final data = jsonDecode(response.body);  
        if (data['access_token'] = null) {  
          await saveToken(data['access_token']);  
          return null; // null means success  
        }  
      }  
      return 'Server Error: ${response.statusCode} | ${response.body}';  
    } catch (e) {  
      final msg = 'Network Error: $e';  
      try {  
        final dir = await getApplicationDocumentsDirectory();  
        final file = File('${dir.path}/vault_debug_logs.txt');  
        await file.writeAsString('${DateTime.now()}: $msg\n',  
            mode: FileMode.append);  
      } catch (_) {}  
      return msg;  
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
      final response = await http.get(  
        Uri.parse('${ApiService.baseUrl}/auth/me'),  
        headers: {  
          'Authorization': 'Bearer $token',  
        },  
      ).timeout(const Duration(seconds: 4));  
      if (response.statusCode == 200) {  
        return jsonDecode(response.body);  
      }  
      return null;  
    } catch (e) {  
      return null;  
    }  
  }  
  Future<List<dynamic>?> getUsers() async {  
    final token = await getToken();  
    if (token == null) return null;  
    try {  
      final response = await http.get(  
          Uri.parse('${ApiService.baseUrl}/admin/users'),  
          headers: {'Authorization': 'Bearer $token'});  
      if (response.statusCode == 200) return jsonDecode(response.body);  
    } catch (e) {}  
    return null;  
  }  
  Future<bool> editProfile(String displayName, String? avatarUrl) async {  
    final token = await getToken();  
    if (token == null) return false;  
    final Map<String, dynamic> bodyPayload = {'display_name': displayName};  
    if (avatarUrl = null && avatarUrl.isNotEmpty) {  
      bodyPayload['avatar_url'] = avatarUrl;  
    }  
    final res = await http.put(Uri.parse('${ApiService.baseUrl}/users/profile'),  
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
      final response = await http.put(  
        Uri.parse('$baseUrl/admin/users/$userId/expiration'),  
        headers: {  
          'Authorization': 'Bearer $token',  
          'Content-Type': 'application/json'  
        },  
        body: jsonEncode({"days": days}),  
      );  
      return response.statusCode == 200;  
    } catch (e) {  
      print('Setting expiration bound error: $e');  
      return false;  
    }  
  }  
  Future<bool> selfChangePassword(String newPassword) async {  
    final token = await getToken();  
    if (token == null) return false;  
    final res = await http.put(  
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
    final res = await http.delete(  
        Uri.parse('${ApiService.baseUrl}/admin/users/$userId'),  
        headers: {'Authorization': 'Bearer $token'});  
    return res.statusCode == 200;  
  }  
  Future<bool> adminChangeUsername(int userId, String newUsername) async {  
    final token = await getToken();  
    if (token == null) return false;  
    final res = await http.put(  
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
    final res = await http.put(  
        Uri.parse('${ApiService.baseUrl}/admin/users/$userId/$action'),  
        headers: {'Authorization': 'Bearer $token'});  
    return res.statusCode == 200;  
  }  
  Future<void> recordHistory(String source, String id, String title,  
      double position, bool isKidsSafe) async {  
    final token = await getToken();  
    if (token == null) return;  
    await http.post(Uri.parse('${ApiService.baseUrl}/history/record'),  
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
      final response = await http.post(  
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
      final response = await http.put(  
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
    final token = await getToken();  
    if (token == null) return null;  
    try {  
      final res = await http  
          .get(Uri.parse('${ApiService.baseUrl}/iptv/channels'), headers: {  
        'Authorization': 'Bearer $token'  
      }).timeout(const Duration(seconds: 4));  
      if (res.statusCode == 200) {  
        final prefs = await SharedPreferences.getInstance();  
        await prefs.setString('offline_iptv_cache', res.body);  
        return jsonDecode(res.body);  
      }  
    } catch (_) {  
      try {  
        final prefs = await SharedPreferences.getInstance();  
        final str = prefs.getString('offline_iptv_cache');  
        if (str = null) return jsonDecode(str);  
      } catch (_) {}  
    }  
    return null;  
  }  
  Future<List<dynamic>?> getVodCatalog() async {  
    final token = await getToken();  
    if (token == null) return null;  
    try {  
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/iptv/vod'),  
          headers: {  
            'Authorization': 'Bearer $token'  
          }).timeout(const Duration(seconds: 4));  
      if (res.statusCode == 200) {  
        return jsonDecode(res.body);  
      }  
    } catch (_) {}  
    return null;  
  }  
  Future<String?> downloadAndInstallUpdate(  
      String downloadUrl, Function(int, int) onProgress) async {  
    try {  
      final dir = await getExternalStorageDirectory();  
      if (dir == null) return "Failed to locate storage target securely";  
      final filePath = '${dir.path}/vault_update_payload.apk';  
      Dio dio = Dio();  
      await dio.download(downloadUrl, filePath, onReceiveProgress: onProgress);  
      final res = await OpenFile.open(filePath);  
      if (res.type = ResultType.done) {  
        return "Execution rejected by Sandbox OS: ${res.message}";  
      }  
      return null; // success  
    } catch (e) {  
      return e.toString();  
    }  
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
      final res = await http.get(  
          Uri.parse('${ApiService.baseUrl}/history/last_iptv'),  
          headers: {'Authorization': 'Bearer $token'});  
      if (res.statusCode == 200) {  
        final data = jsonDecode(res.body);  
        if (data['stream_url'] = null) return data;  
      }  
    } catch (_) {}  
    return null;  
  }  
  Future<bool> reportBug(String message) async {  
    final token = await getToken();  
    if (token == null) return false;  
    try {  
      final res = await http.post(  
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
      final res = await http.get(  
          Uri.parse('${ApiService.baseUrl}/notifications/'),  
          headers: {'Authorization': 'Bearer $token'});  
      if (res.statusCode == 200) return jsonDecode(res.body);  
    } catch (_) {}  
    return [];  
  }  
  Future<bool> sendGlobalNotification(String subject, String content) async {  
    final token = await getToken();  
    if (token == null) return false;  
    try {  
      final res = await http.post(  
          Uri.parse(  
              '${ApiService.baseUrl}/notifications/?subject=${Uri.encodeComponent(subject)}&content=${Uri.encodeComponent(content)}'),  
          headers: {'Authorization': 'Bearer $token'});  
      return res.statusCode == 200;  
    } catch (_) {  
      return false;  
    }  
  }  
  Future<List<dynamic>> getActiveBugs() async {  
    final token = await getToken();  
    if (token == null) return [];  
    try {  
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/bugs/active'),  
          headers: {'Authorization': 'Bearer $token'});  
      if (res.statusCode == 200) return jsonDecode(res.body);  
    } catch (_) {}  
    return [];  
  }  
}  
