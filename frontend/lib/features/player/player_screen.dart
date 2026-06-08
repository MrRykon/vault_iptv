import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'package:simple_pip_mode/pip_widget.dart';
import '../../core/api/api_service.dart';

class PlayerScreen extends StatefulWidget {
  final String streamUrl;
  final String contentId;
  final String contentTitle;
  final String source; // 'plex' or 'iptv'
  final bool isKidsSafe;

  const PlayerScreen({
    Key? key,
    required this.streamUrl,
    required this.contentId,
    required this.contentTitle,
    required this.source,
    required this.isKidsSafe,
  }) : super(key: key);

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  final ApiService _apiService = ApiService();
  Timer? _historyTimer;
  Timer? _timeoutTimer;
  bool _failedTimeout = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    try { SimplePip().setAutoPipMode(autoEnter: true); } catch (_) {}
  }

  void _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl));
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
    
    setState(() {});

    _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && !_videoPlayerController.value.isInitialized) {
            setState(() {
                _failedTimeout = true;
            });
        }
    });

    // Begin 5-second offset tracker
    _historyTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_videoPlayerController.value.isPlaying) {
         _apiService.recordHistory(
            widget.source,
            widget.contentId,
            widget.contentTitle,
            _videoPlayerController.value.position.inSeconds.toDouble(),
            widget.isKidsSafe
         );
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _historyTimer?.cancel();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PipWidget(
      onPipEntered: () {},
      onPipExited: () {},
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
               if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized)
                 Expanded(
                   child: Stack(
                     children: [
                       Chewie(controller: _chewieController!),
                       Positioned(
                         top: 16,
                         right: 16,
                         child: IconButton(
                           icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white, size: 28),
                           onPressed: () {
                               try { SimplePip().enterPipMode(); } catch (_) {}
                           }
                         )
                       )
                     ]
                   )
                 )
               else
                 const Expanded(
                   child: Center(
                     child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                   )
                 )
            ]
          )
        )
      )
    );
  }
}
