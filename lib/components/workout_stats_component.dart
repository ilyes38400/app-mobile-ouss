import 'package:flutter/material.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/text_styles.dart';
import '../models/workout_stats_response.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';

class WorkoutStatsComponent extends StatefulWidget {
  @override
  _WorkoutStatsComponentState createState() => _WorkoutStatsComponentState();
}

class _WorkoutStatsComponentState extends State<WorkoutStatsComponent> {
  List<WorkoutTypeStat> workoutStats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print("WorkoutStatsComponent: initState appelé");
    loadWorkoutStats();
  }

  Future<void> loadWorkoutStats() async {
    try {
      print("WorkoutStats: Chargement des logs...");
      final response = await getWorkoutLogsApi();
      print("WorkoutStats: ${response.data.length} logs trouvés");
      
      // Calculer les statistiques à partir des logs
      Map<int, WorkoutTypeStat> statsMap = {};
      
      for (var log in response.data) {
        if (log.workoutType != null) {
          final typeId = log.workoutType!.id;
          final typeName = log.workoutType!.title;
          
          if (statsMap.containsKey(typeId)) {
            // Incrémenter le compteur
            final existing = statsMap[typeId]!;
            statsMap[typeId] = WorkoutTypeStat(
              id: existing.id,
              name: existing.name,
              count: existing.count + 1,
              color: existing.color,
            );
          } else {
            // Créer nouvelle entrée
            statsMap[typeId] = WorkoutTypeStat(
              id: typeId,
              name: typeName,
              count: 1,
              color: null, // Couleur par défaut
            );
          }
        }
      }
      
      setState(() {
        workoutStats = statsMap.values.toList();
        // Trier par nombre décroissant
        workoutStats.sort((a, b) => b.count.compareTo(a.count));
        isLoading = false;
      });
    } catch (e) {
      print("Erreur chargement stats workout: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (workoutStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: primaryColor, size: 20),
              8.width,
              Text(
                "Par type d'entraînement",
                style: boldTextStyle(size: 16),
              ),
            ],
          ),
          12.height,
          ...workoutStats.map((stat) => _buildStatRow(stat)),
        ],
      ),
    );
  }

  Widget _buildStatRow(WorkoutTypeStat stat) {
    Color statColor = stat.color != null 
        ? Color(int.parse(stat.color!.replaceFirst('#', '0xFF')))
        : primaryColor;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: statColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.name,
                  style: boldTextStyle(size: 14),
                ),
                2.height,
                Text(
                  "${stat.count} séance${stat.count > 1 ? 's' : ''}",
                  style: secondaryTextStyle(size: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "${stat.count}",
              style: boldTextStyle(size: 14, color: statColor),
            ),
          ),
        ],
      ),
    );
  }
}