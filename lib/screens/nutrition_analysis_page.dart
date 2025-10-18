import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../main.dart';                     // Assure-toi que `cameras` est exposé ici
import '../utils/compress_image.dart';
import '../network/rest_api.dart';
import '../models/nutrition_photo_response.dart';
import 'nutrition_result_page.dart';

class NutritionAnalysisPage extends StatefulWidget {
  const NutritionAnalysisPage({Key? key}) : super(key: key);

  @override
  State<NutritionAnalysisPage> createState() => _NutritionAnalysisPageState();
}

class _NutritionAnalysisPageState extends State<NutritionAnalysisPage> {
  late CameraController _controller;
  late Future<void> _initFuture;
  File? _capturedImage;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _setupCamera();
  }

  Future<void> _setupCamera() async {
    // On prend la caméra arrière si dispo, sinon la première
    final backCam = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      backCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    await _initFuture;
    final XFile raw = await _controller.takePicture();
    setState(() => _capturedImage = File(raw.path));
  }

  Future<void> _analyze() async {
    if (_capturedImage == null) return;
    setState(() => _isAnalyzing = true);
    try {
      final File optimized = await compressAndConvertImage(_capturedImage!);
      final NutritionPhotoResponse resp = await sendNutritionPhotoApi(optimized);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NutritionResultPage(
          imageFile: _capturedImage!,
          response: resp,
        ),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur analyse : \$e')),
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analyse Nutritionnelle")),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final size = MediaQuery.of(context).size;
          final deviceRatio = size.width / size.height;
          final cameraRatio = _controller.value.aspectRatio;
          // calcule l’échelle pour couvrir tout l’écran
          double scale = deviceRatio * cameraRatio;
          if (scale < 1) scale = 1 / scale;

          return Stack(
            children: [
              Transform.scale(
                scale: scale,
                child: Center(
                  child: _capturedImage == null
                  // live preview
                      ? CameraPreview(_controller)
                  // photo capturée, remplissage et coupe (BoxFit.cover)
                      : Image.file(
                    _capturedImage!,
                    fit: BoxFit.cover,
                    width: size.width,
                    height: size.height,
                  ),
                ),
              ),

              // Overlay en bas
              Positioned(
                bottom: 0, left: 0, right: 0, height: 200,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black26, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Boutons
              Positioned(
                bottom: 32, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_capturedImage == null)
                      FloatingActionButton(
                        onPressed: _takePhoto,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.camera_alt, color: Colors.black),
                      )
                    else if (_isAnalyzing)
                      const CircularProgressIndicator(color: Colors.white)
                    else ...[
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => setState(() => _capturedImage = null),
                        ),
                        const SizedBox(width: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text("Analyser"),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _analyze,
                        ),
                      ]
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }



}
