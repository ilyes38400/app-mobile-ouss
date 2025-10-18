import 'dart:ui';

import 'package:flutter/material.dart';

import '../../extensions/app_button.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../extensions/colors.dart';
import '../extensions/decorations.dart';
import '../extensions/horizontal_list.dart';
import '../extensions/text_styles.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../models/day_exercise_response.dart';
import '../models/exercise_detail_response.dart' hide Sets;
import '../network/rest_api.dart';
import '../screens/tips_screen.dart';
import '../screens/youtube_player_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';
import '../utils/app_images.dart';
import 'chewie_screen.dart';

import 'exercise_duration_screen.dart';
import 'exercise_duration_screen1.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final int? mExerciseId;
  final String? mExerciseName;
  final List<Sets>? mSets;


  ExerciseDetailScreen({required this.mExerciseName, required this.mExerciseId, this.mSets = const []});

  @override
  _ExerciseDetailScreenState createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  ExerciseDetailResponse? mExerciseModel;
  ScrollController mScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    if (userStore.adsBannerDetailShowAdsOnExerciseDetail == 1) loadInterstitialAds();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget logSetWidget(String text, String subText) {
    return RichText(
      text: TextSpan(
        text: text,
        style: boldTextStyle(size: 20),
        children: [
          WidgetSpan(
            child: Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(subText, style: secondaryTextStyle()),
            ),
          )
        ],
      ),
    );
  }

  Widget getHeading(String title) {
    return Row(children: [
      Image.asset(ic_level, color: primaryColor, height: 18, width: 18),
      10.width,
      Text(title, style: primaryTextStyle()),
    ]).paddingSymmetric(horizontal: 16);
  }

  Widget dividerHorizontalLine({bool? isSmall = false}) {
    return Container(
      height: isSmall == true ? 40 : 65,
      width: 4,
      color: context.scaffoldBackgroundColor,
    );
  }

  Widget mSetText(String value, {String? value2}) {
    return value2.isEmptyOrNull
        ? Text(value, style: boldTextStyle()).center()
        : Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: boldTextStyle()),
        2.height,
        Text("- " + value2.validate() + languages.lblKg, style: primaryTextStyle(size: 14)),
      ],
    );
  }


  Widget buildSetCardsInDarkMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.mSets!.length, (index) {
        final set = widget.mSets![index];
        final isRepsBased = mExerciseModel!.data!.based == "reps";
        final top = isRepsBased ? "${set.reps.validate()} Reps" : "${set.time.validate()} Sec";
        final bottom = set.rest.validate().isNotEmpty ? "Repos ${set.rest.validate()}s" : "";

        return Column(
          children: [
            Text('Série ${index + 1}', style: primaryTextStyle(color: Colors.white)),
            4.height,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(top, style: boldTextStyle(color: Colors.white, size: 14)),
                  if (bottom.isNotEmpty)
                    Text(bottom, style: secondaryTextStyle(color: Colors.white60, size: 12)),
                ],
              ),
            )
          ],
        );
      }),
    );
  }


  Widget buildSetCards() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.mSets!.length, (index) {
          final set = widget.mSets![index];
          final isRepsBased = mExerciseModel!.data!.based == "reps";
          final String topText = isRepsBased ? "${set.reps.validate()} Reps" : "${set.time.validate()} Sec";
          final String restText = set.rest.validate().isEmpty ? "" : "Repos ${set.rest.validate()}s";

          return Column(
            children: [
              Text('Set ${index + 1}', style: boldTextStyle(size: 13)),
              4.height,
              Container(
                width: context.width() * 0.2,
                height: 58,
                margin: EdgeInsets.symmetric(horizontal: 6),
                padding: EdgeInsets.all(4),
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: appStore.isDarkMode ? cardDarkColor : Colors.white,
                  borderRadius: radius(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(topText, style: boldTextStyle(size: 13), textAlign: TextAlign.center),
                    if (restText.isNotEmpty) ...[
                      4.height,
                      Text(restText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    if (userStore.adsBannerDetailShowAdsOnExerciseDetail == 1) showInterstitialAds();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ Fond noir complet
      body: FutureBuilder(
        future: geExerciseDetailApi(widget.mExerciseId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            mExerciseModel = snapshot.data;

            return SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24), // ✅ Coins arrondis globaux
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                width: double.infinity,
                height: double.infinity, // ✅ prend tout l'écran
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🔙 Retour & menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: Icon(Icons.more_horiz, color: Colors.white),
                            onPressed: () {
                              TipsScreen(
                                mExerciseVideo: mExerciseModel!.data!.videoUrl.validate(),
                                mTips: mExerciseModel!.data!.tips.validate(),
                                mExerciseImage: mExerciseModel!.data!.exerciseImage.validate(),
                                mExerciseInstruction: mExerciseModel!.data!.instruction,
                              ).launch(context);
                            },
                          ),
                        ],
                      ),

                      12.height,

                      // 🎥 Vidéo bien proportionnée
                      Expanded(
                        flex: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ChewieScreen(
                            mExerciseModel!.data!.videoUrl.validate(),
                            mExerciseModel!.data!.exerciseImage.validate(),
                          ),
                        ),
                      ),

                      16.height,

                      // 🏷️ Titre
                      Text(
                        widget.mExerciseName.validate(),
                        style: boldTextStyle(size: 18, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),

                      20.height,

                      // 🧱 Sets
                      buildSetCardsInDarkMode(),

                    ],
                  ),
              ),
            );
          }

          return snapWidgetHelper(snapshot);
        },
      ),
    );
  }

}
