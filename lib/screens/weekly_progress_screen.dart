import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';

import '../components/home_weekly_category_section.dart';
import '../components/workout_stats_component.dart';
import '../components/goal_stats_component.dart';
import '../components/goal_stats_test_component.dart';
import '../components/goal_stats_simple_component.dart';
import '../components/star_diagram_component.dart';
import '../components/manual_workout_dialog.dart';
import '../extensions/colors.dart';
import '../extensions/constants.dart';
import '../extensions/decorations.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../models/workout_log_model.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import 'home_weight_section.dart';
import 'workout_history_screen.dart';

class WeeklyProgressScreen extends StatefulWidget {
  const WeeklyProgressScreen({Key? key}) : super(key: key);

  @override
  _WeeklyProgressScreenState createState() => _WeeklyProgressScreenState();
}

class _WeeklyProgressScreenState extends State<WeeklyProgressScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<DateTime> workoutDates = [];
  late ReactionDisposer _disposer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchWorkoutLogs();
    
    // Ajouter un listener direct sur shouldReloadWorkoutLogs
    _disposer = reaction(
      (_) => userStore.shouldReloadWorkoutLogs,
      (shouldReload) {
        if (shouldReload == true) {
          print("WeeklyProgressScreen: Reaction détectée! Rafraîchissement...");
          fetchWorkoutLogs();
          userStore.shouldReloadWorkoutLogs = false;
        }
      },
    );
  }

  @override
  void dispose() {
    _disposer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Vérifier quand l'app revient au premier plan
      if (userStore.shouldReloadWorkoutLogs == true) {
        print("WeeklyProgressScreen: App resumed, rafraîchissement...");
        fetchWorkoutLogs();
        userStore.shouldReloadWorkoutLogs = false;
      }
    }
  }

  Future<void> fetchWorkoutLogs() async {
    if (userStore.userId == 0) return;

    try {
      print("WeeklyProgressScreen: Chargement des logs...");
      final logs = await getWorkoutLogsApi();
      setState(() {
        workoutDates = logs.data.map((log) => log.date).toList();
        print("WeeklyProgressScreen: ${workoutDates.length} entraînements chargés");
      });
    } catch (e) {
      print("Erreur chargement logs workout : $e");
    }
  }

  int getTotalWorkoutDays() {
    return workoutDates.length;
  }

  int getWorkoutDaysThisWeek() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    
    return workoutDates.where((date) {
      return date.isAfter(startOfWeek.subtract(Duration(days: 1))) && 
             date.isBefore(endOfWeek.add(Duration(days: 1)));
    }).length;
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        height: 110,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAnnualReport(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );

      final email = userStore.email;
      final response = await getAnnualQuestionnaireResultsApi(email);
      
      Navigator.of(context).pop();
      
      if (response.data.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AnnualReportDialog(data: response.data),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aucune donnée de questionnaire disponible pour cette année'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement du bilan annuel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildMiniCalendar() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final daysOfWeek = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: daysOfWeek.map((day) {
        final isWorkout = workoutDates.any((d) =>
        d.year == day.year && d.month == day.month && d.day == day.day);

        final isToday = DateUtils.dateOnly(day) == DateUtils.dateOnly(today);

        Color bgColor;
        Color textColor;
        Color borderColor;
        Color checkColor;

        if (isWorkout) {
          bgColor = Color(0xFF7ED6AC); // ✅ vert plus soutenu
          textColor = Colors.black;
          borderColor = Color(0xFF1E7E5A); // vert profond pour contraste
          checkColor = Color(0xFF1E7E5A);  // même vert profond pour la coche
        } else if (isToday) {
          bgColor = Colors.deepOrange;
          textColor = Colors.white;
          borderColor = Colors.white;
          checkColor = Colors.deepOrange;
        } else {
          bgColor = Colors.white;
          textColor = Colors.black;
          borderColor = Colors.grey.shade400;
          checkColor = Colors.transparent;
        }

        return Column(
          children: [
            GestureDetector(
              onTap: () async {
                // Empêcher la saisie pour les jours futurs
                if (day.isAfter(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Impossible d\'ajouter un entraînement pour un jour futur'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => ManualWorkoutDialog(selectedDate: day),
                );

                if (result == true) {
                  // Rafraîchir les données du calendrier
                  fetchWorkoutLogs();
                }
              },
              child: Container(
                width: 48,
                height: 88,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('d').format(day),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    Text(
                      DateFormat('E', 'fr_FR').format(day).toLowerCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 2),
                        color: isWorkout ? Colors.white : Colors.transparent,
                      ),
                      child: isWorkout
                          ? Icon(Icons.check, size: 14, color: checkColor)
                          : (!day.isAfter(DateTime.now()) 
                              ? Icon(Icons.add, size: 14, color: borderColor) 
                              : null),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Nécessaire pour AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: context.primaryColor,
      appBar: AppBar(
        backgroundColor: context.primaryColor,
        elevation: 0,
        title: Text(
          "Mes Progrès",
          style: boldTextStyle(color: white, size: 20),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: context.width(),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: context.scaffoldBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(defaultRadius),
                  topRight: Radius.circular(defaultRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  20.height,
                  
                  
                  // Section Ma semaine
                  Observer(
                    builder: (_) {
                      if (userStore.shouldReloadWorkoutLogs == true) {
                        print("WeeklyProgressScreen: Rafraîchissement détecté!");
                        fetchWorkoutLogs();
                        userStore.shouldReloadWorkoutLogs = false;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Ma semaine", style: boldTextStyle()),
                                TextButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WorkoutHistoryScreen(),
                                      ),
                                    );
                                    // Rafraîchir les données au retour
                                    fetchWorkoutLogs();
                                  },
                                  child: Text(
                                    "Voir l'historique",
                                    style: TextStyle(
                                      color: Color(0xFF2196F3),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            buildMiniCalendar(),
                          ],
                        ),
                      );
                    },
                  ),

                  20.height,

                  // Section Statistiques d'entraînement
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Statistiques d'entraînement",
                          style: boldTextStyle(size: 18, color: Colors.black87),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatCard(
                              "Total jours entraînés",
                              getTotalWorkoutDays().toString(),
                              Color(0xFF4CAF50),
                              Icons.calendar_month,
                            ),
                            SizedBox(width: 12),
                            _buildStatCard(
                              "Cette semaine",
                              getWorkoutDaysThisWeek().toString(),
                              Color(0xFF2196F3),
                              Icons.today,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Statistiques par type d'entraînement
                        WorkoutStatsComponent(),
                        SizedBox(height: 8),
                        // Puis le vrai component
                        Builder(
                          builder: (context) {
                            try {
                              return GoalStatsComponentNew();
                            } catch (e) {
                              print("❌ ERROR: Erreur lors du rendu de GoalStatsComponent: $e");
                              return Container(
                                padding: EdgeInsets.all(16),
                                child: Text("Erreur: $e", style: TextStyle(color: Colors.red)),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  20.height,

                  // Section Suivi de poids
                  HomeWeightSection(),
                  
                  // Section Évolution hebdomadaire des catégories  
                  HomeWeeklyCategorySection(),

                  20.height,

                  // Section Bilan Annuel
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.star_border_rounded,
                            size: 48,
                            color: primaryColor,
                          ),
                          16.height,
                          Text(
                            'Bilan Annuel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          20.height,
                          ElevatedButton(
                            onPressed: () => _showAnnualReport(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.assessment, color: Colors.white),
                                8.width,
                                Text(
                                  'Voir mon bilan annuel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  40.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}