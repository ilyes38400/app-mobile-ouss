import 'package:flutter/material.dart';

// Import des différents players
import 'ultra_smooth_video_player.dart';
import 'gapless_loop_player.dart';

/// Smart Video Player qui choisit automatiquement le meilleur player
/// selon le contexte et permet de basculer facilement entre les différentes solutions
class SmartVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;
  final VideoPlayerType? forcePlayerType;
  final Function(bool isPlaying)? onPlayStateChanged;

  const SmartVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.showControls = false,
    this.forcePlayerType,
    this.onPlayStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerType = forcePlayerType ?? _getOptimalPlayerType();

    switch (playerType) {
      case VideoPlayerType.gapless:
        return GaplessLoopPlayer(
          videoUrl: videoUrl,
          autoPlay: autoPlay,
          showControls: showControls,
          onPlayStateChanged: onPlayStateChanged,
        );

      case VideoPlayerType.ultraSmooth:
        return UltraSmoothVideoPlayer(
          videoUrl: videoUrl,
          autoPlay: autoPlay,
          showControls: showControls,
          onPlayStateChanged: onPlayStateChanged,
        );

      case VideoPlayerType.seamless:
        // Fallback vers ultraSmooth si seamless n'est plus disponible
        return UltraSmoothVideoPlayer(
          videoUrl: videoUrl,
          autoPlay: autoPlay,
          showControls: showControls,
          onPlayStateChanged: onPlayStateChanged,
        );
    }
  }

  VideoPlayerType _getOptimalPlayerType() {
    // Pour tes exercices, utilise le Gapless qui est le plus performant
    if (!showControls && autoPlay) {
      return VideoPlayerType.gapless;
    }
    
    // Pour les autres cas, utilise UltraSmooth
    return VideoPlayerType.ultraSmooth;
  }
}

enum VideoPlayerType {
  /// Player avec double buffer et transition fade (le plus performant)
  gapless,
  
  /// Player avec boucle ultra-précise et timer optimisé
  ultraSmooth,
  
  /// Player avec système de double controller (première version)
  seamless,
}

/// Configuration globale pour tous les players
class VideoPlayerConfig {
  // Tu peux changer cette valeur pour tester différents players
  static VideoPlayerType defaultType = VideoPlayerType.gapless;
  
  // Pour forcer un player spécifique sur tous tes écrans
  static VideoPlayerType? forceGlobalType; // = VideoPlayerType.ultraSmooth;
  
  static VideoPlayerType getPlayerType({VideoPlayerType? override}) {
    return override ?? forceGlobalType ?? defaultType;
  }
}