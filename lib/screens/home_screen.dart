// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

import 'package:mighty_fitness/screens/search_screen.dart';
import 'package:mighty_fitness/screens/notification_screen.dart';
import 'package:mighty_fitness/screens/edit_profile_screen.dart';
import 'package:mighty_fitness/screens/workout_list_screen.dart';
import 'package:mighty_fitness/screens/diet_screen.dart';
import 'package:mighty_fitness/screens/mental_preparation_list_screen.dart';
import 'package:mighty_fitness/screens/weekly_progress_screen.dart';

import '../components/manual_workout_dialog.dart';

import '../components/home_weekly_category_section.dart';
import '../extensions/decorations.dart';
import '../extensions/loader_widget.dart';
import '../../components/level_component.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/widgets.dart';
import '../extensions/app_text_field.dart';
import '../extensions/common.dart';
import '../extensions/horizontal_list.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../models/home_information_model.dart';
import '../network/rest_api.dart';
import '../extensions/LiveStream.dart';
import '../utils/app_constants.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_images.dart';
import 'WeeklyQuestionnaireScreen.dart';
import 'home_weight_section.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onWorkoutTap;
  final VoidCallback onDietTap;
  final VoidCallback onMentalTap;
  final VoidCallback? onProgressTap;

  const HomeScreen({
    Key? key,
    required this.onProfileTap,
    required this.onWorkoutTap,
    required this.onDietTap,
    required this.onMentalTap,
    this.onProgressTap,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showClear = false;
  List<DateTime> workoutDates = [];


  bool _shouldShowWeeklyCard = false;

  late Future<HomeInformationModel> _futureHomeInfo;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    userStore.loadUserProfile();
    _futureHomeInfo    = getHomeInformationApi();

    _searchController.addListener(() {
      setState(() => _showClear = _searchController.text.isNotEmpty);
    });
    fetchWorkoutLogs();
    _checkWeeklyQuestionnaireVisibility();

  }

  @override
  void dispose() {
    _searchController.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }


  void fetchWorkoutLogs() async {
    try {
      final dates = await getWorkoutLogsApi();
      setState(() {
        workoutDates = dates.data.map((e) => e.date).toList();
      });
    } catch (e) {
      print("Erreur récupération des logs : $e");
    }
  }


  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
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
  Future<void> _checkWeeklyQuestionnaireVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_weekly_questionnaire_${userStore.email.validate()}';
    final lastStr = prefs.getString(key);

    if (lastStr == null) {
      setState(() => _shouldShowWeeklyCard = true); // jamais rempli
      return;
    }

    final last = DateTime.tryParse(lastStr);
    if (last == null) {
      setState(() => _shouldShowWeeklyCard = true);
      return;
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // lundi

    if (last.isBefore(startOfWeek)) {
      setState(() => _shouldShowWeeklyCard = true);
    } else {
      setState(() => _shouldShowWeeklyCard = false);
    }
  }









  Widget _buildHomeVideoSection() {
    return FutureBuilder<HomeInformationModel>(
      future: _futureHomeInfo,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200,
            child: Center(child: Loader()),
          );
        }

        if (snap.hasError || snap.data == null) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Impossible de charger la vidéo"),
          );
        }

        final info = snap.data!;
        final videoUrl = info.videoUrl.trim();

        // Check si le contrôleur existe mais sur une URL différente
        if (_videoPlayerController == null ||
            _videoPlayerController!.dataSource != videoUrl) {
          // Libère les anciens contrôleurs
          _videoPlayerController?.dispose();
          _chewieController?.dispose();

          // Crée les nouveaux contrôleurs
          _videoPlayerController = VideoPlayerController.network(videoUrl);
          _videoPlayerController!.initialize().then((_) {
            setState(() {
              _chewieController = ChewieController(
                videoPlayerController: _videoPlayerController!,
                autoPlay: false,
                looping: true,
              );
            });
          }).catchError((error) {
            print('Erreur d\'initialisation vidéo: $error');
          });

          // Pendant l'initialisation
          return SizedBox(
            height: 200,
            child: Center(child: Loader()),
          );
        }

        if (!_videoPlayerController!.value.isInitialized) {
          return SizedBox(
            height: 200,
            child: Center(child: Loader()),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.all(8),
          height: 200,
          child: Chewie(controller: _chewieController!),
        );
      },
    );
  }


  @override
  @override
  Widget build(BuildContext context) {
    const double cardHeight = 185.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // barre du haut avec avatar
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  Observer(builder: (_) {
                    return InkWell(
                      onTap: widget.onProfileTap,
                      child: cachedImage(
                        userStore.profileImage.validate(),
                        width: 42,
                        height: 42,
                      ).cornerRadiusWithClipRRect(100).paddingAll(1),
                    );
                  }),
                  10.width,
                  Expanded(
                    child: Text(
                      "${languages.lblHey}${userStore.fName.validate().capitalizeFirstLetter()}👋",
                      style: boldTextStyle(size: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Image.asset(ic_notification,
                        width: 24, height: 24, color: primaryColor),
                    onPressed: () => NotificationScreen().launch(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ✅ Mini calendrier inséré ici
                    Observer(
                      builder: (_) {
                        if (userStore.shouldReloadWorkoutLogs == true) {
                          fetchWorkoutLogs();
                          userStore.shouldReloadWorkoutLogs = false;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ma semaine", style: boldTextStyle()),
                              SizedBox(height: 8),
                              buildMiniCalendar(),
                              SizedBox(height: 12),
/*                              TextButton(
                                onPressed: () {
                                  // TODO : navigation vers calendrier complet
                                },
                                child: Text("Voir tout le calendrier"),
                              )*/
                            ],
                          ),
                        );
                      },
                    ),

                    // Section Questionnaires
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Questionnaires",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),

                          // Questionnaire hebdomadaire
                          if (_shouldShowWeeklyCard)
                            Card(
                              color: Color(0xFF263238),
                              elevation: 3,
                              margin: EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                leading: Icon(Icons.edit_note, color: Colors.white),
                                title: Text(
                                  "Questionnaire bien-être hebdomadaire",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Évaluez votre bien-être de la semaine",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WeeklyQuestionnaireScreen(),
                                    ),
                                  ).then((_) => _checkWeeklyQuestionnaireVisibility());
                                },
                              ),
                            ),

                          // Placeholder pour futurs questionnaires
                          Card(
                            color: Color(0xFF1565C0),
                            elevation: 3,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Icon(Icons.assignment, color: Colors.white),
                              title: Text(
                                "Questionnaire retour de compétition",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Bientôt disponible",
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: Icon(Icons.lock, color: Colors.white70),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Fonctionnalité en développement")),
                                );
                              },
                            ),
                          ),

                          Card(
                            color: Color(0xFF388E3C),
                            elevation: 3,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Icon(Icons.book, color: Colors.white),
                              title: Text(
                                "Carnet d'entraînement mensuel",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Objectifs techniques, tactiques, physiques et mentaux",
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: Icon(Icons.lock, color: Colors.white70),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Fonctionnalité en développement")),
                                );
                              },
                            ),
                          ),

                          Card(
                            color: Color(0xFF7B1FA2),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Icon(Icons.star, color: Colors.white),
                              title: Text(
                                "Questionnaire d'accomplissement mensuel",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Évaluez votre satisfaction mensuelle",
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: Icon(Icons.lock, color: Colors.white70),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Fonctionnalité en développement")),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    20.height,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
