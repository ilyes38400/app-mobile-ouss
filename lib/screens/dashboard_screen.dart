// lib/screens/dashboard_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mighty_fitness/screens/nutrition_analysis_page.dart';
import 'package:mighty_fitness/screens/mental_preparation_list_screen.dart';
import 'package:mighty_fitness/screens/workout_list_screen.dart';
import 'package:mighty_fitness/screens/weekly_progress_screen.dart';

import '../components/double_back_to_close_app.dart';
import '../components/permission.dart';
import '../extensions/LiveStream.dart';
import '../extensions/colors.dart';
import '../extensions/constants.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/shared_pref.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../network/rest_api.dart';
import '../screens/diet_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';
import '../utils/app_images.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    init();
    LiveStream().on("LANGUAGE", (s) => setState(() {}));
  }

  void init() {
    // Theme system
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      if (getIntAsync(THEME_MODE_INDEX) == ThemeModeSystem) {
        appStore.setDarkMode(
          MediaQuery.of(context).platformBrightness == Brightness.light,
        );
      }
    };
    getSettingList();
    Permissions.activityPermissionsGranted();
  }

  Future<void> getSettingList() async {
    final value = await getSettingApi();
    userStore.setCurrencyCodeID(value.currencySetting!.symbol.validate());
    userStore.setCurrencyPositionID(value.currencySetting!.position.validate());
    userStore.setCurrencyCode(value.currencySetting!.code.validate());
    for (final setting in value.data!) {
      switch (setting.key) {
        case "terms_condition":
          userStore.setTermsCondition(setting.value.validate());
          break;
        case "privacy_policy":
          userStore.setPrivacyPolicy(setting.value.validate());
          break;
        case "ONESIGNAL_APP_ID":
          userStore.setOneSignalAppID(setting.value.validate());
          break;
        case "ONESIGNAL_REST_API_KEY":
          userStore.setOnesignalRestApiKey(setting.value.validate());
          break;
        case "ADMOB_BannerId":
          userStore.setAdmobBannerId(setting.value.validate());
          break;
        case "ADMOB_InterstitialId":
          userStore.setAdmobInterstitialId(setting.value.validate());
          break;
        case "ADMOB_BannerIdIos":
          userStore.setAdmobBannerIdIos(setting.value.validate());
          break;
        case "ADMOB_InterstitialIdIos":
          userStore.setAdmobInterstitialIdIos(setting.value.validate());
          break;
        case "CHATGPT_API_KEY":
          userStore.setChatGptApiKey(setting.value.validate());
          break;
        case "subscription_system":
          userStore.setSubscription(setting.value.toString());
          break;
      }
    }
    getSettingData();
  }

  @override
  void didChangeDependencies() {
    if (getIntAsync(THEME_MODE_INDEX) == ThemeModeSystem) {
      appStore.setDarkMode(
        MediaQuery.of(context).platformBrightness == Brightness.dark,
      );
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeScreen(
        // clic sur l'avatar : ouvre le profile en push
        onProfileTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
        },
        // Navigations vers les autres screens en mode push
        onWorkoutTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutListScreen()));
        },
        onDietTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DietScreen()));
        },
        onMentalTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MentalPreparationListScreen()));
        },
        onProgressTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => WeeklyProgressScreen()));
        },
      ),
    ];

    return Scaffold(
      body: DoubleBackToCloseApp(
        snackBar: SnackBar(
          elevation: 4,
          backgroundColor: appStore.isDarkMode ? cardDarkColor : primaryOpacity,
          content: Text('Appuyez à nouveau pour quitter', style: primaryTextStyle()),
        ),
        child: tabs[0], // Affiche seulement l'accueil
      ),
    );
  }
}
