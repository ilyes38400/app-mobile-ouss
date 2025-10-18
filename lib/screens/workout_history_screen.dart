import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../extensions/colors.dart';
import '../extensions/constants.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../models/workout_log_model.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';

import '../components/manual_workout_dialog.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({Key? key}) : super(key: key);

  @override
  _WorkoutHistoryScreenState createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  List<DateTime> workoutDates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _loadWorkoutHistory();
  }

  Future<void> _loadWorkoutHistory() async {
    if (userStore.userId == 0) return;

    setState(() => _loading = true);
    try {
      final logs = await getWorkoutLogsApi();
      setState(() {
        workoutDates = logs.data.map((log) => log.date).toList();
        _loading = false;
      });
    } catch (e) {
      print("Erreur chargement historique : $e");
      setState(() => _loading = false);
    }
  }

  bool _hasWorkoutOnDay(DateTime day) {
    return workoutDates.any((workoutDate) =>
        workoutDate.year == day.year &&
        workoutDate.month == day.month &&
        workoutDate.day == day.day);
  }

  Future<void> _handleDayTap(DateTime selectedDay) async {
    // Empêcher la saisie pour les jours futurs
    if (selectedDay.isAfter(DateTime.now())) {
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
      builder: (context) => ManualWorkoutDialog(selectedDate: selectedDay),
    );

    if (result == true) {
      // Rafraîchir les données du calendrier
      _loadWorkoutHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        // Rafraîchir automatiquement si des changements sont détectés
        if (userStore.shouldReloadWorkoutLogs == true) {
          _loadWorkoutHistory();
          userStore.shouldReloadWorkoutLogs = false;
        }

        return Scaffold(
      backgroundColor: context.primaryColor,
      appBar: AppBar(
        backgroundColor: context.primaryColor,
        elevation: 0,
        title: Text(
          "Historique des entraînements",
          style: boldTextStyle(color: white, size: 18),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: white),
      ),
      body: Column(
        children: [
          Container(
            width: context.width(),
            decoration: BoxDecoration(
              color: context.scaffoldBackgroundColor,
              borderRadius: BorderRadius.only(
          topLeft: Radius.circular(defaultRadius),
                topRight: Radius.circular(defaultRadius),
              ),
            ),
            child: Column(
              children: [
                20.height,
                
                if (_loading)
                  Container(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TableCalendar<DateTime>(
                      locale: 'fr_FR',
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      selectedDayPredicate: (day) {
                        return false; // Pas de sélection visuelle permanente
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        _handleDayTap(selectedDay);
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: TextStyle(color: Colors.black), // Week-end en noir comme les autres jours
                        holidayTextStyle: TextStyle(color: Colors.black),
                        todayDecoration: BoxDecoration(
                          color: Colors.deepOrange, // Jour actuel en orange
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 0, // Enlever les marqueurs par défaut
                        // Personnaliser les jours d'entraînement avec un contour vert
                        defaultDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonShowsNext: false,
                        formatButtonDecoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        formatButtonTextStyle: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      eventLoader: (day) {
                        return _hasWorkoutOnDay(day) ? [day] : [];
                      },
                      calendarBuilders: CalendarBuilders(
                        // Personnaliser l'affichage du jour actuel
                        todayBuilder: (context, day, focusedDay) {
                          if (_hasWorkoutOnDay(day)) {
                            // Si le jour actuel est un jour d'entraînement, l'afficher en vert
                            return Container(
                              margin: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4CAF50),
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            // Sinon, l'afficher en orange (comportement par défaut)
                            return Container(
                              margin: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.deepOrange,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        // Personnaliser l'affichage des jours d'entraînement
                        defaultBuilder: (context, day, focusedDay) {
                          if (_hasWorkoutOnDay(day)) {
                            return Container(
                              margin: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4CAF50),
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                        // Personnaliser les week-ends avec des jours d'entraînement
                        outsideBuilder: (context, day, focusedDay) {
                          if (_hasWorkoutOnDay(day)) {
                            return Container(
                              margin: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4CAF50),
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                // Légende
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Légende",
                        style: boldTextStyle(size: 16),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text("Jour d'entraînement"),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.deepOrange,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text("Aujourd'hui"),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.touch_app, color: Colors.blue, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Cliquez sur n'importe quel jour pour ajouter un entraînement",
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Statistiques du mois
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Statistiques de ${DateFormat('MMMM yyyy', 'fr_FR').format(_focusedDay)}",
                        style: boldTextStyle(size: 16),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            "Entraînements",
                            _getWorkoutsInMonth(_focusedDay).toString(),
                            Color(0xFF4CAF50),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                40.height,
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  int _getWorkoutsInMonth(DateTime month) {
    return workoutDates.where((date) =>
        date.year == month.year && date.month == month.month).length;
  }
}