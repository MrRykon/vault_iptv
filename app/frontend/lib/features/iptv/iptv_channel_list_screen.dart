import 'package:flutter/material.dart';
import '../player/player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class IptvChannelListScreen extends StatefulWidget {
  final String categoryName;
  final List<dynamic> channels;
  final IconData? fallbackIcon;

  const IptvChannelListScreen({Key? key, required this.categoryName, required this.channels, this.fallbackIcon}) : super(key: key);

  @override
  _IptvChannelListScreenState createState() => _IptvChannelListScreenState();
}

class _IptvChannelListScreenState extends State<IptvChannelListScreen> {
  List<String> _favorites = [];
  final Map<String, bool?> _channelAvailability = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _checkAvailability();
  }

  void _checkAvailability() async {
    for (var c in widget.channels) {
      final String channelId = c['channel_id']?.toString() ?? '';
      final String url = c['stream_url'] ?? '';
      if (url.isNotEmpty && channelId.isNotEmpty) {
        _checkSingleChannel(channelId, url);
      }
    }
  }

  Future<void> _checkSingleChannel(String channelId, String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _channelAvailability[channelId] = response.statusCode >= 200 && response.statusCode < 400;
        });
      }
    } catch (_) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _channelAvailability[channelId] = response.statusCode >= 200 && response.statusCode < 400;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _channelAvailability[channelId] = false;
          });
        }
      }
    }
  }

  void _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
       setState(() {
          _favorites = prefs.getStringList('vault_favorites') ?? [];
       });
    }
  }

  void _toggleFavorite(String id) async {
    setState(() {
       if (_favorites.contains(id)) {
         _favorites.remove(id);
       } else {
         _favorites.add(id);
       }
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('vault_favorites', _favorites);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.categoryName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.amber)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: widget.channels.isEmpty 
        ? const Center(child: Text("No broadcast channels mapped here natively.", style: TextStyle(color: Colors.white54)))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: widget.channels.length,
            itemBuilder: (context, index) {
              final c = widget.channels[index];
              final channelId = c['channel_id']?.toString() ?? '';
              final isFav = _favorites.contains(channelId);
              
              return Container(
                 margin: const EdgeInsets.only(bottom: 12),
                 decoration: BoxDecoration(
                   color: const Color(0xFF151515),
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Colors.white10),
                   boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
                 ),
                 child: ListTile(
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   leading: CircleAvatar(
                     backgroundColor: Colors.black,
                     radius: 30,
                     backgroundImage: (c['logo_url'] != null && c['logo_url'].toString().isNotEmpty) ? NetworkImage(c['logo_url']) : null,
                     child: (c['logo_url'] == null || c['logo_url'].toString().isEmpty) ? Icon(widget.fallbackIcon ?? Icons.live_tv, color: Colors.blueAccent) : null,
                   ),
                   title: Row(
                     children: [
                       Flexible(
                         child: Text(
                           c['channel_name'] ?? 'Unknown Broadcast', 
                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                       const SizedBox(width: 8),
                       Container(
                         width: 10,
                         height: 10,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           color: _channelAvailability[channelId] == null 
                                  ? Colors.grey 
                                  : (_channelAvailability[channelId]! ? Colors.green : Colors.red),
                         ),
                       ),
                     ],
                   ),
                   subtitle: Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Row(
                       children: [
                         const Icon(Icons.stream, color: Colors.greenAccent, size: 14),
                         const SizedBox(width: 4),
                         Text('Live Sync Active', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                         if (c['is_kids_safe'] == true) ...[
                           const Spacer(),
                           const Icon(Icons.child_care, color: Colors.blueAccent, size: 16),
                         ]
                       ]
                     ),
                   ),
                   trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       GestureDetector(
                         onTap: () => _toggleFavorite(channelId),
                         child: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.white24, size: 28),
                       ),
                       const SizedBox(width: 12),
                       const Icon(Icons.play_circle_fill, color: Colors.amber, size: 36),
                     ]
                   ),
                   onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (_) => PlayerScreen(
                           streamUrl: c['stream_url'],
                           contentId: c['channel_id'] ?? c['channel_name'],
                           contentTitle: c['channel_name'],
                           source: 'iptv',
                           isKidsSafe: c['is_kids_safe'] ?? false,
                         )
                       )
                     );
                   },
                 )
               );
             }
          )
    );
  }
}
