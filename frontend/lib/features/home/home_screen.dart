import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api/api_service.dart';
import '../updates/updates_screen.dart';
import '../profile/profile_screen.dart';
import '../iptv/iptv_screen.dart';
import '../player/player_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:package_info_plus/package_info_plus.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isAdmin = false;
  bool _isOfflineMode = false;
  String _avatarUrl = '';
  Map<String, dynamic>? _lastIptv;
  List<dynamic> _vodMovies = [];
  List<dynamic> _activeNotifications = [];
  VideoPlayerController? _previewController;
  
  @override
  void initState() {
    super.initState();
    _fetchProfileStatus();
    _checkForUpdatesSilent();
  }
  
  Future<void> _fetchProfileStatus() async {
    final data = await _apiService.getProfile();
    if (data != null && mounted) {
      setState(() {
         _isAdmin = data['admin_status'] == true;
         _avatarUrl = data['avatar_url'] ?? '';
      });
    } else if (mounted) {
       setState(() { _isOfflineMode = true; });
    }
    
    final iptvData = await _apiService.fetchLastWatchedIptv();
    if (iptvData != null && mounted) {
       setState(() { _lastIptv = iptvData; });
       _initPreview(iptvData['stream_url']);
    }
    
    final vodData = await _apiService.getVodCatalog();
    if (vodData != null && mounted) {
        setState(() { _vodMovies = vodData; });
    }
    
    final notes = await _apiService.getGlobalNotifications();
    if (notes.isNotEmpty && mounted) {
        setState(() { _activeNotifications = notes; });
    }
  }

  void _initPreview(String url) async {
     if (_previewController != null) await _previewController!.dispose();
     try {
         _previewController = VideoPlayerController.networkUrl(Uri.parse(url));
         await _previewController!.initialize();
         await _previewController!.setVolume(0.0);
         await _previewController!.play();
         await _previewController!.setLooping(true);
         if (mounted) setState(() {});
     } catch (_) {}
  }

  @override
  void dispose() {
     _previewController?.dispose();
     super.dispose();
  }

  void _checkForUpdatesSilent() async {
      try {
          final packageInfo = await PackageInfo.fromPlatform();
          final res = await http.get(Uri.parse('${ApiService.baseUrl}/updates/check')).timeout(const Duration(seconds: 5));
          if(res.statusCode == 200) {
              final data = jsonDecode(res.body);
              if (data['latest_version'] != packageInfo.version && mounted) {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF151515),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
                          title: const Row(children: [Icon(Icons.system_update, color: Colors.amber), SizedBox(width: 8), Text('Vault Update', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))]),
                          content: Text("Vault ${data['latest_version']} has been pushed out natively to the server. Do you want to invoke the Android OS Auto-Installer right now?", style: const TextStyle(color: Colors.white)),
                          actions: [
                              TextButton(child: const Text('LATER', style: TextStyle(color: Colors.grey)), onPressed: () => Navigator.pop(context)),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  child: const Text('INSTALL OVER-THE-AIR', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => UpdatesScreen(updateData: data)));
                                  }
                              )
                          ]
                      )
                  );
              }
          }
      } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('VAULT', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () async {
                final Map<String, dynamic>? currentProfile = await _apiService.getProfile();
                if (currentProfile != null && mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(initialData: currentProfile))).then((_) {
                      _fetchProfileStatus();
                  });
                }
              },
              child: CircleAvatar(
                backgroundColor: const Color(0xFF2C2C2E),
                backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                child: _avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white38) : null,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              if (_isOfflineMode)
                 Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent)),
                    child: const Row(
                       children: [
                          Icon(Icons.warning_amber, color: Colors.orangeAccent),
                          SizedBox(width: 12),
                          Expanded(child: Text("⚠️ OFFLINE MODE (LIVE TV CACHE ACTIVE)\nVault PC Tracker is Offline. Profiles & VOD disabled natively.", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
                       ]
                    )
                 ),

              // Featured Hero Banner & Last Watched IPTV
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                         onTap: () {
                             if (_vodMovies.isNotEmpty) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(
                                   streamUrl: _vodMovies[0]['stream_url'],
                                   contentId: _vodMovies[0]['id'],
                                   contentTitle: _vodMovies[0]['title'],
                                   source: 'vod',
                                   isKidsSafe: false,
                                )));
                             }
                         },
                         child: Container(
                           height: 180,
                           decoration: BoxDecoration(
                             borderRadius: BorderRadius.circular(16),
                             image: _vodMovies.isNotEmpty ? DecorationImage(image: NetworkImage(_vodMovies[0]['poster_url']), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken)) : null,
                             gradient: _vodMovies.isEmpty ? const LinearGradient(colors: [Colors.deepPurple, Colors.indigo]) : null,
                             boxShadow: [
                               BoxShadow(
                                 color: Colors.deepPurple.withOpacity(0.4),
                                 blurRadius: 15,
                                 offset: const Offset(0, 5),
                               )
                             ]
                           ),
                           child: Center(
                             child: Text(_vodMovies.isNotEmpty ? '▶ VIP PREMIERE' : 'Featured Movie', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, backgroundColor: Colors.black45)),
                           )
                         )
                      )
                    ),
                    if (_lastIptv != null && _previewController != null && _previewController!.value.isInitialized) ...[
                       const SizedBox(width: 12),
                       Expanded(
                          flex: 2,
                          child: GestureDetector(
                             onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(
                                   streamUrl: _lastIptv!['stream_url'],
                                   contentId: _lastIptv!['channel_id'],
                                   contentTitle: _lastIptv!['channel_name'],
                                   source: 'iptv',
                                   isKidsSafe: false,
                                )));
                             },
                             child: Container(
                                height: 180,
                                decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(16),
                                   border: Border.all(color: Colors.white12, width: 2),
                                   boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0,4))]
                                ),
                                child: ClipRRect(
                                   borderRadius: BorderRadius.circular(14),
                                   child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                         FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                               width: _previewController!.value.size.width,
                                               height: _previewController!.value.size.height,
                                               child: VideoPlayer(_previewController!),
                                            )
                                         ),
                                         Positioned(
                                            bottom: 0, left: 0, right: 0,
                                            child: Container(
                                               padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                               decoration: BoxDecoration(
                                                  gradient: LinearGradient(colors: [Colors.black.withOpacity(0.9), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                                               ),
                                               child: Text(_lastIptv!['channel_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            )
                                         )
                                      ]
                                   )
                                )
                             )
                          )
                       )
                    ]
                  ]
                )
              ),
              if (!_isOfflineMode) ...[
                 if (_activeNotifications.isNotEmpty) ...[
                     const SizedBox(height: 10),
                     const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('System Notices', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold))),
                     ..._activeNotifications.map((n) => Container(
                         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0,5))]),
                         child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                Row(children: [const Icon(Icons.campaign, color: Colors.cyanAccent), const SizedBox(width: 8), Expanded(child: Text(n['subject'] ?? 'Update', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))]),
                                const SizedBox(height: 8),
                                Text(n['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                             ]
                         )
                     )).toList()
                 ],

                 // Vault Cinematic VOD
                 const SizedBox(height: 10),
                 const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('Vault Cinematic Library', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold))),
                 SizedBox(
                   height: 180,
                   child: ListView.builder(
                     scrollDirection: Axis.horizontal,
                     itemCount: _vodMovies.length,
                     itemBuilder: (context, index) {
                       final vod = _vodMovies[index];
                       return GestureDetector(
                          onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(
                                  streamUrl: vod['stream_url'],
                                  contentId: vod['id'],
                                  contentTitle: vod['title'],
                                  source: 'vod',
                                  isKidsSafe: false,
                              )));
                          },
                          child: Container(
                             width: 120,
                             margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                             decoration: BoxDecoration(
                               color: const Color(0xFF1C1C1E),
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: Colors.white10),
                               image: DecorationImage(image: NetworkImage(vod['poster_url']), fit: BoxFit.cover)
                             ),
                             child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 40)),
                          )
                       );
                     }
                   )
                 ),
              ],
             const SizedBox(height: 30),
          ],
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: const Color(0xFF111111),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search VOD'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live TV'),
        ],
        onTap: (index) {
           if (index == 1) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const IptvScreen()));
           }
        },
      ),
    );
  }
}
