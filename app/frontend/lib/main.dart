import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/splash_screen.dart';
import 'core/api/api_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: const [
        // Configuration / State providers will be added here
      ],
      child: const VaultApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class VaultApp extends StatefulWidget {
  const VaultApp({Key? key}) : super(key: key);

  @override
  _VaultAppState createState() => _VaultAppState();
}

class _VaultAppState extends State<VaultApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      await prefs.setInt('last_active_time', now);
    } else if (state == AppLifecycleState.resumed) {
      final lastActive = prefs.getInt('last_active_time') ?? 0;
      if (lastActive > 0 && (now - lastActive) > 30 * 60 * 1000) {
        // Locked! Clear token and push login
        await ApiService().logout();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        await prefs.setInt('last_active_time', now);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Optionally tie to a settings provider
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('ja', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
