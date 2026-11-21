import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/api/api_service.dart';

class PlayerScreen extends StatefulWidget {
  final String streamUrl;
  final String contentId;
  final String contentTitle;
  final String source;
  final bool isKidsSafe;
  final Map<String, String> headers;
  const PlayerScreen(
      {super.key,
      required this.streamUrl,
      required this.contentId,
      required this.contentTitle,
      required this.source,
      required this.isKidsSafe,
      this.headers = const {}});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? video;
  ChewieController? controls;
  Timer? history;
  String? error;
  @override
  void initState() {
    super.initState();
    ApiService.serverOnline.addListener(connectionChanged);
    initialize();
  }

  void connectionChanged() {
    if (widget.source != 'iptv' && !ApiService.serverOnline.value) {
      video?.pause();
      if (mounted) {
        setState(() =>
            error = 'El servidor se desconectó. Puedes seguir usando Live TV.');
      }
    }
  }

  Future<void> initialize() async {
    try {
      if (widget.source != 'iptv' && !ApiService.serverOnline.value) {
        throw StateError('Servidor desconectado');
      }
      video = VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl),
          httpHeaders: widget.headers);
      await video!.initialize().timeout(const Duration(seconds: 30));
      if (!mounted || error != null) return;
      controls = ChewieController(
          videoPlayerController: video!, autoPlay: true, looping: false);
      setState(() {});
      history = Timer.periodic(const Duration(seconds: 15), (_) async {
        if (!ApiService.serverOnline.value || video?.value.isPlaying != true) {
          return;
        }
        try {
          await ApiService().recordHistory(
              widget.source,
              widget.contentId,
              widget.contentTitle,
              video!.value.position.inSeconds.toDouble(),
              widget.isKidsSafe);
        } catch (_) {/* History must not interrupt playback. */}
      });
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'No se pudo reproducir. Comprueba tu conexión, la fuente y los formatos compatibles.');
      }
    }
  }

  @override
  void dispose() {
    ApiService.serverOnline.removeListener(connectionChanged);
    history?.cancel();
    controls?.dispose();
    video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.contentTitle)),
      body: SafeArea(
          child: Center(
        child: error != null
            ? Padding(padding: const EdgeInsets.all(24), child: Text(error!))
            : controls == null
                ? const CircularProgressIndicator()
                : Chewie(controller: controls!),
      )));
}
