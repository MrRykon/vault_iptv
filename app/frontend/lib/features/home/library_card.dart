import 'package:flutter/material.dart';

class LibraryCard extends StatelessWidget {
  final dynamic item;
  final int index;
  final String? posterUrl;
  final String? token;
  final bool saved;
  final bool enabled;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  const LibraryCard(
      {super.key,
      required this.item,
      required this.index,
      this.posterUrl,
      this.token,
      required this.saved,
      required this.enabled,
      required this.onOpen,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF5C4A80),
      const Color(0xFF355F67),
      const Color(0xFF765B49),
      const Color(0xFF4F567D)
    ];
    return Semantics(
        label:
            '${item['title']}, ${item['type'] == 'show' ? 'serie' : 'película'}',
        child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Stack(fit: StackFit.expand, children: [
                InkWell(
                    onTap: enabled ? onOpen : null,
                    child: Ink(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                              colors[index % colors.length],
                              const Color(0xFF181723)
                            ])),
                        child: posterUrl != null
                            ? Image.network(posterUrl!,
                                headers: {'Authorization': 'Bearer $token'},
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child:
                                        Icon(Icons.movie_outlined, size: 60)))
                            : Center(
                                child: Icon(
                                    item['type'] == 'show'
                                        ? Icons.video_library_outlined
                                        : Icons.movie_outlined,
                                    size: 56,
                                    color:
                                        Colors.white.withValues(alpha: .5))))),
                Positioned(
                    right: 5,
                    top: 5,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: const Color(0xCC171320),
                            borderRadius: BorderRadius.circular(30)),
                        child: IconButton(
                            tooltip: saved
                                ? 'Quitar de Mi lista'
                                : 'Agregar a Mi lista',
                            onPressed: onSave,
                            icon: Icon(
                                saved ? Icons.bookmark : Icons.bookmark_border,
                                color: saved
                                    ? const Color(0xFFD0BEFF)
                                    : Colors.white)))),
                if (item['mock'] == true)
                  Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                              color: const Color(0xCC171320),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('PRÓXIMAMENTE · PLEX',
                              style: TextStyle(
                                  fontSize: 9, color: Color(0xFFDDC9FF))))),
              ])),
              InkWell(
                  onTap: enabled ? onOpen : null,
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] ?? 'Plex',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 5),
                            Text(item['type'] == 'show' ? 'Serie' : 'Película',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11)),
                          ]))),
            ])));
  }
}
