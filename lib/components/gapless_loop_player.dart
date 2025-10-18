import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/app_colors.dart';
import '../extensions/loader_widget.dart';

class GaplessLoopPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;
  final Function(bool isPlaying)? onPlayStateChanged;

  const GaplessLoopPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.showControls = false,
    this.onPlayStateChanged,
  }) : super(key: key);

  @override
  _GaplessLoopPlayerState createState() => _GaplessLoopPlayerState();
}

class _GaplessLoopPlayerState extends State<GaplessLoopPlayer> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller1;
  VideoPlayerController? _controller2;
  
  int _activeController = 1;
  bool _isInitialized = false;
  bool _isDisposed = false;
  
  Timer? _switchTimer;
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  
  Duration? _videoDuration;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController!);
    _initializeControllers();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _switchTimer?.cancel();
    _fadeController?.dispose();
    _controller1?.dispose();
    _controller2?.dispose();
    super.dispose();
  }

  Future<void> _initializeControllers() async {
    try {
      // Créer les deux controllers
      _controller1 = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: {
          'User-Agent': 'MyFitnessApp/1.0',
          'Connection': 'keep-alive',
          'Cache-Control': 'max-age=3600',
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      _controller2 = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: {
          'User-Agent': 'MyFitnessApp/1.0',
          'Connection': 'keep-alive',  
          'Cache-Control': 'max-age=3600',
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // Initialiser les deux en parallèle
      await Future.wait([
        _controller1!.initialize(),
        _controller2!.initialize(),
      ]);

      if (_isDisposed) return;

      _videoDuration = _controller1!.value.duration;
      
      // Préparer le second controller au début
      await _controller2!.seekTo(Duration.zero);
      await _controller2!.pause();

      if (widget.autoPlay) {
        await _controller1!.play();
        _setupGaplessLoop();
      }

      await _fadeController!.forward();

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

  void _setupGaplessLoop() {
    if (_isDisposed || _videoDuration == null) return;

    // Calculer le timing précis pour le switch
    final switchTime = _videoDuration!.inMilliseconds - 150; // 150ms avant la fin

    _switchTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      final activeController = _getActiveController();
      if (activeController == null || !activeController.value.isInitialized) return;

      final currentPosition = activeController.value.position.inMilliseconds;
      
      if (currentPosition >= switchTime) {
        _performGaplessSwitch();
      }
    });
  }

  Future<void> _performGaplessSwitch() async {
    if (_isDisposed) return;

    try {
      final nextController = _getInactiveController();
      if (nextController == null) return;

      // Préparer le prochain controller
      await nextController.seekTo(Duration.zero);
      
      // Démarrer le prochain controller
      await nextController.play();
      
      // Switch instantané
      setState(() {
        _activeController = _activeController == 1 ? 2 : 1;
      });

      // Pause et reset l'ancien controller après un petit délai
      Future.delayed(Duration(milliseconds: 200), () async {
        if (!_isDisposed) {
          final oldController = _getInactiveController();
          if (oldController != null) {
            await oldController.pause();
            await oldController.seekTo(Duration.zero);
          }
        }
      });

    } catch (e) {
      print('Erreur lors du switch gapless: $e');
    }
  }

  VideoPlayerController? _getActiveController() {
    if (_activeController == 1) return _controller1;
    return _controller2;
  }

  VideoPlayerController? _getInactiveController() {
    if (_activeController == 1) return _controller2;
    return _controller1;
  }

  Future<void> play() async {
    if (_isInitialized && !_isDisposed) {
      final controller = _getActiveController();
      if (controller != null) {
        await controller.play();
        _setupGaplessLoop();
        widget.onPlayStateChanged?.call(true);
      }
    }
  }

  Future<void> pause() async {
    if (_isInitialized && !_isDisposed) {
      _switchTimer?.cancel();
      final controller = _getActiveController();
      if (controller != null) {
        await controller.pause();
        widget.onPlayStateChanged?.call(false);
      }
    }
  }

  bool get isPlaying {
    if (!_isInitialized || _isDisposed) return false;
    final controller = _getActiveController();
    return controller?.value.isPlaying ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Loader(),
        ),
      );
    }

    final activeController = _getActiveController();
    if (activeController == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text('Erreur de lecture', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    Widget videoWidget = FadeTransition(
      opacity: _fadeAnimation!,
      child: widget.showControls
        ? VideoPlayer(activeController)
        : Stack(
            children: [
              VideoPlayer(activeController),
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
          ),
    );
    
    // TOUJOURS retourner la version sans contrôles si showControls est false
    if (!widget.showControls) {
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: ClipRect(
          child: Center(
            child: AspectRatio(
              aspectRatio: activeController.value.aspectRatio,
              child: Transform.scale(
                scale: 1.2,
                child: videoWidget,
              ),
            ),
          ),
        ),
      );
    }

    // Avec contrôles
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          ClipRect(
            child: Center(
              child: AspectRatio(
                aspectRatio: activeController.value.aspectRatio,
                child: Transform.scale(
                  scale: 1.2, // Agrandit un peu pour remplir toute la largeur
                  child: videoWidget,
                ),
              ),
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
                      setState(() {});
                    },
                  ),

                  // Debug info
                  if (false) // Mets à true pour debug
                    Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Text(
                        'Controller: $_activeController',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}