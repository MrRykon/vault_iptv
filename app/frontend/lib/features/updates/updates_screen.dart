import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdatesScreen extends StatefulWidget {
  final Map<String, dynamic> updateData;

  const UpdatesScreen({Key? key, required this.updateData}) : super(key: key);

  @override
  _UpdatesScreenState createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'A new Vault update is available!';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'Validating OS Installation permissions safely...';
    });

    try {
      // Prompt explicitly the OS settings page natively!
      var status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
          status = await Permission.requestInstallPackages.request();
          if (!status.isGranted) {
              setState(() {
                  _statusMessage = 'INSTALLATION ABORTED: Explicit permission to automatically install packages is required dynamically by the Android OS.';
                  _isDownloading = false;
              });
              return;
          }
      }

      setState(() {
          _statusMessage = 'Downloading update dynamically...';
      });

      final dio = Dio();
      final targetUrl = widget.updateData['apk_download_url'];
      
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/Vault${widget.updateData['latest_version']}.apk';

      await dio.download(
        targetUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      setState(() {
        _statusMessage = 'Download complete! Launching installer...';
      });

      // Trigger the Android Native Package Installer Hook
      final result = await OpenFile.open(savePath);
      
      if (result.type != ResultType.done) {
        setState(() {
          _statusMessage = 'Failed to open installer: ${result.message}';
        });
      }
    } catch (e) {
      setState(() {
         _statusMessage = 'Download failed: $e';
         _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool forceUpdate = widget.updateData['force_update'] ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_alt, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              Text(
                "Version ${widget.updateData['latest_version']} Available",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              if (_isDownloading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 8),
                    Text("${(_progress * 100).toStringAsFixed(1)}%")
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _startDownload,
                  child: const Text('DOWNLOAD AND INSTALL'),
                ),
              if (!forceUpdate && !_isDownloading) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('skipped_update_version', widget.updateData['latest_version']);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('LATER', style: TextStyle(color: Colors.grey)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
