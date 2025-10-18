import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/app_colors.dart';
import '../extensions/loader_widget.dart';

/// Player vidéo spécialement conçu pour le mode programme d'exercices
/// Avec contrôles discrets et adaptés au contexte sportif
class ProgramVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  const ProgramVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
  }) : super(key: key);

  @override
  _ProgramVideoPlayerState createState() => _ProgramVideoPlayerState();
}

class _ProgramVideoPlayerState extends State<ProgramVideoPlayer> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller1;
  VideoPlayerController? _controller2;
  
  int _activeController = 1;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _showControls = false;
  
  Timer? _switchTimer;
  Timer? _hideControlsTimer;
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _controlsAnimation;
  
  Duration? _videoDuration;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController!);
    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut)
    );
    _initializeControllers();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _switchTimer?.cancel();
    _hideControlsTimer?.cancel();
    _fadeController?.dispose();
    _controller1?.dispose();
    _controller2?.dispose();
    super.dispose();
  }

  Future<void> _initializeControllers() async {
    try {
      // Créer les deux controllers pour la lecture gapless
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
      
      // Préparer le second controller
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

    final switchTime = _videoDuration!.inMilliseconds - 150;

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

      await nextController.seekTo(Duration.zero);
      await nextController.play();
      
      setState(() {
        _activeController = _activeController == 1 ? 2 : 1;
      });

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

  void _togglePlayPause() async {
    final controller = _getActiveController();
    if (controller == null) return;

    if (controller.value.isPlaying) {
      _switchTimer?.cancel();
      await controller.pause();
    } else {
      await controller.play();
      _setupGaplessLoop();
    }
    setState(() {});
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });

    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
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

    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Vidéo principale
            Center(
              child: AspectRatio(
                aspectRatio: activeController.value.aspectRatio,
                child: FadeTransition(
                  opacity: _fadeAnimation!,
                  child: VideoPlayer(activeController),
                ),
              ),
            ),
            
            // Contrôles discrets pour le mode programme
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton Play/Pause principal
                        Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ),
                        
                        SizedBox(width: 12),
                        
                        // Indicateur de statut
                        Text(
                          isPlaying ? 'En cours' : 'En pause',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        SizedBox(width: 12),
                        
                        // Icône loop pour indiquer la boucle
                        Icon(
                          Icons.repeat,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Indicateur subtil en bas à droite quand contrôles cachés
            if (!_showControls && isPlaying)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: primaryColor,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.repeat,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Indicateur de tap pour montrer les contrôles
            if (!_showControls)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.white70,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tap pour contrôles',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}