import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import '../components/workout_component.dart';
import '../main.dart';
import '../models/dashboard_response.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import '../models/workout_detail_response.dart';
import '../utils/app_colors.dart';

class ProgramsByTypeScreen extends StatelessWidget {
  final Workouttype type;
  final List<WorkoutDetailModel> allWorkouts;

  ProgramsByTypeScreen({
    required this.type,
    required this.allWorkouts,
  });

  @override
  Widget build(BuildContext context) {
    final List<WorkoutDetailModel> workoutsOfType =
    allWorkouts.where((w) => w.workoutTypeId == type.id).toList();

    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      appBar: AppBar(
        title: Text(type.title!, style: boldTextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1C1C1E), // 👈 Même couleur que le fond
        elevation: 0, // 👈 (optionnel) pour enlever l’ombre et garder un look plat
      ),
      body: workoutsOfType.isEmpty
          ? Center(
        child: Text(
          "Aucun programme pour « ${type.title} »",
          style: secondaryTextStyle(color: Colors.white),
        ),
      )
          : Padding(
        padding: EdgeInsets.only(top: 16, bottom: 32),
        child: GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: workoutsOfType.length,
          physics: BouncingScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,           // 👉 2 cartes par ligne
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,       // 👈 Ajuste selon la hauteur souhaitée
          ),
          itemBuilder: (_, idx) {
            return WorkoutComponent(
              mWorkoutModel: workoutsOfType[idx],
              onCall: () {
                appStore.setLoading(true);
                Future.delayed(Duration(milliseconds: 100), () {
                  appStore.setLoading(false);
                });
              },
              isView: true, // 👈 pour appliquer le bon style (comme dans WorkoutListScreen)
              isActuallyMonthlyProgram: false, // Pas de programmes du mois dans cette vue spécifique
            );
          },
        ),
      ),
    );
  }
}
