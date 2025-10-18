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
import '../models/goal_challenge_response.dart';
import '../models/goal_achievement_response.dart';
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


  bool _objectivesExpanded = false;
  bool _isExpandedPhysique = true;
  bool _isExpandedAlimentaire = true;
  bool _isExpandedMental = true;
  Map<int, int> achievementIds = {};



  bool _shouldShowWeeklyCard = false;


  final Map<int, bool> _donePhysique    = {};
  final Map<int, bool> _doneAlimentaire = {};
  final Map<int, bool> _doneMental      = {};
  
  // Stockage des IDs d'achievements pour pouvoir les supprimer
  final Map<int, int> _achievementIds = {}; // goalId -> achievementId

  late Future<GoalChallengeResponse> _futurePhysique;
  late Future<GoalChallengeResponse> _futureAlimentaire;
  late Future<GoalChallengeResponse> _futureMental;

  late Future<HomeInformationModel> _futureHomeInfo;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    userStore.loadUserProfile();
    _futurePhysique    = getGoalChallengesApi(theme: "physique");
    _futureAlimentaire = getGoalChallengesApi(theme: "alimentaire");
    _futureMental      = getGoalChallengesApi(theme: "mental");
    // **NOUVEAU** appel de l'API home-information
    _futureHomeInfo    = getHomeInformationApi();

    _searchController.addListener(() {
      setState(() => _showClear = _searchController.text.isNotEmpty);
    });
    fetchWorkoutLogs();
    _checkWeeklyQuestionnaireVisibility();
    
    // Charger les achievements existants après un délai pour laisser les futures se charger
    Future.delayed(Duration(milliseconds: 500), () {
      loadExistingAchievements();
    });

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

  Future<void> loadExistingAchievements() async {
    try {

      final achievements = await getGoalAchievementsApi();


      final achievementsList = achievements.data!;

      for (final achievement in achievementsList) {
        final goalId = achievement.goalChallengeId;
        final achievementId = achievement.id;


        // Stocker l'ID de l'achievement
        achievementIds[goalId] = achievementId;
        sharedPreferences.setInt("achievement_${goalId}", achievementId);

        // NOUVEAU: Mettre à jour l'état des checkboxes selon le type d'objectif
        final goalType = achievement.goalType;
        switch (goalType) {
          case 'physique':
            _donePhysique[goalId] = true;
            sharedPreferences.setBool("physique_${goalId}", true);
            print("✅ DEBUG: Objectif physique $goalId marqué comme accompli");
            break;
          case 'alimentaire':
            _doneAlimentaire[goalId] = true;
            sharedPreferences.setBool("alimentaire_${goalId}", true);
            print("✅ DEBUG: Objectif alimentaire $goalId marqué comme accompli");
            break;
          case 'mental':
            _doneMental[goalId] = true;
            sharedPreferences.setBool("mental_${goalId}", true);
            print("✅ DEBUG: Objectif mental $goalId marqué comme accompli");
            break;
          default:
            print("⚠️ WARNING: Type d'objectif inconnu: $goalType pour goal $goalId");
            break;
        }
      }

      // Forcer la mise à jour de l'interface
      if (mounted) {
        setState(() {});
      }

    } catch (e, stackTrace) {

    }
  }

  Future<void> _toggleGoalAchievement(int goalId, String themeKey, Map<int, bool> doneMap, bool newValue) async {
    // Mettre à jour l'interface immédiatement pour une meilleure UX
    final previousValue = doneMap[goalId] ?? false;
    doneMap[goalId] = newValue;
    sharedPreferences.setBool("${themeKey}_$goalId", newValue);
    setState(() {});
    
    try {
      if (newValue) {
        // Marquer comme accompli via l'API et stocker l'achievement ID
        final response = await markGoalAsAchievedApi(goalChallengeId: goalId);
        if (response.achievementId != null) {
          _achievementIds[goalId] = response.achievementId!;
          // Optionnel: sauvegarder l'ID dans SharedPreferences pour persistance
          sharedPreferences.setInt("achievement_${goalId}", response.achievementId!);
        }
        print("Objectif $goalId marqué comme accompli (Achievement ID: ${response.achievementId})");
        
        // NOUVEAU: Notifier le rafraîchissement des statistiques
        _notifyStatsRefresh();
      } else {
        // Décocher l'objectif - supprimer l'achievement via l'API
        print("🔍 DEBUG: Tentative de suppression pour goal $goalId");
        print("🔍 DEBUG: _achievementIds = ${_achievementIds.toString()}");
        
        final achievementIdFromMemory = _achievementIds[goalId];
        final achievementIdFromPrefs = sharedPreferences.getInt("achievement_${goalId}");
        final achievementId = achievementIdFromMemory ?? achievementIdFromPrefs;
        
        print("🔍 DEBUG: Achievement ID depuis mémoire: $achievementIdFromMemory");
        print("🔍 DEBUG: Achievement ID depuis prefs: $achievementIdFromPrefs");
        print("🔍 DEBUG: Achievement ID final: $achievementId");
        
        if (achievementId != null) {
          print("🔄 Suppression de l'achievement $achievementId via l'API...");
          await deleteGoalAchievementApi(achievementId);
          _achievementIds.remove(goalId);
          sharedPreferences.remove("achievement_${goalId}");
          print("✅ Objectif $goalId décoché - supprimé de l'API (Achievement ID: $achievementId)");
          
          // NOUVEAU: Notifier le rafraîchissement des statistiques
          _notifyStatsRefresh();
        } else {
          print("❌ Objectif $goalId décoché mais aucun Achievement ID trouvé");
        }
      }
      
    } catch (e) {
      // En cas d'erreur, revenir à l'état précédent
      print("Erreur lors de la validation de l'objectif: $e");
      doneMap[goalId] = previousValue;
      sharedPreferences.setBool("${themeKey}_$goalId", previousValue);
      setState(() {});
      
      // Optionnel: afficher un message d'erreur à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la synchronisation de l'objectif"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Nouvelle méthode pour notifier le rafraîchissement des statistiques
  void _notifyStatsRefresh() {
    // Utiliser LiveStream pour notifier les composants de statistiques
    LiveStream().emit('GOAL_STATS_REFRESH', true);
    print("📊 Notification de rafraîchissement des statistiques envoyée");
    
    // Ajouter un délai pour s'assurer que les composants sont prêts
    Future.delayed(Duration(milliseconds: 500), () {
      LiveStream().emit('GOAL_STATS_REFRESH', true);
      print("📊 Notification de rafraîchissement des statistiques (délai) envoyée");
    });
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


  Color _headerColor(String theme) {
    switch (theme) {
      case 'physique':    return Color(0xFF0D47A1);
      case 'alimentaire': return Color(0xFF1565C0);
      case 'mental':      return Color(0xFF1976D2);
      default:            return primaryColor;
    }
  }


  Widget buildGlobalObjectivesCard() {
    Widget buildSection({
      required String emoji,
      required String title,
      required Future<GoalChallengeResponse> future,
      required Map<int, bool> doneMap,
      required String themeKey,
      required bool showDetails,
      required Color barColor,
    }) {
      return FutureBuilder<GoalChallengeResponse>(
        future: future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                color: barColor,
                minHeight: 6,
              ),
            );
          }

          final list = snap.data?.data ?? [];
          for (var g in list) {
            doneMap[g.id] = doneMap[g.id] ?? (sharedPreferences.getBool("${themeKey}_${g.id}") ?? false);
          }
          final doneCount = doneMap.values.where((v) => v).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre + Barre
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Row(
                  children: [
                    Text("$emoji $title", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text("$doneCount / ${list.length}", style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: list.isEmpty ? 0.0 : doneCount / list.length,
                backgroundColor: Colors.white24,
                color: barColor,
                minHeight: 6,
              ),
              // Objectifs détaillés si déplié
              if (_objectivesExpanded && showDetails) ...[
                SizedBox(height: 12),
                ...list.map((g) => Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        g.title,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        g.description.replaceAll(RegExp(r"<[^>]*>"), "").trim(),
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Checkbox(
                        value: doneMap[g.id],
                        onChanged: (v) {
                          final nv = v ?? false;
                          _toggleGoalAchievement(g.id, themeKey, doneMap, nv);
                        },
                        shape: CircleBorder(),
                        checkColor: Colors.white,
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                              (states) => states.contains(MaterialState.selected)
                              ? barColor
                              : Colors.white,
                        ),
                      ),
                      onTap: () {
                        final nv = !doneMap[g.id]!;
                        _toggleGoalAchievement(g.id, themeKey, doneMap, nv);
                      },
                    ),
                    if (g != list.last) Divider(color: Colors.white12),
                  ],
                )),
              ]
            ],
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF142448),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mes Objectifs", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Les 3 sections
          buildSection(
            emoji: "🏋️‍♂️",
            title: "Physique",
            future: _futurePhysique,
            doneMap: _donePhysique,
            themeKey: "physique",
            showDetails: true,
            barColor: Color(0xFF0D47A1),
          ),
          buildSection(
            emoji: "🥦",
            title: "Alimentaire",
            future: _futureAlimentaire,
            doneMap: _doneAlimentaire,
            themeKey: "alimentaire",
            showDetails: true,
            barColor: Color(0xFF1565C0),
          ),
          buildSection(
            emoji: "🧠",
            title: "Mental",
            future: _futureMental,
            doneMap: _doneMental,
            themeKey: "mental",
            showDetails: true,
            barColor: Color(0xFF1976D2),
          ),

          // Bouton Voir/Masquer
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() => _objectivesExpanded = !_objectivesExpanded);
              },
              icon: Icon(
                _objectivesExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
              ),
              label: Text(
                _objectivesExpanded ? "Masquer les objectifs" : "Voir les objectifs",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      String title,
      Future<GoalChallengeResponse> future,
      Map<int, bool> doneMap,
      String themeKey,
      bool isExpanded,
      VoidCallback toggle,
      ) {
    final headerColor = _headerColor(themeKey);

    return FutureBuilder<GoalChallengeResponse>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: Loader()).paddingAll(16);
        }

        final list = snap.data?.data ?? [];
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Aucun défi $title", style: TextStyle(color: Colors.white)),
          );
        }

        for (var g in list) {
          doneMap[g.id] = doneMap[g.id] ?? (sharedPreferences.getBool("${themeKey}_${g.id}") ?? false);
        }

        final doneCount = doneMap.values.where((v) => v).length;

        Widget buildGoalItem(var g) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    g.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    g.description.replaceAll(RegExp(r"<[^>]*>"), "").trim(),
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Checkbox(
                    value: doneMap[g.id],
                    onChanged: (v) {
                      final nv = v ?? false;
                      _toggleGoalAchievement(g.id, themeKey, doneMap, nv);
                    },
                    shape: CircleBorder(),
                    checkColor: Colors.white,
                    fillColor: MaterialStateProperty.resolveWith<Color>(
                          (states) => states.contains(MaterialState.selected) ? headerColor : Colors.white,
                    ),
                  ),
                  onTap: () {
                    final nv = !doneMap[g.id]!;
                    _toggleGoalAchievement(g.id, themeKey, doneMap, nv);
                  },
                ),
              ),
              if (g != list.last) Divider(color: Colors.white12),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isExpanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      "Objectifs $title",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                    Text(
                      "$doneCount/${list.length}",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: LinearProgressIndicator(
                  value: doneCount / list.length,
                  backgroundColor: Colors.grey.shade800,
                  color: headerColor,
                  minHeight: 6,
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: toggle,
                  icon: Icon(Icons.expand_more, color: Colors.white),
                  label: Text("Voir les objectifs", style: TextStyle(color: Colors.white)),
                ),
              ),
            ] else ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF142448),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + barre dans la carte
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Objectifs $title",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: doneCount / list.length,
                            backgroundColor: Colors.grey.shade800,
                            color: headerColor,
                            minHeight: 6,
                          ),
                        ],
                      ),
                    ),

                    ...list.map(buildGoalItem).toList(),

                    Center(
                      child: TextButton.icon(
                        onPressed: toggle,
                        icon: Icon(Icons.expand_less, color: Colors.white),
                        label: Text("Réduire", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
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

                    if (_shouldShowWeeklyCard)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Card(
                          color: Color(0xFF263238),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: Icon(Icons.edit_note, color: Colors.white),
                            title: Text(
                              "Remplir le questionnaire hebdo",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "5 minutes pour répondre au questionnaire",
                              style: TextStyle(color: Colors.white70),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WeeklyQuestionnaireScreen(),
                                ),
                              ).then((_) => _checkWeeklyQuestionnaireVisibility()); // refresh au retour
                            },
                          ),
                        ),
                      ),

                    // Card pour voir les progrès
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Card(
                        color: Color(0xFF4CAF50), // Vert moderne
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Icon(Icons.show_chart, color: Colors.white),
                          title: Text(
                            "Voir mes progrès",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Suivez votre évolution et vos statistiques",
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                          onTap: widget.onProgressTap,
                        ),
                      ),
                    ),

                    buildGlobalObjectivesCard(),


                    20.height,

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Présentation du mois",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: _buildHomeVideoSection(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    20.height,
                    _sectionTitle("Votre parcours forme"),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              onTap: widget.onWorkoutTap,
                              child: Stack(
                                children: [
                                  Image.asset(
                                    'assets/background-workout.png',
                                    width: double.infinity,
                                    height: 185,
                                    fit: BoxFit.cover,
                                  ),
                                  mBlackEffect(context.width() - 32, 185, radiusValue: 16),
                                  Positioned.fill(
                                    child: Center(
                                      child: Text(
                                        "Workouts",
                                        style: boldTextStyle(color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          16.height,
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: InkWell(
                                    onTap: widget.onDietTap,
                                    child: Stack(
                                      children: [
                                        Image.asset(
                                          'assets/background-nutri.jpg',
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                        ),
                                        mBlackEffect(context.width() / 2 - 24, 140, radiusValue: 16),
                                        Positioned.fill(
                                          child: Center(
                                            child: Text(
                                              "Nutrition",
                                              style: boldTextStyle(color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: InkWell(
                                    onTap: widget.onMentalTap,
                                    child: Stack(
                                      children: [
                                        Image.asset(
                                          'assets/background-mental.jpg',
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                        ),
                                        mBlackEffect(context.width() / 2 - 24, 140, radiusValue: 16),
                                        Positioned.fill(
                                          child: Center(
                                            child: Text(
                                              "Mental",
                                              style: boldTextStyle(color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          20.height,
                        ],
                      ),
                    ),
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
