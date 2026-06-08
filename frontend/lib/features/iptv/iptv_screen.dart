import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import 'iptv_country_categories_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../player/player_screen.dart';

class IptvScreen extends StatefulWidget {
  const IptvScreen({Key? key}) : super(key: key);

  @override
  _IptvScreenState createState() => _IptvScreenState();
}

class _IptvScreenState extends State<IptvScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, Map<String, List<dynamic>>> _countryCategorizedChannels = {};
  
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<String> _favorites = [];
  bool _showFavoritesOnly = false;
  dynamic _randomChannel;

  final Map<String, Map<String, String>> countryMetadata = {
     'UNITED STATES': {'flag': '🇺🇸', 'welcome': 'Welcome to'},
     'USA': {'flag': '🇺🇸', 'welcome': 'Welcome to'},
     'UK': {'flag': '🇬🇧', 'welcome': 'Welcome to'},
     'CANADA': {'flag': '🇨🇦', 'welcome': 'Welcome to'},
     'COLOMBIA': {'flag': '🇨🇴', 'welcome': 'Bienvenido a'},
     'VENEZUELA': {'flag': '🇻🇪', 'welcome': 'Bienvenido a'},
     'SPAIN': {'flag': '🇪🇸', 'welcome': 'Bienvenido a'},
     'FRANCE': {'flag': '🇫🇷', 'welcome': 'Bienvenue en'},
     'GERMANY': {'flag': '🇩🇪', 'welcome': 'Willkommen in'},
     'ITALY': {'flag': '🇮🇹', 'welcome': 'Benvenuto in'},
     'JAPAN': {'flag': '🇯🇵', 'welcome': 'Yokoso'},
     'GLOBAL': {'flag': '🌍', 'welcome': 'Welcome to'},
     'UNCATEGORIZED': {'flag': '❓', 'welcome': 'Unsorted Channels'},
  };

  @override
  void initState() {
    super.initState();
    _fetchBroadcastArrays();
  }

  void _fetchBroadcastArrays() async {
    final rawData = await _apiService.getIptvChannels();
    if (rawData != null && mounted) {
       Map<String, Map<String, List<dynamic>>> grouped = {};
       for (var c in rawData) {
          String rawCat = (c['category'] ?? '').toString();
          List<String> parts = rawCat.split('|');
          String country = 'GLOBAL';
          String cat = 'UNCATEGORIZED';
          
          if (parts.length > 1) {
              country = parts[0].trim().toUpperCase();
              cat = parts[1].trim().toUpperCase();
          } else if (rawCat.isNotEmpty) {
              country = 'GLOBAL';
              cat = rawCat.trim().toUpperCase();
          } else {
              country = 'UNCATEGORIZED';
              cat = 'UNCATEGORIZED';
          }

          if (!grouped.containsKey(country)) grouped[country] = {};
          if (!grouped[country]!.containsKey(cat)) grouped[country]![cat] = [];
          grouped[country]![cat]!.add(c);
       }
       
       final prefs = await SharedPreferences.getInstance();
       final favs = prefs.getStringList('vault_favorites') ?? [];
       
       setState(() {
         _countryCategorizedChannels = grouped;
         _favorites = favs;
         if (rawData.isNotEmpty) {
           _randomChannel = rawData[math.Random().nextInt(rawData.length)];
         }
         _isLoading = false;
       });
    } else if (mounted) {
       setState(() { _isLoading = false; });
    }
  }

  void _toggleFavorite(String channelId) async {
      setState(() {
          if (_favorites.contains(channelId)) { _favorites.remove(channelId); }
          else { _favorites.add(channelId); }
      });
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('vault_favorites', _favorites);
  }

  List<dynamic> _getFlattenedSearchResults() {
      List<dynamic> flat = [];
      _countryCategorizedChannels.forEach((country, map) {
          map.forEach((cat, list) {
              for (var c in list) {
                  bool matchSearch = _searchQuery.isEmpty || c['channel_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                  bool matchFav = !_showFavoritesOnly || _favorites.contains(c['channel_id']);
                  if (matchSearch && matchFav) flat.add(c);
              }
          });
      });
      return flat;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('GLOBAL BROADCASTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.amber)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
             child: Row(
               children: [
                 Expanded(
                   child: TextField(
                     controller: _searchCtrl,
                     style: const TextStyle(color: Colors.white),
                     decoration: InputDecoration(
                        hintText: 'Search Global Networks...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.amber),
                        filled: true,
                        fillColor: const Color(0xFF1C1C1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0)
                     ),
                     onChanged: (val) {
                        setState(() { _searchQuery = val.trim(); });
                     },
                   )
                 ),
                 const SizedBox(width: 12),
                 GestureDetector(
                    onTap: () {
                       setState(() { _showFavoritesOnly = !_showFavoritesOnly; });
                    },
                    child: Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                          color: _showFavoritesOnly ? Colors.amber.withOpacity(0.2) : const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _showFavoritesOnly ? Colors.amber : Colors.transparent)
                       ),
                       child: Icon(_showFavoritesOnly ? Icons.star : Icons.star_border, color: _showFavoritesOnly ? Colors.amber : Colors.white54),
                    )
                 )
               ]
             )
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : _countryCategorizedChannels.isEmpty
                  ? const Center(child: Text('No broadcasting channels found', style: TextStyle(color: Colors.white54)))
                  : (_searchQuery.isNotEmpty || _showFavoritesOnly)
                      ? _buildFlatSearchResults()
                      : Column(
                          children: [
                            if (_randomChannel != null) _buildRandomChannelBanner(),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _countryCategorizedChannels.keys.length,
                                itemBuilder: (context, index) {
            String country = _countryCategorizedChannels.keys.elementAt(index);
            
            int validChannels = 0;
            _countryCategorizedChannels[country]!.forEach((cat, list) {
                 for (var c in list) {
                     validChannels++;
                 }
            });
            
            final meta = countryMetadata[country] ?? countryMetadata['GLOBAL']!;

            return GestureDetector(
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => IptvCountryCategoriesScreen(
                     countryName: country,
                     categories: _countryCategorizedChannels[country]!,
                     flagEmoji: meta['flag']!
                 )));
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                    leading: Text(meta['flag']!, style: const TextStyle(fontSize: 32)),
                    title: Text(country, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    subtitle: Text('Total Channels: $validChannels', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  ),
                )
              );
            },
          ),
                            ),
                          ],
                        )
          )
        ]
      )
    );
  }

  Widget _buildRandomChannelBanner() {
    return GestureDetector(
      onTap: () => importPlayer(_randomChannel),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.black87]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.casino, color: Colors.amber, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Featured Random Channel', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(_randomChannel['channel_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.amber, size: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatSearchResults() {
      final results = _getFlattenedSearchResults();
      if (results.isEmpty) return const Center(child: Text("No channels correctly match your boundaries.", style: TextStyle(color: Colors.white54)));

      return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: results.length,
          itemBuilder: (context, index) {
              final c = results[index];
              final channelId = c['channel_id']?.toString() ?? '';
              final isFav = _favorites.contains(channelId);
              return Container(
                 margin: const EdgeInsets.only(bottom: 12),
                 decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                 child: ListTile(
                   leading: CircleAvatar(backgroundColor: Colors.black, backgroundImage: (c['logo_url'] != null && c['logo_url'].toString().isNotEmpty) ? NetworkImage(c['logo_url']) : null, child: (c['logo_url'] == null || c['logo_url'].toString().isEmpty) ? const Icon(Icons.live_tv, color: Colors.blueAccent) : null),
                   title: Text(c['channel_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                   subtitle: Text('Stream Node Active', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                   trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       GestureDetector(onTap: () => _toggleFavorite(channelId), child: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.white24, size: 24)),
                       const SizedBox(width: 12),
                       const Icon(Icons.play_circle_fill, color: Colors.amber, size: 30),
                     ]
                   ),
                   onTap: () {
                       importPlayer(c);
                   }
               ));
          }
      );
  }

  void importPlayer(dynamic c) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(streamUrl: c['stream_url'], contentId: c['channel_id'] ?? c['channel_name'], contentTitle: c['channel_name'], source: 'iptv', isKidsSafe: c['is_kids_safe'] ?? false)));
  }
}
