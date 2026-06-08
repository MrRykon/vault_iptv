import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/api/api_service.dart';
import '../home/home_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/services/update_notifier_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateNotifierService.checkUpdateAndNotify(context);
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'V${packageInfo.version}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appVersion = 'V0.0.0';
        });
      }
    }
  }

  void _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    String? errorResponse = await _apiService.login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (errorResponse == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_active_time', DateTime.now().millisecondsSinceEpoch);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorResponse),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  void _handleRegistration() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    String? errorResponse = await _apiService.register(
      _usernameController.text,
      _passwordController.text,
    );

    errorResponse ??= await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

    setState(() {
      _isLoading = false;
    });

    if (errorResponse == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_active_time', DateTime.now().millisecondsSinceEpoch);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorResponse),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents the whole screen from shrinking, hiding the version text behind the keyboard
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 32.0, 
                  right: 32.0, 
                  top: 60.0,
                  bottom: 60.0 + MediaQuery.of(context).viewInsets.bottom, // Manually pad for keyboard
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Futuristic Logo Glow Placeholder
              Image.asset(
                 'assets/images/dragon_logo.png',
                 height: 120,
              ),
              const SizedBox(height: 16),
              const Text(
                "VAULT",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 60),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: loc.get('username'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: loc.get('password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : Text(
                      loc.get('login').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _handleRegistration,
                child: Text('Create Account', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                     // TODO: Open Language Chooser Modal
                  },
                  icon: const Icon(Icons.language),
                  label: Text(loc.get('select_language')),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () async {
                    try {
                      final dir = await getApplicationDocumentsDirectory();
                      final file = File('${dir.path}/vault_debug_logs.txt');
                      if (await file.exists()) {
                        final content = await file.readAsString();
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Local Crash Logs'),
                            content: SingleChildScrollView(child: Text(content)),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                          ),
                        );
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs found yet.')));
                      }
                    } catch (_) {}
                  },
                  child: const Text('View Raw Logs', style: TextStyle(color: Colors.red)),
                ),
              )
            ],
          ),
        ),
      ),
      Positioned(
        bottom: 16,
          right: 16,
          child: Text(
            _appVersion,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}
