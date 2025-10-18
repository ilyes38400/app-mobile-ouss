import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Compresse et convertit l’image en JPEG.
/// Ajustez minWidth, minHeight et quality selon vos besoins.
Future<File> compressAndConvertImage(File file) async {
  final result = await FlutterImageCompress.compressWithFile(
    file.absolute.path,
    minWidth: 800,      // largeur minimale souhaitée
    minHeight: 600,     // hauteur minimale souhaitée
    quality: 85,        // qualité (0-100)
    format: CompressFormat.jpeg,
  );

  if (result == null) {
    throw Exception("La compression de l'image a échoué");
  }

  // Enregistrement dans un fichier temporaire
  final tempDir = await getTemporaryDirectory();
  final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
  return File(targetPath)..writeAsBytesSync(result);
}
