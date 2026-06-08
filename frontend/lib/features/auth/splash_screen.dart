import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api/api_service.dart';
import '../updates/updates_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkUpdatesAndNavigate();
      });
    });
  }

  Future<void> _checkUpdatesAndNavigate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/updates/check')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['latest_version'] != packageInfo.version) { // Bump Version Natively
          if (!mounted) return;
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => UpdatesScreen(updateData: data)));
          return;
        }
      }
    } catch (_) { }
    
    // OFFLINE PROTOCOL
    try {
        final token = await ApiService().getToken();
        final prefs = await SharedPreferences.getInstance();
        
        final lastActive = prefs.getInt('last_active_time') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final bool isExpired = lastActive > 0 && (now - lastActive) > 30 * 60 * 1000;
        
        if (token != null) {
            if (isExpired) {
                await ApiService().logout(); // Auto-lock
            } else {
                await prefs.setInt('last_active_time', now); // Refresh activity
                if (!mounted) return;
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
                return;
            }
        }
    } catch (_) {}
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Stylized dark background
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Image.asset(
                  'assets/images/dragon_logo.png',
                  width: 150,
                  height: 150,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
