import 'package:flutter/material.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/text_styles.dart';
import '../extensions/LiveStream.dart';
import '../models/goal_stats_response.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';

class GoalStatsComponentNew extends StatefulWidget {
  @override
  _GoalStatsComponentNewState createState() {
      return _GoalStatsComponentNewState();
  }
}

class _GoalStatsComponentNewState extends State<GoalStatsComponentNew> {
  GoalStatsData? goalStats;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    try {
      super.initState();

      loadGoalStats();

      LiveStream().on('GOAL_STATS_REFRESH', (dynamic data) {
        if (mounted) {
          loadGoalStats();
        }
      });
      
    } catch (e) {
      print("❌ DEBUG: Erreur dans initState: $e");
      rethrow;
    }
  }

  Future<void> loadGoalStats() async {
    try {

      final response = await getGoalAchievementStatsApi();
      
      if (mounted) {
        setState(() {
          goalStats = response.data;
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ DEBUG: Erreur API statistiques: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Erreur: $e";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null || goalStats == null) {
      return const SizedBox.shrink();
    }

    // Vérifier si il y a vraiment des données à afficher
    final hasData = goalStats!.totalAchievements > 0 || 
                   goalStats!.byType.physique > 0 || 
                   goalStats!.byType.alimentaire > 0 || 
                   goalStats!.byType.mental > 0;
                   
    if (!hasData) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: EdgeInsets.all(16),
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
              Icon(Icons.track_changes, color: primaryColor, size: 20),
              8.width,
              Text("Objectifs accomplis", style: boldTextStyle(size: 16)),
            ],
          ),
/*          16.height,
          
          // Stats principales
          Row(
            children: [
              Expanded(child: _buildStatCard("Total", goalStats!.totalAchievements.toString(), Colors.blue)),
              8.width,
              Expanded(child: _buildStatCard("Ce mois", goalStats!.thisMonth.toString(), Colors.green)),
              8.width,
              Expanded(child: _buildStatCard("Cette année", goalStats!.thisYear.toString(), Colors.orange)),
            ],
          ),*/
          
          16.height,
          Text("Par catégorie (total)", style: boldTextStyle(size: 14)),
          8.height,
          
          // Stats par type
          _buildTypeStatRow("🏃‍♂️ Physique", goalStats!.byType.physique, Color(0xFF2196F3)),
          4.height,
          _buildTypeStatRow("🥗 Alimentaire", goalStats!.byType.alimentaire, Color(0xFF4CAF50)),
          4.height,
          _buildTypeStatRow("🧠 Mental", goalStats!.byType.mental, Color(0xFF9C27B0)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor, // ✅ même couleur de fond pour tous
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)), // ✅ neutre
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)), // ✅ barre colorée
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                2.height,
                Text(label, style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTypeStatRow(String title, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          12.width,
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}