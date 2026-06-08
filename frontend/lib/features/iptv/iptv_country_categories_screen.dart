import 'package:flutter/material.dart';
import 'iptv_channel_list_screen.dart';

class IptvCountryCategoriesScreen extends StatelessWidget {
  final String countryName;
  final String flagEmoji;
  final Map<String, List<dynamic>> categories;

  const IptvCountryCategoriesScreen({
     Key? key, 
     required this.countryName, 
     required this.flagEmoji, 
     required this.categories
  }) : super(key: key);

  IconData _getCategoryIcon(String cat) {
      cat = cat.toLowerCase();
      if (cat.contains('sport') || cat.contains('deporte') || cat.contains('nfl') || cat.contains('nba') || cat.contains('ufc')) return Icons.sports_soccer;
      if (cat.contains('kid') || cat.contains('infantil') || cat.contains('child') || cat.contains('family') || cat.contains('cartoon')) return Icons.child_care;
      if (cat.contains('movie') || cat.contains('cine') || cat.contains('pelicula') || cat.contains('cinema')) return Icons.movie;
      if (cat.contains('news') || cat.contains('noticia') || cat.contains('24/7')) return Icons.article;
      if (cat.contains('music') || cat.contains('audio') || cat.contains('radio')) return Icons.music_note;
      if (cat.contains('doc') || cat.contains('ciencia') || cat.contains('nature')) return Icons.biotech;
      return Icons.satellite_alt;
  }

  Color _getCategoryColor(String cat) {
      cat = cat.toLowerCase();
      if (cat.contains('sport') || cat.contains('deporte')) return Colors.greenAccent;
      if (cat.contains('kid') || cat.contains('infantil')) return Colors.purpleAccent;
      if (cat.contains('movie') || cat.contains('cine')) return Colors.redAccent;
      if (cat.contains('news') || cat.contains('noticia')) return Colors.blueAccent;
      return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final catKeys = categories.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
              Text(flagEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Flexible(child: Text(countryName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white), overflow: TextOverflow.ellipsis)),
           ]
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: catKeys.length,
          itemBuilder: (context, index) {
            String cat = catKeys[index];
            int count = categories[cat]!.length;
            IconData localIcon = _getCategoryIcon(cat);
            Color localColor = _getCategoryColor(cat);

            return GestureDetector(
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => IptvChannelListScreen(
                     categoryName: cat, 
                     channels: categories[cat]!,
                     fallbackIcon: localIcon,
                 )));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                       radius: 30,
                       backgroundColor: localColor.withOpacity(0.1),
                       child: Icon(localIcon, size: 32, color: localColor),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        cat.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$count CHANNELS', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
