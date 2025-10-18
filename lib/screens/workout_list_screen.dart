import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/horizontal_list.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/models/dashboard_response.dart';
import 'package:mighty_fitness/models/workout_response.dart';
import 'package:mighty_fitness/models/workout_detail_response.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/screens/programs_by_type_screen.dart';
import 'package:mighty_fitness/utils/app_colors.dart';

import '../components/workout_component.dart';
import '../main.dart';
import 'no_data_screen.dart';

class WorkoutListScreen extends StatefulWidget {
  @override
  _WorkoutListScreenState createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  late Future<DashboardResponse> _futureDashboard;
  late Future<WorkoutResponse> _futureWorkouts;
  late Future<WorkoutResponse> _futureMonthlyPrograms;
  List<WorkoutDetailModel> _monthlyWorkoutsList = [];

  @override
  void initState() {
    super.initState();
    _futureDashboard = getDashboardApi();
    _futureWorkouts = getWorkoutListWithAccessApi(false, false);
    _futureMonthlyPrograms = getWorkoutListWithAccessApi(false, false, isMonthlyProgram: true);
    _loadMonthlyWorkouts();
  }

  Future<void> _loadMonthlyWorkouts() async {
    try {
      final response = await getWorkoutListWithAccessApi(false, false, isMonthlyProgram: true);
      setState(() {
        _monthlyWorkoutsList = response.data ?? <WorkoutDetailModel>[];
      });
    } catch (e) {
      print("Erreur chargement workouts du mois: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      body: SafeArea(
        child: FutureBuilder<DashboardResponse>(
          future: _futureDashboard,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Loader().center();
            }
            if (!snap.hasData || snap.data!.workouttype == null || snap.data!.workouttype!.isEmpty) {
              return NoDataScreen(mTitle: "Aucun type d'entraînement trouvé").center();
            }

            final types = snap.data!.workouttype;

            return FutureBuilder<WorkoutResponse>(
              future: _futureWorkouts,
              builder: (ctx, workoutSnap) {
                if (workoutSnap.connectionState == ConnectionState.waiting) {
                  return Loader().center();
                }
                if (!workoutSnap.hasData || workoutSnap.data!.data == null || workoutSnap.data!.data!.isEmpty) {
                  return NoDataScreen(mTitle: "Aucun entraînement trouvé").center();
                }

                final workouts = workoutSnap.data!.data!;

            return ListView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 32),
              children: [
                30.height,
                
                // Section Programmes du mois avec contour doré
                FutureBuilder<WorkoutResponse>(
                  future: _futureMonthlyPrograms,
                  builder: (ctx, monthlySnap) {
                    if (monthlySnap.hasData && 
                        monthlySnap.data!.data != null &&
                        monthlySnap.data!.data!.isNotEmpty) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color(0xFFFFD700), // Or
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 24,
                                ),
                                8.width,
                                Text("Programmes du mois", 
                                    style: boldTextStyle(size: 20, color: Colors.white)),
                                Spacer(),
                                Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 24,
                                ),
                              ],
                            ),
                            16.height,
                            HorizontalList(
                              padding: EdgeInsets.zero,
                              itemCount: monthlySnap.data!.data!.length,
                              spacing: 12,
                              physics: BouncingScrollPhysics(),
                              itemBuilder: (_, idx) {
                                final workout = monthlySnap.data!.data![idx];
                                return Container(
                                  width: 200,
                                  child: WorkoutComponent(
                                    mWorkoutModel: workout,
                                    onCall: () => setState(() {}),
                                    isView: true,
                                    isMonthlyProgram: true, // Dans la section "Programme du mois", masquer les badges dorés
                                    isActuallyMonthlyProgram: true, // C'est vraiment un programme du mois
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox();
                  },
                ),
                30.height,
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Types d'entraînements", style: boldTextStyle(size: 20, color: Colors.white)),
                ),
                16.height,

                if (types != null && types.isNotEmpty)
                  ...types.map((type) {
                    final workoutsOfType = workouts
                        .where((w) => w.workoutTypeId == type.id)
                        .toList();

                    // Séparer les workouts du mois des autres
                    final monthlyWorkoutsOfType = workoutsOfType
                        .where((w) => _monthlyWorkoutsList.any((monthly) => monthly.id != null && w.id != null && monthly.id == w.id))
                        .toList();
                    final regularWorkoutsOfType = workoutsOfType
                        .where((w) => !_monthlyWorkoutsList.any((monthly) => monthly.id != null && w.id != null && monthly.id == w.id))
                        .toList();

                    // Combiner: workouts du mois en premier, puis les autres
                    final sortedWorkouts = [...monthlyWorkoutsOfType, ...regularWorkoutsOfType];

                    if (sortedWorkouts.isEmpty) return SizedBox();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre + bouton
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(type.title ?? "", style: boldTextStyle(size: 18, color: Colors.white)),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProgramsByTypeScreen(
                                        type: type,
                                        allWorkouts: sortedWorkouts,
                                      ),
                                    ),
                                  );
                                },
                                child: Text("Voir tout", style: secondaryTextStyle(color: Colors.grey[300])),
                              ),
                            ],
                          ),
                        ),

                        // Liste horizontale de petits cards
                        HorizontalList(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sortedWorkouts.length,
                          spacing: 12,
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (_, idx) {
                            final workout = sortedWorkouts[idx];
                            final isMonthlyProgram = _monthlyWorkoutsList.any((monthly) => monthly.id != null && workout.id != null && monthly.id == workout.id);
                            return Container(
                              width: 200,
                              child: WorkoutComponent(
                                mWorkoutModel: workout,
                                onCall: () => setState(() {}),
                                isView: true,
                                isMonthlyProgram: false, // Dans les types, on ne masque jamais
                                isActuallyMonthlyProgram: isMonthlyProgram, // Mais on indique si c'est un programme du mois
                              ),
                            );
                          },
                        ),
                        20.height,
                      ],
                    );
                  }),
              ],
            );
              },
            );
          },
        ),
      ),
    );
  }
}
