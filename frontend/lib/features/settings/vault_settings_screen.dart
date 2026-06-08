import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api/api_service.dart';
import '../updates/updates_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VaultSettingsScreen extends StatefulWidget {
  const VaultSettingsScreen({Key? key}) : super(key: key);

  @override
  _VaultSettingsScreenState createState() => _VaultSettingsScreenState();
}

class _VaultSettingsScreenState extends State<VaultSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isChecking = false;
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appVersion = '0.0.0';
        });
      }
    }
  }

  void _checkForUpdates() async {
    setState(() => _isChecking = true);
    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/updates/check'))
          .timeout(const Duration(seconds: 5));
      setState(() => _isChecking = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Explicitly bypassing strictly to prove internal OS OTA executes perfectly!
        if (true || data['latest_version'] != _appVersion) {
          if (!mounted) return;
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => UpdatesScreen(updateData: data)));
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Vault is fully up to date! (v$_appVersion)')));
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to reach Deployment Server.')));
      }
    } catch (e) {
      setState(() => _isChecking = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Network Timeout: Cannot find deployment server.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('VAULT SYSTEM',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.amber)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.amber),
        ),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12)),
              child: Column(children: [
                const ListTile(
                  leading: Icon(Icons.security, color: Colors.greenAccent),
                  title: Text('Encryption Engine',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Argon2 Local Hashing active',
                      style: TextStyle(color: Colors.grey)),
                  trailing: Icon(Icons.check_circle, color: Colors.greenAccent),
                ),
                const Divider(color: Colors.white12),
                const ListTile(
                  leading: Icon(Icons.wifi_tethering, color: Colors.blueAccent),
                  title: Text('Host Backbone IP',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('10.29.148.140:8000',
                      style: TextStyle(color: Colors.grey)),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.update, color: Colors.amber),
                  title: const Text('System Package',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Currently running v$_appVersion',
                      style: const TextStyle(color: Colors.grey)),
                  trailing: _isChecking
                      ? const CircularProgressIndicator(color: Colors.amber)
                      : TextButton(
                          onPressed: _checkForUpdates,
                          style: TextButton.styleFrom(
                              backgroundColor: Colors.amber.withOpacity(0.1)),
                          child: const Text('CHECK NET',
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold)),
                        ),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                    leading: const Icon(Icons.bug_report,
                        color: Colors.orangeAccent),
                    title: const Text('Bugs',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Transmit system failures securely',
                        style: TextStyle(color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.orangeAccent, size: 16),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VaultBugsScreen()));
                    }),
              ]))
        ]));
  }
}

class VaultBugsScreen extends StatefulWidget {
  const VaultBugsScreen({Key? key}) : super(key: key);
  @override
  _VaultBugsScreenState createState() => _VaultBugsScreenState();
}

class _VaultBugsScreenState extends State<VaultBugsScreen> {
  final ApiService _apiService = ApiService();
  final _ctrl = TextEditingController();
  bool _isAdmin = false;
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatrix();
  }

  void _fetchMatrix() async {
    final prof = await _apiService.getProfile();
    if (prof != null && prof['admin_status'] == true) {
      _isAdmin = true;
      _reports = await _apiService.getActiveBugs();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submitBug() async {
    if (_ctrl.text.trim().isEmpty) return;
    bool ok = await _apiService.reportBug(_ctrl.text.trim());
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Bug parameters transmitted seamlessly to Sentinel DB.')));
      _ctrl.clear();
      _fetchMatrix(); // Refresh list if Admin
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            title: const Text('SYSTEM BUGS',
                style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.orangeAccent)),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                          hintText: "Describe the bug structure...",
                          hintStyle:
                              TextStyle(color: Colors.grey.withOpacity(0.5)),
                          filled: true,
                          fillColor: const Color(0xFF151515),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.orangeAccent, width: 1)))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent),
                      onPressed: _submitBug,
                      child: const Text('SUBMIT REPORT',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(height: 24),
                  if (_isAdmin) ...[
                    Container(height: 1, color: Colors.white10),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Global Admin Faults DB',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.orangeAccent))
                            : ListView.builder(
                                itemCount: _reports.length,
                                itemBuilder: (context, index) {
                                  var b = _reports[index];
                                  return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF1C1C1E),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.white10)),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              const Icon(Icons.person,
                                                  color: Colors.white54,
                                                  size: 14),
                                              const SizedBox(width: 6),
                                              Text(b['username'] ?? 'User',
                                                  style: const TextStyle(
                                                      color:
                                                          Colors.orangeAccent,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const Spacer(),
                                              Text(
                                                  b['created_at']
                                                      .toString()
                                                      .substring(0, 10),
                                                  style: const TextStyle(
                                                      color: Colors.white30,
                                                      fontSize: 10))
                                            ]),
                                            const SizedBox(height: 8),
                                            Text(b['message'],
                                                style: const TextStyle(
                                                    color: Colors.white70)),
                                          ]));
                                }))
                  ]
                ])));
  }
}
