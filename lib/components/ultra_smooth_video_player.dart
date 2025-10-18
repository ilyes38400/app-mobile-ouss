import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/app_colors.dart';
import '../extensions/loader_widget.dart';

class UltraSmoothVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;
  final Function(bool isPlaying)? onPlayStateChanged;

  const UltraSmoothVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.showControls = false,
    this.onPlayStateChanged,
  }) : super(key: key);

  @override
  _UltraSmoothVideoPlayerState createState() => _UltraSmoothVideoPlayerState();
}

class _UltraSmoothVideoPlayerState extends State<UltraSmoothVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isDisposed = false;
  Timer? _loopTimer;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loopTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: {
          'User-Agent': 'MyFitnessApp/1.0',
          'Accept': 'video/*',
          'Cache-Control': 'max-age=3600',
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize();

      if (_isDisposed) return;

      // Configuration pour une lecture ultra-smooth
      await _controller!.setLooping(false); // On gère manuellement
      
      if (widget.autoPlay) {
        await _controller!.play();
        _setupUltraSmoothLoop();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _setupUltraSmoothLoop() {
    if (_isDisposed || _controller == null) return;

    // Timer ultra-précis pour la boucle seamless
    _loopTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (_isDisposed || _controller == null || !_controller!.value.isInitialized) {
        timer.cancel();
        return;
      }

      final position = _controller!.value.position;
      final duration = _controller!.value.duration;

      if (duration == Duration.zero) return;

      // Restart à 50ms de la fin pour éviter tout glitch
      final timeBeforeEnd = duration - position;
      if (timeBeforeEnd <= const Duration(milliseconds: 50)) {
        _instantRestart();
      }
    });
  }

  Future<void> _instantRestart() async {
    if (_isDisposed || _controller == null) return;

    try {
      // Méthode la plus rapide pour redémarrer
      await _controller!.seekTo(Duration.zero);
      if (!_controller!.value.isPlaying) {
        await _controller!.play();
      }
    } catch (e) {
      print('Erreur lors du restart: $e');
    }
  }

  Future<void> play() async {
    if (_isInitialized && !_isDisposed && _controller != null) {
      await _controller!.play();
      _setupUltraSmoothLoop();
      widget.onPlayStateChanged?.call(true);
    }
  }

  Future<void> pause() async {
    if (_isInitialized && !_isDisposed && _controller != null) {
      _loopTimer?.cancel();
      await _controller!.pause();
      widget.onPlayStateChanged?.call(false);
    }
  }

  bool get isPlaying {
    if (!_isInitialized || _isDisposed || _controller == null) return false;
    return _controller!.value.isPlaying;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Loader(),
        ),
      );
    }

    Widget videoWidget = widget.showControls
        ? VideoPlayer(_controller!)
        : Stack(
            children: [
              VideoPlayer(_controller!),
              // Overlay pour bloquer complètement les contrôles natifs
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Container(),
                  ),
                ),
              ),
            ],
          );
    
    // Pas de contrôles pour l'exercice - juste la vidéo pure
    if (!widget.showControls) {
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: videoWidget,
          ),
        ),
      );
    }

    // Avec contrôles si demandé
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: videoWidget,
            ),
          ),
          
          // Contrôles basiques - seulement si showControls est true
          if (widget.showControls)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        pause();
                      } else {
                        play();
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}