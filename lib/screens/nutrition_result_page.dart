import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/text_theme_extensions.dart';
import '../models/nutrition_photo_response.dart';

class NutritionResultPage extends StatelessWidget {
  final File imageFile;
  final NutritionPhotoResponse response;

  const NutritionResultPage({
    Key? key,
    required this.imageFile,
    required this.response,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final imageHeight = screenH * 0.33;

    return Scaffold(
      appBar: AppBar(title: const Text("Résultats Nutrition")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // IMAGE AVEC MARGE HORIZONTALE & COINS ARRONDIS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                imageFile,
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // TITRE & DESCRIPTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(response.titre,
                    style: Theme.of(context).textTheme.headline6),
                const SizedBox(height: 6),
                Text(response.description,
                    style: Theme.of(context).textTheme.bodyText2),
              ],
            ),
          ),

          // GRILLE DES MACROS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
                children: [
                  _MacroCard(
                    color: Colors.orange.shade50,
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: response.calories,
                  ),
                  _MacroCard(
                    color: Colors.red.shade50,
                    icon: Icons.fitness_center,
                    label: 'Protéines',
                    value: response.proteines,
                  ),
                  _MacroCard(
                    color: Colors.yellow.shade50,
                    icon: Icons.opacity,
                    label: 'Lipides',
                    value: response.lipides,
                  ),
                  _MacroCard(
                    color: Colors.lightBlue.shade50,
                    icon: Icons.grain,
                    label: 'Glucides',
                    value: response.glucides,
                  ),
                  // pleine largeur pour Fibres
                  GridTile(
                    child: _MacroCard(
                      color: Colors.grey.shade200,
                      icon: Icons.restaurant,
                      label: 'Fibres',
                      value: response.fibres,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;

  const _MacroCard({
    Key? key,
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black54),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
