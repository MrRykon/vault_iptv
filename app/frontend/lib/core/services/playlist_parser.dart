import 'dart:convert';
import 'package:crypto/crypto.dart';

List<Map<String, dynamic>> parsePlaylist(String source) {
  final channels = <Map<String, dynamic>>[];
  Map<String, String>? attrs;
  String? title;
  for (final raw in source.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('#EXTINF:')) {
      attrs = {
        for (final m in RegExp(r'([\w-]+)="([^"]*)"').allMatches(line))
          m[1]!: m[2]!
      };
      final comma = RegExp(r',(?=(?:[^"]*"[^"]*")*[^"]*$)').firstMatch(line);
      title = attrs['tvg-name'] ??
          (comma == null ? 'Canal' : line.substring(comma.start + 1));
    } else if (attrs != null && !line.startsWith('#') && line.isNotEmpty) {
      final uri = Uri.tryParse(line);
      if (uri != null && ['http', 'https'].contains(uri.scheme)) {
        final group = attrs['group-title'] ?? 'General';
        channels.add({
          'channel_id':
              sha256.convert(utf8.encode(line)).toString().substring(0, 24),
          'channel_name': title,
          'stream_url': line,
          'category': group,
          'logo_url': attrs['tvg-logo'],
          'is_kids_safe': RegExp(
                  r'kids|children|cartoon|animation|family|infantil',
                  caseSensitive: false)
              .hasMatch(group)
        });
      }
      attrs = null;
    }
  }
  return channels;
}
