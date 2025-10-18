import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../extensions/extension_util/context_extensions.dart';
import '../extensions/constants.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/loader_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';

import '../components/smart_video_player.dart';

class ChewieScreen extends StatefulWidget {
  final String url;
  final String image;

  ChewieScreen(this.url, this.image);

  @override
  State<StatefulWidget> createState() {
    return _ChewieScreenState();
  }
}

class _ChewieScreenState extends State<ChewieScreen> {
  VideoPlayerController? _videoPlayerController1;
  ChewieController? _chewieController;
  int? bufferDelay;
  bool _useSmartPlayer = true; // Option pour utiliser le smart player

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController1?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    if (!_useSmartPlayer) {
      _videoPlayerController1 = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await Future.wait([_videoPlayerController1!.initialize()]);
      _createChewieController();
      setState(() {});
    }
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController1!,
      autoPlay: true,
      looping: true,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp,
      ],
      progressIndicatorDelay: bufferDelay != null ? Duration(milliseconds: bufferDelay!) : null,
      hideControlsTimer: const Duration(seconds: 1),
      showOptions: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: primaryColor,
        handleColor: primaryColor,
        backgroundColor: textSecondaryColorGlobal,
        bufferedColor: textSecondaryColorGlobal,
      ),
      // autoInitialize: true,
    );
  }

  int currPlayIndex = 0;

  Future<void> toggleVideo() async {
    await _videoPlayerController1?.pause();
    currPlayIndex += 1;
    await initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _useSmartPlayer
            ? SmartVideoPlayer(
                videoUrl: widget.url,
                autoPlay: true,
                showControls: true,
                forcePlayerType: VideoPlayerType.gapless,
              )
            : _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : Center(
                    child: Loader(),
                  ),
      ),
    );
  }
}
