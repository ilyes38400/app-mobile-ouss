// lib/screens/mental_preparation_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:simple_pip_mode/simple_pip.dart';

import '../../extensions/loader_widget.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/text_styles.dart';
import '../../extensions/decorations.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/components/HtmlWidget.dart';
import 'package:mighty_fitness/models/mental_preparation_response.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/screens/program_payment_screen.dart';
import 'package:mighty_fitness/screens/subscribe_screen.dart';
import '../../extensions/common.dart';

import '../main.dart';

class MentalPreparationDetailScreen extends StatefulWidget {
  final int? id;
  final String? slug;
  final MentalPreparation? mMentalPreparationModel;

  const MentalPreparationDetailScreen({
    Key? key,
    this.id,
    this.slug,
    this.mMentalPreparationModel
  }) : super(key: key);

  @override
  _MentalPreparationDetailScreenState createState() =>
      _MentalPreparationDetailScreenState();
}

class _MentalPreparationDetailScreenState
    extends State<MentalPreparationDetailScreen> {
  MentalPreparation? _mp;
  bool _isLoading = true;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  Future<void>? _initializeFuture;

  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;
  bool _playerReady = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      MentalPreparationResponse response;

      if (widget.id != null) {
        // Utiliser la nouvelle API avec contrôle d'accès
        response = await getMentalPreparationDetailWithAccessApi(widget.id!);
        if (response.data.isNotEmpty) {
          _mp = response.data.first;

          // Setup du player seulement si l'utilisateur a accès
          if (_mp!.userHasAccess == true || _mp!.programType == 'free') {
            _setupPlayer(_mp!);
          }
        }
      } else if (widget.slug != null) {
        // Fallback vers l'ancienne méthode par slug
        response = await getMentalPreparationBySlugApi(slug: widget.slug!);
        if (response.data.isNotEmpty) {
          _mp = response.data.first;
          if (_mp!.userHasAccess == true || _mp!.programType == 'free') {
            _setupPlayer(_mp!);
          }
        }
      } else if (widget.mMentalPreparationModel != null) {
        // Utiliser le modèle fourni
        _mp = widget.mMentalPreparationModel;
        if (_mp!.userHasAccess == true || _mp!.programType == 'free') {
          _setupPlayer(_mp!);
        }
      }
    } catch (_) {
      _mp = null;
    }
    setState(() => _isLoading = false);
  }

  bool _hasAccess() {
    if (_mp == null) return false;
    return _mp!.userHasAccess == true || _mp!.programType == 'free';
  }

  String _getUnlockButtonText() {
    if (_mp!.price != null && _mp!.price! > 0) {
      return "Débloquer ce programme - ${_mp!.price!.toStringAsFixed(2)} €";
    }
    return "Obtenir l'accès";
  }

  void _showUnlockDialog() {
    if (_mp!.programType == 'premium') {
      _showSubscriptionDialog();
    } else if (_mp!.programType == 'paid') {
      _showPurchaseDialog();
    } else {
      // Fallback pour compatibilité
      _showPurchaseDialog();
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Abonnement requis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 50, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Cette préparation mentale "${_mp!.title}" est réservée aux membres premium.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Abonnez-vous pour accéder à tous les programmes premium !',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                SubscribeScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('S\'abonner', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Achat requis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart, size: 50, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Cette préparation mentale "${_mp!.title}" nécessite un achat.',
                textAlign: TextAlign.center,
              ),
              if (_mp!.price != null) ...[
                SizedBox(height: 8),
                Text(
                  'Prix: ${_mp!.price!.toStringAsFixed(2)} €',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProgramPaymentScreen(
                      programId: _mp!.id,
                      programTitle: _mp!.title,
                      programType: 'mental', // Backend attend exactement 'mental'
                      price: _mp!.price ?? 0.0,
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    // Paiement réussi, recharger les données
                    _refreshMentalPreparationData();
                  }
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Acheter', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshMentalPreparationData() async {
    if (widget.id == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await getMentalPreparationDetailWithAccessApi(widget.id!);
      if (response.data.isNotEmpty) {
        _mp = response.data.first;

        // Maintenant que l'utilisateur a acheté, il devrait avoir accès
        if (_mp!.userHasAccess == true) {
          _setupPlayer(_mp!);
        }
      }
      setState(() {});
    } catch (e) {
      print('Erreur lors du rechargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupPlayer(MentalPreparation mp) {
    final url = mp.videoUrl;
    final ytId = YoutubePlayer.convertUrlToId(url);
    if (mp.videoType == 'external' && ytId != null) {
      _isYoutube = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: ytId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: true),
      )..addListener(() {
        if (_playerReady && mounted) setState(() {});
      });
    } else {
      _isYoutube = false;
      _videoPlayerController = VideoPlayerController.network(url);
      _initializeFuture = _videoPlayerController!.initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: false,
          looping: false,
          deviceOrientationsAfterFullScreen: [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ],
          hideControlsTimer: const Duration(seconds: 2),
          showOptions: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: primaryColor,
            handleColor: primaryColor,
            backgroundColor: Colors.grey.shade300,
            bufferedColor: Colors.grey.shade300,
          ),
          autoInitialize: true,
        );
      });
    }
  }

  Widget _buildVideoPlayer() {
    // Si pas d'accès, ne pas afficher de vidéo
    if (!_hasAccess()) {
      return const Center(
        child: Text(
          "Accès requis pour voir la vidéo",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (_isYoutube && _youtubeController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: primaryColor,
          onReady: () => _playerReady = true,
        ),
        builder: (_, player) => player,
      );
    }
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snap) {
        if (_initializeFuture == null ||
            snap.connectionState != ConnectionState.done ||
            _chewieController == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Chewie(controller: _chewieController!);
      },
    );
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1) On récupère le HTML brut
    final rawHtml = _mp?.description ?? '';
    // 2) On remplace uniquement les déclarations de couleur par blanc
    final sanitizedHtml = rawHtml.replaceAll(
      RegExp(r'color\s*:\s*[^;"]+'),
      'color: #ffffff',
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (!_isLoading && _mp != null)
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Image en entête ───
                    Stack(
                      children: [
                        cachedImage(
                          _mp!.imageUrl.validate(),
                          width: context.width(),
                          height: context.height() * 0.35,
                          fit: BoxFit.cover,
                        ),
                        mBlackEffect(
                            context.width(), context.height() * 0.35,
                            radiusValue: 0),
                        Positioned(
                          top: context.statusBarHeight + 8,
                          left: appStore.selectedLanguageCode == 'ar' ? 8 : 0,
                          child: IconButton(
                            icon: Icon(
                              appStore.selectedLanguageCode == 'ar'
                                  ? MaterialIcons.arrow_forward_ios
                                  : Octicons.chevron_left,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Description (texte en blanc) ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: HtmlWidget(postContent: sanitizedHtml),
                    ),
                    const SizedBox(height: 40),

                    // ─── Bouton d'accès si nécessaire ───
                    if (!_hasAccess())
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                _showUnlockDialog();
                              },
                              icon: Icon(Icons.lock_open),
                              label: Text(_getUnlockButtonText()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!_hasAccess()) const SizedBox(height: 24),

                    // ─── Lecteur vidéo (fond noir) - Seulement si accès ───
                    if (_hasAccess())
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.black,
                            child: AspectRatio(
                              aspectRatio: _videoPlayerController
                                  ?.value.aspectRatio ??
                                  16 / 9,
                              child: _buildVideoPlayer(),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              )
            else if (!_isLoading && _mp == null)
              Center(
                child: Text("Programme non trouvé",
                    style: secondaryTextStyle(color: Colors.white)),
              ),

            // Loader centré
            Loader().center().visible(_isLoading),
          ],
        ),
      ),
    );
  }
}
