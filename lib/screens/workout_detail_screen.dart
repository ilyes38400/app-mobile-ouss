import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:mighty_fitness/screens/program_payment_screen.dart';
import '../components/program_access_button.dart';

import '../../extensions/colors.dart';
import '../../extensions/decorations.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../network/rest_api.dart';
import '../../utils/app_images.dart';
import '../components/HtmlWidget.dart';
import '../components/exercise_day_component.dart';
import '../extensions/animatedList/animated_list_view.dart';
import '../extensions/constants.dart';
import '../extensions/extension_util/list_extensions.dart';
import '../extensions/common.dart';
import '../extensions/loader_widget.dart';
import '../extensions/system_utils.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../models/day_exercise_response.dart';
import '../models/exercise_detail_response.dart';
import '../models/workout_detail_response.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import 'exercise_duration_screen1.dart';
import 'subscribe_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final int? id;

  final WorkoutDetailModel? mWorkoutModel;

  WorkoutDetailScreen({this.id, this.mWorkoutModel});

  @override
  _WorkoutDetailScreenState createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  ScrollController scrollController = ScrollController();
  int page = 1;
  int? numPage;
  int currentTabIndex = 0;
  int? mWorkoutId;

  bool isLastPage = false;
  bool isLoading = false;

  List<DayExerciseModel> mDayExerciseList = [];
  List<Workoutday> mWorkoutDayList = [];
  List<Widget> tabs = [];

  WorkoutDetailModel? mWorkoutDetailModel;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    if (userStore.adsBannerDetailShowAdsOnWorkoutDetail == 1) loadInterstitialAds();
    appStore.setLoading(true);
    await getWorkoutDetailWithAccessApi(widget.id.validate()).then((value) {
      mWorkoutDetailModel = value.data;

      // ✅ Plus de blocage ici - permettre l'accès aux détails
      // La logique d'accès sera gérée dans l'affichage des boutons

      tabs.clear();
      value.workoutday!.forEachIndexed((element, index) {
        tabs.add(Text("${languages.lblDay} ${index + 1}"));
      });
      mWorkoutDayList = value.workoutday!;
      getDayExerciseData(value.workoutday!.first.id.validate());
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      setState(() {});
    });
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent && !appStore.isLoading) {
        if (page < numPage!) {
          page++;
          getDayExerciseData(mWorkoutId);
        }
      }
    });
  }

  @override
  void dispose() {
    if (userStore.adsBannerDetailShowAdsOnWorkoutDetail == 1) showInterstitialAds();
    super.dispose();
  }

  Future<void> getDayExerciseData(int? id) async {
    await getDayExerciseApi(id).then((value) {
      numPage = value.pagination!.totalPages;
      isLastPage = false;
      if (page == 1) {
        mDayExerciseList.clear();
      }
      Iterable it = value.data!;
      it.map((e) => mDayExerciseList.add(e)).toList();
      appStore.setLoading(false);
      isLoading = false;
      setState(() {});
    }).catchError((e) {
      isLastPage = true;
      isLoading = false;
      appStore.setLoading(false);
      setState(() {});
    });
  }

  Widget mData(String? img, String? mTitle, String? mValue) {
    return Column(
      children: [
        Image.asset(img.toString(), width: 24, height: 24, color: primaryColor),
        4.height,
        Text(mTitle.validate(), style: boldTextStyle()),
        4.height,
        Text(mValue.validate(), style: secondaryTextStyle()),
      ],
    );
  }

  Future<void> setWorkout(int? id) async {
    appStore.setLoading(true);
    Map req = {"workout_id": id};
    await setWorkoutFavApi(req).then((value) {
      toast(value.message);
      appStore.setLoading(false);
      if (mWorkoutDetailModel!.isFavourite == 1) {
        mWorkoutDetailModel!.isFavourite = 0;
      } else {
        mWorkoutDetailModel!.isFavourite = 1;
      }
      appStore.setLoading(false);
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      setState(() {});
    });
  }

  bool _hasAccess() {
    if (mWorkoutDetailModel == null) return false;
    return mWorkoutDetailModel!.userHasAccess == true || mWorkoutDetailModel!.programType == 'free';
  }

  String _getUnlockButtonText() {
    if (mWorkoutDetailModel!.price != null && mWorkoutDetailModel!.price! > 0) {
      return "Débloquer ce programme - ${mWorkoutDetailModel!.price!.toStringAsFixed(2)} €";
    }
    return "Débloquer ce programme";
  }

  void _showUnlockDialog() {
    if (mWorkoutDetailModel!.programType == 'premium') {
      _showSubscriptionDialog();
    } else if (mWorkoutDetailModel!.programType == 'paid') {
      _showPurchaseDialog();
    } else {
      // Fallback pour compatibilité
      if (mWorkoutDetailModel!.isPremium == 1 && userStore.isSubscribe == 0) {
        _showSubscriptionDialog();
      }
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Abonnement requis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 50, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Ce programme "${mWorkoutDetailModel!.title}" est réservé aux membres premium.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Abonnez-vous pour accéder à tous les programmes premium !',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pop(context);
              },
              child: Text('Retour'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pop(context);
                // Naviguer vers la page d'abonnement comme dans profile_screen
                SubscribeScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('S\'abonner', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Achat requis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart, size: 50, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Ce programme "${mWorkoutDetailModel!.title}" nécessite un achat.',
                textAlign: TextAlign.center,
              ),
              if (mWorkoutDetailModel!.price != null) ...[
                SizedBox(height: 8),
                Text(
                  'Prix: ${mWorkoutDetailModel!.price!.toStringAsFixed(2)} €',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pop(context);
              },
              child: Text('Retour'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Lancer le processus d'achat avec notre ProgramPaymentScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProgramPaymentScreen(
                      programId: mWorkoutDetailModel!.id!,
                      programTitle: mWorkoutDetailModel!.title!,
                      programType: 'workout',
                      price: mWorkoutDetailModel!.price ?? 0.0,
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    // Paiement réussi, recharger les données complètes du workout
                    _refreshWorkoutData();
                  }
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Acheter', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            if (widget.mWorkoutModel != null)
              DefaultTabController(
                length: mWorkoutDayList.isEmpty ? 0 : mWorkoutDayList.length,
                initialIndex: currentTabIndex,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              cachedImage(widget.mWorkoutModel!.workoutImage.validate(), width: context.width(), height: context.height() * 0.39, fit: BoxFit.cover),
                              mBlackEffect(context.width(), context.height() * 0.39, radiusValue: 0),
                            ],
                          ),
                          Positioned(
                              top: context.statusBarHeight,
                              left: appStore.selectedLanguageCode == 'ar' ? 8 : 0,
                              child: Column(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      finish(context);
                                    },
                                    icon: Icon(appStore.selectedLanguageCode == 'ar' ? MaterialIcons.arrow_forward_ios : Octicons.chevron_left, color: whiteColor),
                                  ),
                                  if (userStore.subscription == "1")
                                    if (widget.mWorkoutModel!.isPremium == 1) mPro().paddingOnly(left: 16, top: 8)
                                ],
                              )),
                          if (mWorkoutDetailModel != null)
                            Positioned(
                              right: 16,
                              top: context.statusBarHeight + 8,
                              child: InkWell(
                                onTap: () {
                                  setWorkout(mWorkoutDetailModel!.id.validate());
                                },
                                child: Container(
                                  decoration: boxDecorationWithRoundedCorners(backgroundColor: favBackground, boxShape: BoxShape.circle),
                                  padding: EdgeInsets.all(5),
                                  child: Image.asset(mWorkoutDetailModel!.isFavourite == 1 ? ic_favorite_fill : ic_favorite,
                                          color: mWorkoutDetailModel!.isFavourite == 1 ? primaryColor : white, width: 20, height: 20)
                                      .center(),
                                ),
                              ),
                            ),
                          Positioned(left: 16, bottom: 42, child: Text(widget.mWorkoutModel!.title.capitalizeFirstLetter().toString(), style: boldTextStyle(size: 20, color: Colors.white)))
                        ],
                      ),
                    ),
                    DraggableScrollableSheet(
                      initialChildSize: 0.65,
                      minChildSize: 0.65,
                      maxChildSize: 0.9,
                      builder: (context, controller) => Container(
                        width: context.width(),
                        decoration: boxDecorationWithRoundedCorners(borderRadius: radiusOnly(topLeft: 20.0, topRight: 20.0), backgroundColor: context.scaffoldBackgroundColor),
                        child: SingleChildScrollView(
                          controller: controller,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              16.height,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  mData(ic_dumbbell, widget.mWorkoutModel!.workoutTypeTitle.validate(), languages.lblWorkoutType),
                                  mData(ic_level, widget.mWorkoutModel!.levelTitle.validate(), languages.lblLevel),
                                ],
                              ).paddingSymmetric(horizontal: 32),
                              10.height,
                              Divider(indent: 16, endIndent: 16),
                              10.height,
                              if (!appStore.isLoading)
                                Column(
                                  children: [
                                    HtmlWidget(postContent: mWorkoutDetailModel!.description.validate()).paddingSymmetric(horizontal: 8).visible(!mWorkoutDetailModel!.description.isEmptyOrNull),
                                    20.height,
                                    TabBar(
                                      indicatorColor: primaryColor,
                                      unselectedLabelStyle: primaryTextStyle(),
                                      labelStyle: boldTextStyle(),
                                      labelColor: primaryColor,
                                      labelPadding: EdgeInsets.only(bottom: 8, left: 16, right: 16),
                                      unselectedLabelColor: appStore.isDarkMode ? Colors.white : textSecondaryColorGlobal,
                                      isScrollable: true,
                                      tabs: tabs,
                                      onTap: (index) {
                                        if (mWorkoutDayList.isNotEmpty && index < mWorkoutDayList.length) {
                                          currentTabIndex = index;
                                          mWorkoutId = mWorkoutDetailModel!.id;
                                          isLoading = true;
                                          getDayExerciseData(mWorkoutDayList[index].id);
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    Divider(height: 0, indent: 16),
                      Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (mDayExerciseList.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _hasAccess()
                                        ? ElevatedButton.icon(
                                            onPressed: () {
                                              launchAutoWorkout(context, mDayExerciseList);
                                            },
                                            icon: Icon(Icons.play_arrow),
                                            label: Text("Tout lancer"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          )
                                        : ElevatedButton.icon(
                                            onPressed: () {
                                              _showUnlockDialog();
                                            },
                                            icon: Icon(Icons.lock_open),
                                            label: Text(_getUnlockButtonText()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                  ],
                                ).paddingSymmetric(horizontal: 16, vertical: 8),


                              if (mDayExerciseList.isNotEmpty)
                                AnimatedListView(
                                  controller: scrollController,
                                  itemCount: mDayExerciseList.length,
                                  physics: NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    List<String> mSets = [];
                                    if (mDayExerciseList[index].sets != null &&
                                        mDayExerciseList[index].sets!.isNotEmpty) {
                                      mDayExerciseList[index].sets!.forEach((element) {
                                        if (mDayExerciseList[index].exercise!.based.toString() == "time") {
                                          mSets.add(element.time.toString() + "s");
                                        } else {
                                          mSets.add(element.reps.toString() + "x");
                                        }
                                      });
                                    } else if (mDayExerciseList[index].repetitions != null) {
                                      mSets.add(mDayExerciseList[index].repetitions.toString() + "x");
                                    }
                                    return ExerciseDayComponent(mDayExerciseModel: mDayExerciseList[index], mSets: mSets);
                                  },
                                ),

                              if (!isLoading && mDayExerciseList.isEmpty)
                                Text(
                                  (mWorkoutDayList.isNotEmpty && currentTabIndex < mWorkoutDayList.length && mWorkoutDayList[currentTabIndex].isRest == 1)
                                      ? languages.lblBreak
                                      : languages.lblNoFoundData,
                                  style: secondaryTextStyle(),
                                ).center().paddingOnly(top: 50),
                            ],
                          ),
                          Loader().center().paddingOnly(top: 50).visible(isLoading),
                        ],
                      ),

                                  ],
                                )
                            ],
                          ).paddingOnly(bottom: 16),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            Loader().center().visible(appStore.isLoading)
          ],
        ),
      ),
    );
  }

  Future<void> _refreshWorkoutData() async {
    // Recharger les données complètes du workout après achat
    appStore.setLoading(true);
    try {
      final value = await getWorkoutDetailWithAccessApi(widget.id.validate());
      mWorkoutDetailModel = value.data;

      // Maintenant que l'utilisateur a acheté, il devrait avoir accès
      if (mWorkoutDetailModel!.userHasAccess == true) {
        // Recharger les tabs et les exercices
        tabs.clear();
        value.workoutday!.forEachIndexed((element, index) {
          tabs.add(Text("${languages.lblDay} ${index + 1}"));
        });
        mWorkoutDayList = value.workoutday!;

        // Recharger les exercices du premier jour
        currentTabIndex = 0;
        await getDayExerciseData(value.workoutday!.first.id.validate());
      }

      setState(() {});
    } catch (e) {
      print('Erreur lors du rechargement: $e');
    } finally {
      appStore.setLoading(false);
    }
  }

  void launchAutoWorkout(BuildContext context, List<DayExerciseModel> exercises) async {
    for (int i = 0; i < exercises.length; i++) {
      DayExerciseModel exercise = exercises[i];

      final detail = await geExerciseDetailApi(exercise.exercise!.id);

      final completed = await Navigator.of(context).push<bool>(
        PageRouteBuilder(
          opaque: false,
          transitionDuration: Duration(milliseconds: 0),
          pageBuilder: (_, __, ___) => ExerciseDurationScreen1(
            detail,
            mSets: exercise.sets,
          ),
        ),
      );
      try {
        await saveWorkoutLogApi(
          workoutTypeId: widget.mWorkoutModel?.workoutTypeId ?? 1,
        );
      } catch (e) {
        print("Erreur lors de la sauvegarde du log d'entraînement : $e");
      }

      if (completed != true) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Session interrompue"),
            content: Text("Vous avez quitté l'entraînement avant la fin."),
            actions: [
              TextButton(
                onPressed: () {
                  userStore.shouldReloadWorkoutLogs = true;
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
        return;
      }
    }
    // ✅ Affichage du message final
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Félicitations 🎉"),
        content: Text("Vous avez terminé tous les exercices du jour !"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

}
