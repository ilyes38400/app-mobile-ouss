import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../components/smart_video_player.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../extensions/loader_widget.dart';
import '../models/day_exercise_response.dart';
import '../models/exercise_detail_response.dart' hide Sets;
import '../components/count_down_progress_indicator1.dart';
import '../extensions/colors.dart';
import '../extensions/constants.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/list_extensions.dart';
import '../extensions/system_utils.dart';
import '../extensions/text_styles.dart';
import '../extensions/time_formatter.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../models/models.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import 'chewie_screen.dart';

bool _soundEnabled = false;

class ExerciseDurationScreen1 extends StatefulWidget {
  static String tag = '/ExerciseDurationScreen';
  final ExerciseDetailResponse? mExerciseModel;
  final List<Sets>? mSets;


  ExerciseDurationScreen1(this.mExerciseModel, {this.mSets = const []});

  @override
  ExerciseDurationScreen1State createState() => ExerciseDurationScreen1State();
}

class ExerciseDurationScreen1State extends State<ExerciseDurationScreen1> with TickerProviderStateMixin {
  CountDownController1 mCountDownController1 = CountDownController1();

  Duration? duration;
  FlutterTts? flutterTts;
  int i = 0;
  int? mLength;
  Workout? _workout;
  Tabata? _tabata;
  bool _isResting = false;
  bool _isPreparing = true; // État de préparation avec countdown
  int _countdownValue = 8;
  Timer? _countdownTimer;
  late AnimationController _loaderAnimationController;
  late Animation<double> _countdownAnimation;

  List<String>? mExTime = [];
  List<String>? mRestTime = [];
  late VideoPlayerController _videoPlayerController1;
  ChewieController? _chewieController;
  int? bufferDelay;
  YoutubePlayerController? youtubePlayerController;
  
  late TextEditingController _idController;
  late TextEditingController _seekToController;
  late PlayerState? _playerState;
  late YoutubeMetaData videoMetaData;
  bool _isPlayerReady = false;
  String? videoId = '';

  bool visibleOption = true;
  bool? isChanged = false;
  Future<void>? _initializeFuture;

  // 🎛️ Configuration d'affichage - change cette valeur pour revenir à l'ancien style
  static const bool _useCompactOverlay = false; // true = nouveau style, false = ancien style


  @override
  void initState() {
    super.initState();

    // Animation controller pour le loader rotatif
    _loaderAnimationController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat(); // Répète l'animation en continu
    
    _countdownAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_loaderAnimationController);

    // 1) "Warm‑up" réseau : handshake TLS + 1 Ko de buffer
    _warmUpConnection();

    // 2) Lancement immédiat de l'init du player
    _initializeFuture = _initializePlayer();

    // 3) Ton init Tabata / workout existant
    print(widget.mSets);
    if (widget.mSets != null) {
      // 1) Vide les anciennes données
      mExTime!.clear();
      mRestTime!.clear();

      // 2) Rempli tes listes SANS setState()
      for (var element in widget.mSets!) {
        print(element.rest);
        mExTime!.add(element.time.toString());
        mRestTime!.add(element.rest.toString());
      }

      // 3) Crée ton Tabata
      _tabata = Tabata(
        sets: 1,
        reps: widget.mSets!.length,
        startDelay: Duration(seconds: 0),
        exerciseTime: mExTime,
        restTime: mRestTime,
        breakTime: Duration(seconds: 3),
        status: "reps",
      );

      // 4) Un seul setState() pour tout mettre à jour
      setState(() {});
    }

    init(); // ton init() existant
    _startPreparationCountdown(); // Démarrer le countdown de préparation

    // 4) Setup YouTube / TTS si nécessaire
    if (videoId != null) {
      videoId = YoutubePlayer.convertUrlToId(
        widget.mExerciseModel!.data!.videoUrl.validate(),
      );
    }
    if (flutterTts != null && _soundEnabled) {
      flutterTts!.awaitSpeakCompletion(true);
    }
    if (videoId != null) {
      youtubePlayerController = YoutubePlayerController(
        initialVideoId: videoId!,
        flags: const YoutubePlayerFlags(
          mute: true,
          autoPlay: true,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
          showLiveFullscreenButton: false,
        ),
      )..addListener(listener);
    }
    _idController = TextEditingController();
    _seekToController = TextEditingController();
    if (youtubePlayerController != null) {
      youtubePlayerController!.addListener(() {
        if (_playerState == PlayerState.playing) {
          if (isChanged == true) {
            _workout!.resetTimer();
            isChanged = false;
          }
        }
        if (_playerState == PlayerState.paused) {
          _workout!.pause();
          if (flutterTts != null && _soundEnabled) flutterTts!.pause();
          isChanged = true;
        }
      });
    }
    videoMetaData = const YoutubeMetaData();
    _playerState = PlayerState.unknown;
  }


  init() async {
    //
    if (widget.mSets != null) {
      mLength = widget.mSets!.length - 1;
    }
    _workout = Workout(_tabata!, _onWorkoutChanged);
    // Ne pas démarrer automatiquement, on attend la fin du countdown
  }

  @override
  dispose() {
    _countdownTimer?.cancel();
    _loaderAnimationController.dispose();
    _workout?.dispose();
    _videoPlayerController1.dispose();
    if (youtubePlayerController != null) youtubePlayerController!.dispose();
    _idController.dispose();
    _seekToController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _warmUpConnection() async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(
        Uri.parse(widget.mExerciseModel!.data!.videoUrl.validate()),
      );
      req.headers.add('Range', 'bytes=0-1023');
      final res = await req.close();
      await res.drain();
      client.close(force: true);
    } catch (_) {
    }
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController1 = VideoPlayerController.network(
      widget.mExerciseModel!.data!.videoUrl.validate(),
    );
    await _videoPlayerController1.initialize();
    _createChewieController();
    setState(() {});
  }

  void exitScreen() {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
    Navigator.pop(context, false);
  }

  void listener() {
    if (_isPlayerReady && mounted && !youtubePlayerController!.value.isFullScreen) {
      setState(() {
        _playerState = youtubePlayerController!.value.playerState;
        videoMetaData = youtubePlayerController!.metadata;
      });
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    if (youtubePlayerController != null) youtubePlayerController!.pause();
    super.deactivate();
  }


  void _createChewieController() {
    // Disposer l'ancien contrôleur s'il existe
    _chewieController?.dispose();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController1,
      autoPlay: true,
      looping: true,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp,
      ],
      progressIndicatorDelay: bufferDelay != null ? Duration(milliseconds: bufferDelay!) : null,
      hideControlsTimer: const Duration(seconds: 1),
      showOptions: false,
      showControls: !_isPreparing, // Masquer les contrôles pendant la préparation
      materialProgressColors: ChewieProgressColors(
        playedColor: primaryColor,
        handleColor: primaryColor,
        backgroundColor: textSecondaryColorGlobal,
        bufferedColor: textSecondaryColorGlobal,
      ),
       autoInitialize: false,
    );
  }

  int currPlayIndex = 0;

/*  Future<void> toggleVideo() async {
    await _videoPlayerController1.pause();
    currPlayIndex += 1;
    await initializePlayer();
  }*/

  void _startPreparationCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPreparing || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdownValue > 1) {
          _countdownValue--;
        } else {
          _isPreparing = false;
          timer.cancel();
          // Recréer le contrôleur Chewie pour activer les contrôles
          _createChewieController();
          _start(); // Démarre l'entraînement après le countdown
        }
      });
    });
  }

  void _onWorkoutChanged() {
    // Ignorer les changements pendant la préparation
    if (_isPreparing) return;

    // 1) Si on passe en phase de repos
    if (_workout!.step == WorkoutState.resting) {
      // Ne plus arrêter la vidéo, juste marquer comme repos
      setState(() => _isResting = true);
    }
    // 2) Si on repasse en phase d'exercice
    else if (_workout!.step == WorkoutState.exercising) {
      // La vidéo continue de tourner, on enlève juste l'overlay
      setState(() => _isResting = false);
    }
    // 3) Fin de l'entraînement
    else if (_workout!.step == WorkoutState.finished) {
      Navigator.pop(context, true);
    }

    // 4) On notifie toujours la mise à jour
    setState(() {});
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: Text(
            'Arrêter l\'entraînement ?',
            style: boldTextStyle(color: Colors.white, size: 18),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir arrêter cet exercice ?',
            style: secondaryTextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Continuer',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context, false);
              },
              child: Text(
                'Arrêter',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    final videoUrl = widget.mExerciseModel?.data?.videoUrl;

    if (videoUrl == null || videoUrl.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'Aucune vidéo disponible',
            style: boldTextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Debug : afficher l'état actuel
    print('_buildVideoPlayer: _isPreparing = $_isPreparing, showControls = ${!_isPreparing}');
    print('videoUrl type: ${videoUrl.contains('youtube') ? 'YouTube' : 'HTTP'}');

    // Utiliser le smart player avec contrôles comme en preview
    if (videoUrl.startsWith('http') && !videoUrl.contains('youtube')) {
      return SmartVideoPlayer(
        key: ValueKey(_isPreparing), // Force rebuild quand l'état change
        videoUrl: videoUrl,
        autoPlay: true,
        showControls: !_isPreparing, // Contrôles seulement APRÈS la préparation
        forcePlayerType: VideoPlayerType.gapless,
        onPlayStateChanged: (isPlaying) {
          // Synchroniser la pause vidéo avec le timer workout SEULEMENT si pas en préparation
          if (!_isPreparing) {
            if (isPlaying) {
              if (isChanged == true) {
                _workout?.resetTimer();
                isChanged = false;
              }
            } else {
              _workout?.pause();
              isChanged = true;
            }
          }
        },
      );
    }

    // Fallback vers l'ancien système pour YouTube ou autres
    print('Using Chewie player, _isPreparing = $_isPreparing');
    return _chewieController != null
        ? Stack(
            children: [
              Chewie(
                key: ValueKey(_isPreparing), // Force rebuild quand l'état change
                controller: _chewieController!
              ),
              // Overlay pour masquer tous les contrôles pendant la préparation
              if (_isPreparing)
                Positioned.fill(
                  child: Container(
                    color: Colors.transparent,
                    child: AbsorbPointer(
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
            ],
          )
        : Center(child: CircularProgressIndicator());
  }


  _start() {
    _workout!.start();
  }

  Widget dividerHorizontalLine({bool? isSmall = false}) {
    return Container(
      height: isSmall == true ? 40 : 65,
      width: 4,
      color: whiteColor,
    );
  }

  Widget mSetText(String value, {String? value2}) {
    return Text(value, style: boldTextStyle(size: 18)).center();
  }

  Widget buildSetCardsInDarkMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.mSets!.length, (index) {
        final set = widget.mSets![index];
        final isRepsBased = widget.mExerciseModel!.data!.based == "reps";
        final top = isRepsBased ? "${set.reps.validate()} Reps" : "${set.time.validate()} Sec";
        final bottom = set.rest.validate().isNotEmpty ? "Repos ${set.rest.validate()}s" : "";

        return Column(
          children: [
            Text('Série ${index + 1}', style: primaryTextStyle(color: Colors.white)),
            4.height,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(top, style: boldTextStyle(color: Colors.white, size: 14)),
                  if (bottom.isNotEmpty)
                    Text(bottom, style: secondaryTextStyle(color: Colors.white60, size: 12)),
                ],
              ),
            )
          ],
        );
      }),
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Duration parseDuration(String durationString) {
    List<String> components = durationString.split(':');

    int hours = int.parse(components[0]);
    int minutes = int.parse(components[1]);
    int seconds = int.parse(components[2]);

    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  Widget mData(List<Sets> strings) {
    List<Widget> list = [];
    for (var i = 0; i < strings.length; i++) {
      list.add(new Text(strings[i].time.toString()));
    }
    return new Row(children: list);
  }

  // 🎨 Design moderne et élégant
  Widget _buildCompactVideoInterface() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: FutureBuilder(
            future: _initializeFuture,
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                        16.height,
                        Text(
                          'Chargement...',
                          style: secondaryTextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  // Vidéo en plein écran
                  Positioned.fill(
                    child: _buildVideoPlayer(),
                  ),
                  
                  // Gradient overlay pour améliorer la lisibilité
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: [0.0, 0.25, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // Overlay "Repos" si nécessaire
                  if (_isResting)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.black.withOpacity(0.95),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryColor.withOpacity(0.2),
                                  border: Border.all(color: primaryColor, width: 2),
                                ),
                                child: Icon(
                                  Icons.pause,
                                  color: primaryColor,
                                  size: 40,
                                ),
                              ),
                              20.height,
                              Text(
                                "REPOS",
                                style: boldTextStyle(size: 28, color: Colors.white).copyWith(
                                  letterSpacing: 2,
                                ),
                              ),
                              8.height,
                              Text(
                                "Préparez-vous pour la suite",
                                style: secondaryTextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Header moderne avec titre et infos
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre de l'exercice
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Text(
                              widget.mExerciseModel!.data!.title.validate(),
                              style: boldTextStyle(size: 18, color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Stats en ligne élégantes
                          if (widget.mSets != null) ...[
                            16.height,
                            Row(
                              children: [
                                // Progress des séries
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.fitness_center, color: primaryColor, size: 16),
                                        ),
                                        12.width,
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'SÉRIE',
                                                style: secondaryTextStyle(color: Colors.white60, size: 11).copyWith(
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              2.height,
                                              Text(
                                                '${_workout!.rep}/${widget.mSets!.length}',
                                                style: boldTextStyle(size: 16, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                12.width,
                                
                                // Info reps/temps
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            widget.mExerciseModel!.data!.based == "reps" 
                                                ? Icons.repeat 
                                                : Icons.timer_outlined,
                                            color: primaryColor, 
                                            size: 16
                                          ),
                                        ),
                                        12.width,
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.mExerciseModel!.data!.based == "reps" ? 'REPS' : 'TEMPS',
                                                style: secondaryTextStyle(color: Colors.white60, size: 11).copyWith(
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              2.height,
                                              Text(
                                                _workout!.rep >= 1
                                                    ? (widget.mExerciseModel!.data!.based == "reps"
                                                        ? widget.mSets![_workout!.rep - 1].reps.toString()
                                                        : "${widget.mSets![_workout!.rep - 1].time}s")
                                                    : "—",
                                                style: boldTextStyle(size: 16, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Timer principal moderne en bas
                  Positioned(
                    bottom: 30,
                    left: 30,
                    right: 30,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.9),
                            primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'TEMPS RESTANT',
                            style: secondaryTextStyle(
                              color: Colors.white.withOpacity(0.9), 
                              size: 12,
                            ).copyWith(
                              letterSpacing: 2,
                            ),
                          ),
                          8.height,
                          FittedBox(
                            child: Text(
                              formatTime1(_workout!.timeLeft),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // 📺 Style classique - affichage original
  Widget _buildClassicVideoInterface() {
    return FutureBuilder(
      future: _initializeFuture,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          children: [
            if (_isPreparing) ...[
              12.height,

              Expanded(
                flex: 5,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController1.value.aspectRatio,
                    child: Stack(
                      clipBehavior: Clip.none, // 👈 autorise le dépassement
                      children: [
                        // Vidéo à l’intérieur, légèrement "inset"
                        Positioned.fill(
                          left: 8, right: 8, top: 8, bottom: 8, // 👈 espace pour le halo externe
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ChewieScreen(
                              widget.mExerciseModel!.data!.videoUrl.validate(),
                              widget.mExerciseModel!.data!.exerciseImage.validate(),
                            ),
                          ),
                        ),

                        // Loader "extérieur" (plus grand que la vidéo)
                        Positioned(
                          left: -2, right: -2, top: -2, bottom: -2, // 👈 dépasse autour
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _loaderAnimationController,
                              builder: (_, __) => CustomPaint(
                                painter: OuterArcLoaderPainter(
                                  progress: _countdownAnimation.value,
                                  videoRadius: 16,
                                  stroke: 6,      // épaisseur du trait
                                  gap: 8,         // distance halo/vidéo
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),


              16.height,


            ] else ...[
              // Pendant l'exercice : vidéo prend plus d'espace
              SizedBox(
                height: context.height() * 0.80,
                child: Stack(
                  children: [
                    // Pendant l'exercice : vidéo plein écran total
                    Positioned.fill(
                      child: _buildVideoPlayer(),
                    ),
                    // Overlay repos si nécessaire
                    if (_isResting && !_isPreparing)
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black87,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pause_circle_filled,
                                color: Colors.white,
                                size: 48,
                              ),
                              12.height,
                              Text(
                                "Repos",
                                style: boldTextStyle(size: 24, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            // 📊 Informations en bas - style original optimisé
// ⬇️ Remplace tout ton Expanded(...) actuel par ce code
            _isPreparing
                ? SizedBox(
              height: 150,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Préparez-vous pour le prochain exercice",
                      style: boldTextStyle(size: 18, color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Text(
                          _countdownValue.toString(),
                          style: boldTextStyle(size: 26, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
                : Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Séries + Reps/Durée (uniquement hors préparation)
                    if (widget.mSets != null && _workout != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('${_workout!.rep}/${widget.mSets!.length}',
                                  style: boldTextStyle(size: 18, color: Colors.white)),
                              Text(languages.lblSets,
                                  style: secondaryTextStyle(color: Colors.white60)),
                            ],
                          ),
                          Column(
                            children: [
                              _workout!.rep >= 1
                                  ? Text(
                                widget.mExerciseModel!.data!.based == "reps"
                                    ? widget.mSets![_workout!.rep - 1].reps.toString()
                                    : widget.mSets![_workout!.rep - 1].time.toString(),
                                style: boldTextStyle(size: 18, color: Colors.white),
                              )
                                  : Text("-", style: boldTextStyle(size: 18, color: Colors.white)),
                              Text(
                                widget.mExerciseModel!.data!.based == "reps"
                                    ? languages.lblReps
                                    : languages.lblSecond,
                                style: secondaryTextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ],
                      ).paddingSymmetric(horizontal: 16),

                    // Timer principal
                    if (_workout != null)
                      FittedBox(
                        child: Text(
                          formatTime1(_workout!.timeLeft),
                          style: boldTextStyle(size: 75, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: _isPreparing, // SafeArea seulement en haut pendant la préparation
        child: Stack(
          children: [
            // 🎥 Interface vidéo qui commence juste après la SafeArea
            _useCompactOverlay ? _buildCompactVideoInterface() : _buildClassicVideoInterface(),

            // 🔙 Boutons flottants par-dessus la vidéo
            Positioned(
              top: _isPreparing ? 10 : MediaQuery.of(context).padding.top + 10, // Ajustement selon l'état
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _showExitDialog,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ).paddingSymmetric(horizontal: 8),
            ),
          ],
        ),
      ),
    );
  }


}

// Custom painter pour dessiner le point qui tourne sur le contour rectangulaire
class LoadingDotPainter extends CustomPainter {
  final double progress;
  LoadingDotPainter({this.progress = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 // épaisseur
      ..strokeCap = StrokeCap.round;

    const double cornerRadius = 20.0; // un peu + grand que la vidéo
    // 👇 on élargit volontairement le rect (valeurs négatives)
    final rect = Rect.fromLTWH(-6, -6, size.width + 12, size.height + 12);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;

    // Longueur de l’arc visible (25% du contour)
    final arcLength = metric.length * 0.25;
    final start = progress * metric.length;

    final segment = metric.extractPath(start, start + arcLength);
    canvas.drawPath(segment, paint);
  }

  @override
  bool shouldRepaint(covariant LoadingDotPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class OuterArcLoaderPainter extends CustomPainter {
  final double progress; // 0..1
  final double videoRadius;
  final double stroke;
  final double gap; // distance entre vidéo et halo

  OuterArcLoaderPainter({
    required this.progress,
    this.videoRadius = 16,
    this.stroke = 6,
    this.gap = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Le halo est + grand que la vidéo : on ajoute gap + demi épaisseur
    final inset = (gap) - (stroke / 2); // on "sort" du cadre
    final rect = Rect.fromLTWH(
      inset, inset,
      size.width - 2 * inset,
      size.height - 2 * inset,
    );

    // Rayon + grand que celui de la vidéo
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(videoRadius + gap));

    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;

    // Longueur de l’arc visible (réglable)
    final arc = metric.length * 0.28; // ~28% du tour
    final start = (progress * metric.length) % metric.length;

    // On gère le wrap si on dépasse la fin du path
    final end = start + arc;
    if (end <= metric.length) {
      final seg = metric.extractPath(start, end);
      canvas.drawPath(seg, paint);
    } else {
      final seg1 = metric.extractPath(start, metric.length);
      final seg2 = metric.extractPath(0, end - metric.length);
      canvas.drawPath(seg1, paint);
      canvas.drawPath(seg2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant OuterArcLoaderPainter old) =>
      old.progress != progress ||
          old.videoRadius != videoRadius ||
          old.stroke != stroke ||
          old.gap != gap;
}
