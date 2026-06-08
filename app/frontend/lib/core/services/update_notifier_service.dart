import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateNotifierService {
  static const String _lastVersionKey = 'last_version_seen';

  // Define update notes per version here
  static const Map<String, String> _updateNotes = {
    '0.0.0': 'Welcome to the reset version!\n\n- Reset version back to v0.0.0 to track our progress moving forward.\n- Added an update notification system to keep you informed of new features and fixes.\n- NEW FEATURE: Added live availability status indicators for IPTV channels (green dot for available, red dot for unavailable).',
  };

  static Future<void> checkUpdateAndNotify(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? lastVersion = prefs.getString(_lastVersionKey);

      if (lastVersion != currentVersion) {
        if (lastVersion == null) {
          // Fresh install or wiped data. Don't show update notes.
          await prefs.setString(_lastVersionKey, currentVersion);
          return;
        }

        // Only show if there are actual notes for this exact version
        if (!_updateNotes.containsKey(currentVersion)) {
          // Still save the seen version so we don't keep checking
          await prefs.setString(_lastVersionKey, currentVersion);
          return;
        }

        String notes = _updateNotes[currentVersion]!;

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('App Updated to v$currentVersion'),
                content: SingleChildScrollView(
                  child: Text(notes),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Got it!'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }

        await prefs.setString(_lastVersionKey, currentVersion);
      }
    } catch (e) {
      debugPrint('Error checking update: $e');
    }
  }
}
