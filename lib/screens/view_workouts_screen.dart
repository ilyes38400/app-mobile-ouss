import 'package:flutter/material.dart';

import '../../components/workout_component.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/loader_widget.dart';
import '../../screens/no_data_screen.dart';
import '../components/adMob_component.dart';
import '../extensions/animatedList/animated_list_view.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../models/workout_detail_response.dart';
import '../network/rest_api.dart';
import '../utils/app_config.dart';

class ViewWorkoutsScreen extends StatefulWidget {
  final bool? isFav;
  final bool? isAssign;

  ViewWorkoutsScreen({this.isFav = false, this.isAssign = false});

  @override
  _ViewWorkoutsScreenState createState() => _ViewWorkoutsScreenState();
}

class _ViewWorkoutsScreenState extends State<ViewWorkoutsScreen> {
  ScrollController scrollController = ScrollController();

  List<WorkoutDetailModel> mWorkoutList = [];

  int page = 1;
  int? numPage;

  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent && !appStore.isLoading) {
        if (page < numPage!) {
          page++;
          init();
        }
      }
    });
  }

  void init() async {
    getWorkoutData();
  }

  Future<void> getWorkoutData() async {
    appStore.setLoading(true);
    print("🔍 DEBUG: Appel getWorkoutListWithAccessApi - isFav: ${widget.isFav}, isAssign: ${widget.isAssign}, page: $page");

    // Utiliser la nouvelle API avec logique d'accès
    await getWorkoutListWithAccessApi(widget.isFav, widget.isAssign, page: page).then((value) {
      print("✅ DEBUG: API Response reçue:");
      print("   - Total items: ${value.data?.length ?? 0}");
      print("   - Total pages: ${value.pagination?.totalPages ?? 0}");

      if (value.data != null && value.data!.isNotEmpty) {
        for (int i = 0; i < value.data!.length; i++) {
          var workout = value.data![i];
          print("   - Workout $i: ${workout.title} (type: ${workout.programType}, access: ${workout.userHasAccess})");
        }
      } else {
        print("❌ DEBUG: Aucun workout retourné par l'API !");
      }

      appStore.setLoading(false);
      numPage = value.pagination!.totalPages;
      isLastPage = false;
      if (page == 1) {
        mWorkoutList.clear();
      }
      Iterable it = value.data!;
      it.map((e) => mWorkoutList.add(e)).toList();

      print("📋 DEBUG: Liste finale mWorkoutList: ${mWorkoutList.length} items");
      setState(() {});
    }).catchError((e) {
      print("❌ DEBUG: Erreur API: $e");
      isLastPage = true;
      appStore.setLoading(false);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            widget.isFav == true || widget.isAssign == true ? PreferredSize(preferredSize: Size.fromHeight(0), child: SizedBox()) : appBarWidget(languages.lblWorkouts, elevation: 0, context: context),
        body: Stack(
          children: [
            mWorkoutList.isNotEmpty
                ? AnimatedListView(
                    shrinkWrap: true,
                    controller: scrollController,
                    itemCount: mWorkoutList.length,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: widget.isFav == true || widget.isAssign == true ? 16 : 4),
                    itemBuilder: (context, int i) {
                      return WorkoutComponent(
                        mWorkoutModel: mWorkoutList[i],
                        isView: true,
                        isActuallyMonthlyProgram: false, // Pas de programmes du mois dans cette vue
                        onCall: () {
                          if (widget.isFav == true) {
                            mWorkoutList.clear();
                            getWorkoutData();
                          }
                        },
                      );
                    },
                  )
                : NoDataScreen(mTitle: languages.lblWorkoutNoFound).visible(!appStore.isLoading),
            Loader().center().visible(appStore.isLoading)
          ],
        ),
        bottomNavigationBar: userStore.adsBannerDetailShowBannerOnWorkouts == 1 && userStore.isSubscribe == 0 ? showBannerAds(context) : SizedBox());
  }
}
