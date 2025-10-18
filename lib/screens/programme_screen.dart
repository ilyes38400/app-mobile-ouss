import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart'; // Importation de Chewie
import '../../extensions/horizontal_list.dart';
import '../../extensions/loader_widget.dart';
import '../../models/program_response.dart'; // Modèle adapté pour Program
import '../../network/rest_api.dart'; // API pour récupérer les programmes
import '../../utils/app_colors.dart';
import '../../extensions/text_styles.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../models/video_response.dart';
import '../utils/app_config.dart';

// Écran pour afficher la vidéo avec les contrôles
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({required this.videoUrl, Key? key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    // Initialisation du VideoPlayerController
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: {
        'User-Agent': 'MyFitnessApp/1.0',
        'Accept': 'video/mp4',
      },
    )..initialize().then((_) {
      setState(() {
        // Initialisation du ChewieController avec des options
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          aspectRatio: _videoController.value.aspectRatio * 0.9, // Réduction légère de l'aspect ratio
          autoPlay: true,
          looping: false, // Permet de ne pas répéter automatiquement la vidéo
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                'Erreur de lecture : $errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
      });
    }).catchError((e) {
      print('Erreur lors du chargement de la vidéo : $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vidéo", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: Center(
        child: _chewieController != null &&
            _chewieController!.videoPlayerController.value.isInitialized
            ? Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: MediaQuery.of(context).size.height * 0.75, // La vidéo prendra 75% de la hauteur de l'écran
          child: Chewie(controller: _chewieController!), // Utilisation de Chewie pour afficher la vidéo
        )
            : const CircularProgressIndicator(), // Loader en attendant l'initialisation
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}

// Écran pour afficher la liste des programmes
class ProgramScreen extends StatefulWidget {
  const ProgramScreen({Key? key}) : super(key: key);

  @override
  _ProgramScreenState createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Programme",
          style: boldTextStyle(color: Colors.white, size: 20),
        ),
        backgroundColor: primaryColor,
      ),
      body: FutureBuilder<ProgramResponse>(
        future: getPurchasedProgramsApi(userStore.userId), // Appeler l'API pour récupérer les programmes
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            ProgramResponse? programResponse = snapshot.data;

            return ListView.builder(
              itemCount: programResponse!.programs.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                Program program = programResponse.programs[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image principale du programme
                        program.imageUrl != null
                            ? Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage('$imageBackUrl/storage/${program.imageUrl}'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                            : Container(
                          height: 120,
                          color: Colors.grey,
                          child: const Icon(Icons.image_not_supported, color: Colors.white),
                        ),
                        const SizedBox(height: 8),

                        // Titre du programme
                        Text(
                          program.title,
                          style: boldTextStyle(size: 16),
                        ),
                        const SizedBox(height: 8),

                        // Liste des vidéos (fichiers) du programme
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: program.files.length,
                          itemBuilder: (context, fileIndex) {
                            FileInfo file = program.files[fileIndex];

                            return GestureDetector(
                              onTap: () async {
                                // Appeler l'API pour obtenir l'URL de streaming de la vidéo
                                VideoMobileResponse response = await getVideoStreamUrl(file.filename);
                                // Extraire l'URL de la vidéo de la réponse
                                String videoStreamUrl = response.videoUrl;

                                // Naviguer vers l'écran de lecture vidéo avec l'URL correcte
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoPlayerScreen(
                                      videoUrl: videoStreamUrl,
                                    ),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: const Icon(Icons.play_circle_outline),
                                title: Text(file.filename),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return snapWidgetHelper(snapshot, loadingWidget: Loader());
        },
      ),
    );
  }
}
