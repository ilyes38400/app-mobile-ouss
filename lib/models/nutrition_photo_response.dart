// lib/models/nutrition_photo_response.dart
import 'dart:convert';

class NutritionPhotoResponse {
  final String titre;
  final String description;
  final String calories;
  final String proteines;
  final String lipides;
  final String glucides;
  final String fibres;

  NutritionPhotoResponse({
    required this.titre,
    required this.description,
    required this.calories,
    required this.proteines,
    required this.lipides,
    required this.glucides,
    required this.fibres,
  });

  factory NutritionPhotoResponse.fromJson(Map<String, dynamic> src) {
    final raw = src['candidates'][0]['content']['parts'][0]['text'] as String;
    final cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final Map<String, dynamic> data = jsonDecode(cleaned);
    final nutri = data['valeurs_nutritionnelles'] as Map<String, dynamic>;

    return NutritionPhotoResponse(
      titre: data['titre'] as String,
      description: data['description'] as String,
      calories: nutri['calories'] as String,
      proteines: nutri['proteines'] as String,
      lipides: nutri['lipides'] as String,
      glucides: nutri['glucides'] as String,
      fibres: nutri['fibres'] as String,
    );
  }
}
