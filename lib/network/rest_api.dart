import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/models/category_result.dart';
import 'package:mighty_fitness/models/goal_challenge_response.dart';
import 'package:mighty_fitness/models/mental_preparation_response.dart';
import 'package:mighty_fitness/models/question_model.dart';
import 'package:mighty_fitness/models/weight_entry_response.dart';
import 'package:mighty_fitness/models/goal_stats_response.dart';
import 'package:mighty_fitness/models/annual_questionnaire_response.dart';
import 'package:mighty_fitness/models/program_purchase_models.dart';
import '../../models/category_diet_response.dart';
import '../../models/exercise_response.dart';
import '../../models/graph_response.dart';
import '../../models/level_response.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../extensions/shared_pref.dart';
import '../main.dart';
import '../models/home_information_model.dart';
import '../models/nutrition_element_response.dart';
import '../models/nutrition_photo_response.dart';
import '../models/payment_list_model.dart';
import '../models/app_configuration_response.dart';
import '../models/app_setting_response.dart';
import '../models/base_response.dart';
import '../models/blog_detail_response.dart';
import '../models/blog_response.dart';
import '../models/body_part_response.dart';
import '../models/dashboard_response.dart';
import '../models/day_exercise_response.dart';
import '../models/diet_response.dart';
import '../models/equipment_response.dart';
import '../models/exercise_detail_response.dart';
import '../models/get_setting_response.dart';
import '../models/login_response.dart';
import '../models/notification_response.dart';
import '../models/product_category_response.dart';
import '../models/product_response.dart';
import '../models/program_response.dart';
import '../models/social_login_response.dart';
import '../models/subscribePlan_response.dart';
import '../models/subscribe_package_response.dart';
import '../models/subscribe_response.dart';
import '../models/subscription_payment_intent.dart';
import '../models/subscription_response.dart';
import '../models/user_profile_response.dart';
import '../models/user_response.dart';
import '../models/verify_receipt_response.dart';
import '../models/video_response.dart';
import '../models/weekly_category.dart';
import '../models/workout_detail_response.dart';
import '../models/workout_log_model.dart';
import '../models/workout_response.dart';
import '../models/workout_type_response.dart';
import '../models/goal_achievement_response.dart';
import '../models/competition_feedback_model.dart';
import '../utils/app_config.dart';
import '../utils/app_constants.dart';
import 'network_utils.dart';

Future<LoginResponse> logInApi(request) async {
  Response response = await buildHttpResponse('login', request: request, method: HttpMethod.POST);
  if (!response.statusCode.isSuccessful()) {
    if (response.body.isJson()) {
      var json = jsonDecode(response.body);

      if (json.containsKey('code') && json['code'].toString().contains('invalid_username')) {
        throw 'invalid_username';
      }
    }
  }

  return await handleResponse(response).then((value) async {
    LoginResponse loginResponse = LoginResponse.fromJson(value);
    UserModel? userResponse = loginResponse.data;

    saveUserData(userResponse);
    await userStore.setLogin(true);
    return loginResponse;
  });
}

Future<void> saveUserData(UserModel? userModel) async {
  if (userModel!.apiToken.validate().isNotEmpty) await userStore.setToken(userModel.apiToken.validate());
  setValue(IS_SOCIAL, false);
  await userStore.setToken(userModel.apiToken.validate());
  await userStore.setUserID(userModel.id.validate());
  await userStore.setUserEmail(userModel.email.validate());
  await userStore.setFirstName(userModel.firstName.validate());
  await userStore.setLastName(userModel.lastName.validate());
  await userStore.setUsername(userModel.username.validate());
  await userStore.setUserImage(userModel.profileImage.validate());
  await userStore.setDisplayName(userModel.displayName.validate());
  await userStore.setPhoneNo(userModel.phoneNumber.validate());
  await userStore.setSubscribe(userModel.isSubscribe.validate());

}

Future<SocialLoginResponse> socialLogInApi(Map req) async {
  return SocialLoginResponse.fromJson(await handleResponse(await buildHttpResponse('social-mail-login', request: req, method: HttpMethod.POST)));
}

Future<SocialLoginResponse> socialOtpLogInApi(Map req) async {
  return SocialLoginResponse.fromJson(await handleResponse(await buildHttpResponse('social-otp-login', request: req, method: HttpMethod.POST)));
}

Future<FitnessBaseResponse> changePwdApi(Map req) async {
  return FitnessBaseResponse.fromJson(await handleResponse(await buildHttpResponse('change-password', request: req, method: HttpMethod.POST)));
}

Future<FitnessBaseResponse> forgotPwdApi(Map req) async {
  return FitnessBaseResponse.fromJson(await handleResponse(await buildHttpResponse('forget-password', request: req, method: HttpMethod.POST)));
}

Future<FitnessBaseResponse> deleteUserAccountApi() async {
  return FitnessBaseResponse.fromJson(await handleResponse(await buildHttpResponse('delete-user-account', method: HttpMethod.POST)));
}

Future<LoginResponse> registerApi(Map req) async {
  return LoginResponse.fromJson(await handleResponse(await buildHttpResponse('register', request: req, method: HttpMethod.POST)));
}

Future<LoginResponse> updateProfileApi(Map req) async {
  return LoginResponse.fromJson(await handleResponse(await buildHttpResponse('update-profile', request: req, method: HttpMethod.POST)));
}

Future<BodyPartResponse> getBodyPartApi(int? page) async {
  return BodyPartResponse.fromJson(await (handleResponse(await buildHttpResponse("bodypart-list?page=$page", method: HttpMethod.GET))));
}

Future<EquipmentResponse> getEquipmentListApi({int page = 1, int? mPerPage = EQUIPMENT_PER_PAGE}) async {
  return EquipmentResponse.fromJson(await (handleResponse(await buildHttpResponse("equipment-list?page=$page", method: HttpMethod.GET))));
}

Future<WorkoutResponse> getWorkoutListApi(bool? isFav, bool? isAssign, {int? page = 1, bool? isMonthlyProgram = false}) async {
  if (isAssign == true) {
    return WorkoutResponse.fromJson(await handleResponse(await buildHttpResponse('assign-workout-list?page=$page', method: HttpMethod.GET)));
  } else if (isMonthlyProgram == true) {
    return WorkoutResponse.fromJson(await handleResponse(await buildHttpResponse('workout-list?is_monthly_program=1&page=$page', method: HttpMethod.GET)));
  } else {
    if (isFav != true)
      return WorkoutResponse.fromJson(await (handleResponse(await buildHttpResponse("workout-list?page=$page", method: HttpMethod.GET))));
    else
      return WorkoutResponse.fromJson(await handleResponse(await buildHttpResponse('get-favourite-workout?page=$page', method: HttpMethod.GET)));
  }
}

Future<WorkoutTypeResponse> getWorkoutTypeListApi({int mPerPage = WORKOUT_TYPE_PAGE}) async {
  return WorkoutTypeResponse.fromJson(await (handleResponse(await buildHttpResponse("workouttype-list", method: HttpMethod.GET))));
}

Future<WorkoutResponse> getMonthlyProgramsApi({int? page = 1}) async {
  return WorkoutResponse.fromJson(await handleResponse(await buildHttpResponse('workout-monthly-programs?page=$page', method: HttpMethod.GET)));
}

Future<LevelResponse> getLevelListApi({int? page = 1, int mPerPage = LEVEL_PER_PAGE}) async {
  return LevelResponse.fromJson(await (handleResponse(await buildHttpResponse("level-list?page=$page", method: HttpMethod.GET))));
}

Future<BlogResponse> getBlogApi(String? isFeatured, {int? page = 1}) async {
  return BlogResponse.fromJson(await (handleResponse(await buildHttpResponse("post-list?is_featured=$isFeatured&page=$page", method: HttpMethod.GET))));
}

Future<BlogResponse> getSearchBlogApi({String? mSearch = ""}) async {
  return BlogResponse.fromJson(await (handleResponse(await buildHttpResponse("post-list?title=$mSearch", method: HttpMethod.GET))));
}

Future<BlogDetailResponse> getBlogDetailApi(Map req) async {
  return BlogDetailResponse.fromJson(await (handleResponse(await buildHttpResponse("post-detail", request: req, method: HttpMethod.POST))));
}

Future<DietResponse> getDietApi(String? isFeatured, bool? isCategory, {int? page = 1, bool? isAssign = false, bool? isFav = false, int? categoryId}) async {
  if (isFav == true) {
    return DietResponse.fromJson(await (handleResponse(await buildHttpResponse("get-favourite-diet?page=$page", method: HttpMethod.GET))));
  } else if (isAssign == true) {
    return DietResponse.fromJson(await (handleResponse(await buildHttpResponse("assign-diet-list?page=$page", method: HttpMethod.GET))));
  } else if (isCategory == true) {
    return DietResponse.fromJson(await (handleResponse(await buildHttpResponse("diet-list?categorydiet_id=$categoryId&page=$page", method: HttpMethod.GET))));
  } else {
    return DietResponse.fromJson(await (handleResponse(await buildHttpResponse("diet-list?is_featured=$isFeatured&page=$page", method: HttpMethod.GET))));
  }
}

Future<ProgramResponse> getPurchasedProgramsApi(int userId) async {
  return ProgramResponse.fromJson(
    await handleResponse(
      await buildHttpResponse(
        'programs?id=$userId"',
        method: HttpMethod.GET,
      ),
    ),
  );
}

Future<VideoMobileResponse> getVideoStreamUrl(String filename) async {
  return VideoMobileResponse.fromJson(
    await handleResponse(
      await buildHttpResponse(
        'getVideoUrl?filename=$filename',  // Assumes the route is something like 'video/{videoId}' to fetch the video stream
        method: HttpMethod.GET,
      ),
    ),
  );
}

Future<CategoryDietResponse> getDietCategoryApi({int page = 1}) async {
  return CategoryDietResponse.fromJson(await (handleResponse(await buildHttpResponse("categorydiet-list?page=$page", method: HttpMethod.GET))));
}

Future<DashboardResponse> getDashboardApi() async {
  return DashboardResponse.fromJson(await handleResponse(await buildHttpResponse('dashboard-detail', method: HttpMethod.GET)));
}



Future<ExerciseResponse> getExerciseApi({int? page, String? mSearchValue = " ", bool? isBodyPart = false, int? id, bool? isLevel = false, bool? isEquipment = false, var ids, bool? isFilter = false}) async {
  if (mSearchValue.isEmptyOrNull) {
    if (isBodyPart == true) {
      return ExerciseResponse.fromJson(await handleResponse(await buildHttpResponse('exercise-list?bodypart_id=$id&page=$page', method: HttpMethod.GET)));
    } else if (isEquipment == true) {
      return ExerciseResponse.fromJson(await handleResponse(await buildHttpResponse('exercise-list?equipment_id=${isFilter == true ? ids : id}&page=$page', method: HttpMethod.GET)));
    } else if (isLevel == true) {
      return ExerciseResponse.fromJson(await handleResponse(await buildHttpResponse('exercise-list?level_ids=${isFilter == true ? ids : id}&page=$page', method: HttpMethod.GET)));
    } else {
      return ExerciseResponse.fromJson(await handleResponse(await buildHttpResponse('exercise-list?page=$page', method: HttpMethod.GET)));
    }
  } else {
    if (isBodyPart == true) {
      return ExerciseResponse.fromJson(await handleResponse(await buildHttpResponse('exercise-list?bodypart_id=$id&title=$mSearchValue', method: HttpMethod.GET)));
    } else if (isEquipment == true) {
      return ExerciseResponse.fromJson(await handleResponse(await buildHttpResponse('exercise-list?equipment_id=${isFilter == true ? ids : id}&title=$mSearchValue', method: HttpMethod.GET)));
    } else if (isLevel == true) {
      return ExerciseResponse.fromJson(await handleResponse(await buildHttpResponse('exercise-list?level_ids=${isFilter == true ? ids : id}&title=$mSearchValue', method: HttpMethod.GET)));
    } else {
      return ExerciseResponse.fromJson(await handleResponse(await buildHttpResponse('exercise-list?title=$mSearchValue', method: HttpMethod.GET)));
    }
  }
}

Future<ExerciseDetailResponse> geExerciseDetailApi(int? id) async {
  return ExerciseDetailResponse.fromJson(await handleResponse(await buildHttpResponse('exercise-detail?id=$id', method: HttpMethod.GET)));
}

Future<FitnessBaseResponse> setDietFavApi(Map req) async {
  return FitnessBaseResponse.fromJson(await handleResponse(await buildHttpResponse('set-favourite-diet', request: req, method: HttpMethod.POST)));
}

Future<ProductCategoryResponse> getProductCategoryApi({int? page = 1}) async {
  return ProductCategoryResponse.fromJson(await (handleResponse(await buildHttpResponse("productcategory-list?page=$page", method: HttpMethod.GET))));
}

Future<ProductResponse> getProductApi({bool? isCategory = false, String? mSearch = "", int? productId, int? page = 1}) async {
  if (isCategory == true) {
    return ProductResponse.fromJson(await (handleResponse(await buildHttpResponse("product-list?productcategory_id=$productId", method: HttpMethod.GET))));
  } else {
    if (mSearch.isEmptyOrNull) {
      return ProductResponse.fromJson(await (handleResponse(await buildHttpResponse("product-list?page=$page", method: HttpMethod.GET))));
    } else {
      return ProductResponse.fromJson(await (handleResponse(await buildHttpResponse("product-list?title=$mSearch", method: HttpMethod.GET))));
    }
  }
}

Future<UserResponse> getUserDataApi({int? id}) async {
  return UserResponse.fromJson(await (handleResponse(await buildHttpResponse("user-detail?id=$id", method: HttpMethod.GET))));
}

Future<WorkoutDetailResponse> getWorkoutDetailApi(int? id) async {
  return WorkoutDetailResponse.fromJson(await (handleResponse(await buildHttpResponse("workout-detail?id=$id", method: HttpMethod.GET))));
}

Future<WorkoutDetailResponse> getWorkoutDetailWithAccessApi(int? id) async {
  return WorkoutDetailResponse.fromJson(await (handleResponse(await buildHttpResponse("workout-detail-with-access?id=$id", method: HttpMethod.GET))));
}

Future<WorkoutResponse> getWorkoutFilterListApi({int? page = 1, int? id, bool? isFilter, var ids, bool? isLevel = false, bool? isType}) async {
  if (isType == true) {
    return WorkoutResponse.fromJson(await handleResponse(await buildHttpResponse('workout-list?workout_type_id=${isFilter == true ? ids : id}', method: HttpMethod.GET)));
  } else if (isLevel == true) {
    return WorkoutResponse.fromJson(await handleResponse(await buildHttpResponse('workout-list?level_ids=${isFilter == true ? ids : id}', method: HttpMethod.GET)));
  } else {
    return WorkoutResponse.fromJson(await (handleResponse(await buildHttpResponse('workout-list?page=$page', method: HttpMethod.GET))));
  }
}

Future<DayExerciseResponse> getDayExerciseApi(int? id) async {
  return DayExerciseResponse.fromJson(await (handleResponse(await buildHttpResponse("workoutday-exercise-list?workout_day_id=$id", method: HttpMethod.GET))));
}

Future<FitnessBaseResponse> setWorkoutFavApi(Map req) async {
  return FitnessBaseResponse.fromJson(await handleResponse(await buildHttpResponse('set-favourite-workout', request: req, method: HttpMethod.POST)));
}

Future<DietResponse> getDietFavApi() async {
  return DietResponse.fromJson(await handleResponse(await buildHttpResponse('get-favourite-workout', method: HttpMethod.GET)));
}

Future<FitnessBaseResponse> setProgressApi(Map req) async {
  return FitnessBaseResponse.fromJson(await handleResponse(await buildHttpResponse('usergraph-save', request: req, method: HttpMethod.POST)));
}

Future<FitnessBaseResponse> deleteProgressApi(Map req) async {
  return FitnessBaseResponse.fromJson(await handleResponse(await buildHttpResponse('usergraph-delete', request: req, method: HttpMethod.POST)));
}

Future<GraphResponse> getProgressApi(String? type, {int? page = 1, String? isFilterType, bool? isFilter = false}) async {
  if (isFilter == true) {
    return GraphResponse.fromJson(await handleResponse(await buildHttpResponse('usergraph-list?type=$type&page=$page&duration=$isFilterType', method: HttpMethod.GET)));
  } else {
    return GraphResponse.fromJson(await handleResponse(await buildHttpResponse('usergraph-list?type=$type&page=$page', method: HttpMethod.GET)));
  }
}

Future<AppSettingResponse> getAppSettingApi() async {
  return AppSettingResponse.fromJson(await handleResponse(await buildHttpResponse('get-appsetting', method: HttpMethod.GET)));
}

Future<GetSettingResponse> getSettingApi() async {
  return GetSettingResponse.fromJson(await handleResponse(await buildHttpResponse('get-setting', method: HttpMethod.GET)));
}

// Start Dashboard region
Future<AppConfigurationResponse> getAppConfiguration() async {
  var it = await handleResponse(await buildHttpResponse('mightyblogger/api/v1/blogger/get-configuration', method: HttpMethod.GET));
  return AppConfigurationResponse.fromJson(it);
}

//subscription
Future<SubscriptionResponse> getSubscription() async {
  return SubscriptionResponse.fromJson(await (handleResponse(await buildHttpResponse("package-list", method: HttpMethod.GET))));
}

Future<SubscriptionPaymentIntentResponse> subscriptionPaymentIntentApi(Map req) async {
  return SubscriptionPaymentIntentResponse.fromJson(await handleResponse(await buildHttpResponse('create-subscription', request: req, method: HttpMethod.POST)));
}

Future<Map<String, dynamic>> createProgramPaymentIntentApi(Map<String, dynamic> req) async {
  print("🌐 DEBUG createProgramPaymentIntentApi:");
  print("   - Request data: $req");
  print("   - Endpoint: create-program-payment-intent");

  try {
    final response = await buildHttpResponse('create-program-payment-intent', request: req, method: HttpMethod.POST);
    print("🌐 DEBUG Raw HTTP Response: ${response.body}");
    final result = await handleResponse(response);
    print("🌐 DEBUG Parsed Response: $result");
    return result;
  } catch (e) {
    print("❌ DEBUG createProgramPaymentIntentApi Error: $e");
    rethrow;
  }
}

Future<Map<String, dynamic>> confirmProgramPurchaseApi(Map<String, dynamic> req) async {
  return await handleResponse(await buildHttpResponse('confirm-program-purchase', request: req, method: HttpMethod.POST));
}

Future<SubscribeResponse> subscribeApi(Map<String, dynamic> req) async {
  return SubscribeResponse.fromJson(await handleResponse(await buildHttpResponse('subscribe', request: req, method: HttpMethod.POST)));
}

Future<VerifyReceiptResponse> verifyAndCreateSubscriptionApi(Map<String, dynamic> req) async {
  return VerifyReceiptResponse.fromJson(
      await handleResponse(await buildHttpResponse('verifyAndCreateSubscription', request: req, method: HttpMethod.POST))
  );
}

Future<VerifyReceiptResponse> addTransactionIdUser(Map<String, dynamic> req) async {
  return VerifyReceiptResponse.fromJson(
      await handleResponse(await buildHttpResponse('addTransactionId', request: req, method: HttpMethod.POST))
  );
}

Future<UserProfileResponse> loadUserProfileApi() async {
  return UserProfileResponse.fromJson(
      await handleResponse(await buildHttpResponse('getUserSubscription', method: HttpMethod.GET))
  );
}


Future<SubscribePackageResponse> subscribePackageApi(Map req) async {
  return SubscribePackageResponse.fromJson(await handleResponse(await buildHttpResponse('subscribe-package', request: req, method: HttpMethod.POST)));
}

Future<SubscriptionPlanResponse> getSubScriptionPlanList({int page = 2}) async {
  return SubscriptionPlanResponse.fromJson(await (handleResponse(await buildHttpResponse("subscriptionplan-list?page=$page", method: HttpMethod.GET))));
}

Future<SubscribePackageResponse> cancelPlanApi(Map req) async {
  return SubscribePackageResponse.fromJson(await handleResponse(await buildHttpResponse('cancel-subscription', request: req, method: HttpMethod.POST)));
}

Future<PaymentListModel> getPaymentApi() async {
  return PaymentListModel.fromJson(await handleResponse(await buildHttpResponse('payment-gateway-list', method: HttpMethod.GET)));
}

Future<DietResponse> getSearchDietApi({String? mSearch = ""}) async {
  return DietResponse.fromJson(await (handleResponse(await buildHttpResponse("diet-list?title=$mSearch", method: HttpMethod.GET))));
}

Future<DietModel> getSearchDietListApi() async {
  return DietModel.fromJson(await (handleResponse(await buildHttpResponse("diet-list", method: HttpMethod.GET))));
}

Future<NotificationResponse> notificationApi() async {
  return NotificationResponse.fromJson(await handleResponse(await buildHttpResponse('notification-list', method: HttpMethod.POST)));
}

Future<NotificationResponse> notificationStatusApi(String? id) async {
  return NotificationResponse.fromJson(await handleResponse(await buildHttpResponse('notification-detail?id=$id', method: HttpMethod.GET)));
}

Future<NutritionPhotoResponse> sendNutritionPhotoApi(File imageFile) async {
  final data = await handleResponse(
    await buildHttpResponse(
      'nutrition-analysis',
      method: HttpMethod.POST,
      request: {'image': imageFile},
    ),
  );
  return NutritionPhotoResponse.fromJson(data as Map<String, dynamic>);
}

Future<NutritionElementResponse> getNutritionElementsApi() async {
  final res = await handleResponse(
    await buildHttpResponse("nutrition-elements", method: HttpMethod.GET),
  );
  return NutritionElementResponse.fromJson(res);
}

Future<NutritionElementResponse> getNutritionElementBySlugApi({
  required String slug,
}) async {
  final res = await handleResponse(
    await buildHttpResponse("nutrition-elements/$slug", method: HttpMethod.GET),
  );
  return NutritionElementResponse.fromJson(res);
}

Future<List<QuestionModel>> getQuestionnaireListApi() async {
  final uri  = Uri.parse('https://myfitnessapp.fr/api/questionnaire');
  final resp = await http.get(uri);
  if (resp.statusCode != 200) {
    throw Exception('Erreur HTTP ${resp.statusCode}');
  }
  final List raw = json.decode(resp.body) as List<dynamic>;
  return raw
      .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<CategoryResult>> submitQuestionnaireApi(Map<String, dynamic> req) async {
  final uri  = Uri.parse('https://myfitnessapp.fr/api/questionnaire/submit');
  final resp = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(req),
  );

  print('⚠️ STATUS: ${resp.statusCode}');
  print('⚠️ BODY: ${resp.body}');

  if (resp.statusCode != 200) {
    throw Exception('Erreur HTTP ${resp.statusCode}');
  }

  final List raw = json.decode(resp.body) as List<dynamic>;
  return raw
      .map((e) => CategoryResult.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<GoalChallengeResponse> getGoalChallengesApi({required String theme}) async {
  final res = await handleResponse(await buildHttpResponse("goal-challenges/$theme",method: HttpMethod.GET));
  return GoalChallengeResponse.fromJson(res);
}

Future<MentalPreparationResponse> getMentalPreparationsApi() async {
  final response = await buildHttpResponse(
    "mental-preparations", // endpoint Laravel
    method: HttpMethod.GET,
  );
  final res = await handleResponse(response);
  return MentalPreparationResponse.fromJson(res);
}

Future<MentalPreparationResponse> getMentalPreparationBySlugApi({
  required String slug,
}) async {
  final response = await buildHttpResponse(
    "mental-preparations/$slug",
    method: HttpMethod.GET,
  );
  final res = await handleResponse(response);
  return MentalPreparationResponse.fromJson(res);
}

Future<MentalPreparationResponse> getMentalPreparationDetailWithAccessApi(int id) async {
  final response = await buildHttpResponse(
    "mental-preparations-detail-with-access?id=$id",
    method: HttpMethod.GET,
  );
  final res = await handleResponse(response);
  return MentalPreparationResponse.fromJson(res);
}

Future<MentalPreparationResponse> getMentalPreparationDetailApi(int id) async {
  final response = await buildHttpResponse(
    "mental-preparations-detail?id=$id",
    method: HttpMethod.GET,
  );
  final res = await handleResponse(response);
  return MentalPreparationResponse.fromJson(res);
}

Future<HomeInformationModel> getHomeInformationApi() async {
  final response = await buildHttpResponse(
    "home-informations",
    method: HttpMethod.GET,
  );
  print('avant response');
  print(response.body);
  final json = await handleResponse(response);
  return HomeInformationModel.fromJson(json);
}

Future<FitnessBaseResponse> saveWorkoutLogApi({required int workoutTypeId, DateTime? date}) async {
  Map req = {
    "date": (date ?? DateTime.now()).toIso8601String().split('T')[0],
    "workout_type_id": workoutTypeId,
  };

  return FitnessBaseResponse.fromJson(await handleResponse(
    await buildHttpResponse('user-workout-logs', request: req, method: HttpMethod.POST),
  ));
}


Future<WorkoutLogListResponse> getWorkoutLogsApi() async {
  final response = await buildHttpResponse('user-workout-logs', method: HttpMethod.GET);
  final json = await handleResponse(response);

  return WorkoutLogListResponse.fromJson(json);
}

Future<WorkoutLogListResponse> getWeeklyWorkoutLogsApi({DateTime? date}) async {
  final targetDate = date ?? DateTime.now();
  final dateString = targetDate.toIso8601String().split('T')[0];
  
  final response = await buildHttpResponse('user-workout-logs/weekly?date=$dateString', method: HttpMethod.GET);
  final json = await handleResponse(response);

  return WorkoutLogListResponse.fromJson(json);
}

Future<FitnessBaseResponse> storeManualWorkoutLogApi({
  required DateTime date,
  required int workoutTypeId,
  required String intensityLevel,
  required int durationMinutes,
  String? notes,
}) async {
  Map<String, dynamic> req = {
    "date": date.toIso8601String().split('T')[0],
    "workout_type_id": workoutTypeId,
    "intensity_level": intensityLevel,
    "duration_minutes": durationMinutes,
  };

  if (notes != null && notes.isNotEmpty) {
    req["notes"] = notes;
  }

  return FitnessBaseResponse.fromJson(await handleResponse(
    await buildHttpResponse('user-workout-logs/manual', request: req, method: HttpMethod.POST),
  ));
}

Future<List<QuestionModel>> getQuestionnaireListByTypeApi(String type) async {
  final uri = Uri.parse('https://myfitnessapp.fr/api/questionnaire/type/$type');
  final resp = await http.get(uri);
  if (resp.statusCode != 200) {
    throw Exception('Erreur HTTP ${resp.statusCode}');
  }
  final List raw = json.decode(resp.body) as List<dynamic>;
  return raw
      .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<WeeklyCategoryPoint>> getWeeklyCategoryAveragesApi(String email) async {
  final uri = Uri.parse('https://myfitnessapp.fr/api/weekly-category-trends?email=$email');

  final resp = await http.get(uri);
  if (resp.statusCode != 200) {
    throw Exception('Erreur HTTP ${resp.statusCode}');
  }

  final body = json.decode(resp.body);
  if (body is! List) {
    return <WeeklyCategoryPoint>[];
  }

  return body
      .map<WeeklyCategoryPoint>((e) => WeeklyCategoryPoint.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

Future<WeightEntryResponse> getUserWeightsApi() async {
  final res = await handleResponse(
    await buildHttpResponse("user/weight-entries", method: HttpMethod.GET),
  );
  return WeightEntryResponse.fromJson(res);
}

Future<void> addUserWeightApi(double weight) async {
  await handleResponse(
    await buildHttpResponse("user/weight-entries", request: {
      'weight': weight,
    }, method: HttpMethod.POST),
  );
}

Future<void> updateIdealWeightApi(double ideal) async {
  await handleResponse(
    await buildHttpResponse("user/update-ideal-weight", request: {
      'ideal_weight': ideal,
    }, method: HttpMethod.POST),
  );
}

Future<GoalStatsResponse> getGoalAchievementStatsApi() async {

  final res = await handleResponse(
    await buildHttpResponse("goal-achievements/stats", method: HttpMethod.GET),
  );
  print(' la dans goal');
  print(res);
  return GoalStatsResponse.fromJson(res);
}

Future<GoalAchievementListResponse> getGoalAchievementsApi({String? goalType, String? period}) async {
  String endpoint = "goal-achievements";
  List<String> queryParams = [];
  
  if (goalType != null && goalType.isNotEmpty) {
    queryParams.add("goal_type=$goalType");
  }
  if (period != null && period.isNotEmpty) {
    queryParams.add("period=$period");
  }
  
  if (queryParams.isNotEmpty) {
    endpoint += "?" + queryParams.join("&");
  }
  
  final res = await handleResponse(
    await buildHttpResponse(endpoint, method: HttpMethod.GET),
  );
  return GoalAchievementListResponse.fromJson(res);
}

Future<GoalAchievementResponse> markGoalAsAchievedApi({required int goalChallengeId, String? notes}) async {
  Map<String, dynamic> req = {
    "goal_challenge_id": goalChallengeId,
  };
  
  if (notes != null && notes.isNotEmpty) {
    req["notes"] = notes;
  }
  
  return GoalAchievementResponse.fromJson(await handleResponse(
    await buildHttpResponse('goal-achievements', request: req, method: HttpMethod.POST),
  ));
}

Future<FitnessBaseResponse> deleteGoalAchievementApi(int achievementId) async {
  return FitnessBaseResponse.fromJson(await handleResponse(
    await buildHttpResponse('goal-achievements/$achievementId', method: HttpMethod.DELETE),
  ));
}

Future<FitnessBaseResponse> removeGoalAchievementApi({required int goalChallengeId}) async {
  return FitnessBaseResponse.fromJson(await handleResponse(
    await buildHttpResponse('goal-achievements/by-goal/$goalChallengeId', method: HttpMethod.DELETE),
  ));
}

Future<AnnualQuestionnaireResponse> getAnnualQuestionnaireResultsApi(String email) async {
  final uri = Uri.parse('https://myfitnessapp.fr/api/annual-radar-chart?email=$email');
  final resp = await http.get(uri);

  if (resp.statusCode != 200) {
    throw Exception('Erreur HTTP ${resp.statusCode}');
  }

  final Map<String, dynamic> body = json.decode(resp.body) as Map<String, dynamic>;
  return AnnualQuestionnaireResponse.fromJson(body);
}

// Nouvelles API pour les programmes payants

/// Acheter un programme
Future<ProgramPurchaseResponse> purchaseProgramApi(ProgramPurchaseRequest request) async {
  final res = await handleResponse(
    await buildHttpResponse(
      'purchase-program',
      request: request.toJson(),
      method: HttpMethod.POST,
    ),
  );
  return ProgramPurchaseResponse.fromJson(res);
}

/// Vérifier l'accès à un programme
Future<ProgramAccessCheckResponse> checkProgramAccessApi(ProgramAccessCheckRequest request) async {
  final res = await handleResponse(
    await buildHttpResponse(
      'check-program-access',
      request: request.toJson(),
      method: HttpMethod.POST,
    ),
  );
  return ProgramAccessCheckResponse.fromJson(res);
}

/// Récupérer les programmes achetés par l'utilisateur
Future<UserPurchasedProgramsResponse> getUserPurchasedProgramsApi(int userId) async {
  final res = await handleResponse(
    await buildHttpResponse(
      'my-purchased-programs?user_id=$userId',
      method: HttpMethod.GET,
    ),
  );
  return UserPurchasedProgramsResponse.fromJson(res);
}

/// Récupérer la liste des workouts avec la nouvelle logique d'accès
Future<WorkoutResponse> getWorkoutListWithAccessApi(bool? isFav, bool? isAssign, {int? page = 1, bool? isMonthlyProgram = false}) async {
  String endpoint = 'workout-list';

  if (isAssign == true) {
    endpoint = 'assign-workout-list';
  } else if (isMonthlyProgram == true) {
    endpoint = 'workout-list?is_monthly_program=1';
  } else if (isFav == true) {
    endpoint = 'get-favourite-workout';
  }

  endpoint += (endpoint.contains('?') ? '&' : '?') + 'page=$page';

  return WorkoutResponse.fromJson(
    await handleResponse(
      await buildHttpResponse(endpoint, method: HttpMethod.GET),
    ),
  );
}

/// Récupérer la liste des préparations mentales avec la nouvelle logique d'accès
Future<MentalPreparationResponse> getMentalPreparationsWithAccessApi() async {
  // TODO: Quand le backend sera prêt, changer vers "mental-preparations-list-with-access"
  // Pour l'instant, utiliser l'ancien endpoint qui fonctionne
  final response = await buildHttpResponse(
    "mental-preparations-list",
    method: HttpMethod.GET,
  );
  final res = await handleResponse(response);
  return MentalPreparationResponse.fromJson(res);
}

/// Vérifier l'accès à un programme mental spécifique
Future<Map<String, dynamic>> checkMentalProgramAccessApi(int programId) async {
  final Map<String, dynamic> requestBody = {
    'program_id': programId,
    'program_type': 'mental',
  };

  return await handleResponse(
    await buildHttpResponse(
      'check-program-access',
      request: requestBody,
      method: HttpMethod.POST,
    ),
  );
}

/// Acheter un programme mental
Future<Map<String, dynamic>> purchaseMentalProgramApi(int programId) async {
  final Map<String, dynamic> requestBody = {
    'program_id': programId,
    'program_type': 'mental',
  };

  return await handleResponse(
    await buildHttpResponse(
      'purchase-program',
      request: requestBody,
      method: HttpMethod.POST,
    ),
  );
}

// ==================== Competition Feedback API ====================

/// Créer un questionnaire de retour de compétition
Future<CompetitionFeedbackResponse> submitCompetitionFeedbackApi(CompetitionFeedbackRequest request) async {
  final response = await buildHttpResponse(
    'competition-feedback',
    request: request.toJson(),
    method: HttpMethod.POST,
  );

  return CompetitionFeedbackResponse.fromJson(
    await handleResponse(response),
  );
}

/// Récupérer la liste des questionnaires de retour de compétition
Future<CompetitionFeedbackListResponse> getCompetitionFeedbackListApi({int page = 1}) async {
  final response = await buildHttpResponse(
    'competition-feedback?page=$page',
    method: HttpMethod.GET,
  );

  return CompetitionFeedbackListResponse.fromJson(
    await handleResponse(response),
  );
}

/// Récupérer un questionnaire de retour de compétition spécifique
Future<CompetitionFeedbackResponse> getCompetitionFeedbackApi(int id) async {
  final response = await buildHttpResponse(
    'competition-feedback/$id',
    method: HttpMethod.GET,
  );

  return CompetitionFeedbackResponse.fromJson(
    await handleResponse(response),
  );
}

/// Modifier un questionnaire de retour de compétition
Future<CompetitionFeedbackResponse> updateCompetitionFeedbackApi(int id, CompetitionFeedbackRequest request) async {
  final response = await buildHttpResponse(
    'competition-feedback/$id',
    request: request.toJson(),
    method: HttpMethod.PUT,
  );

  return CompetitionFeedbackResponse.fromJson(
    await handleResponse(response),
  );
}

/// Supprimer un questionnaire de retour de compétition
Future<Map<String, dynamic>> deleteCompetitionFeedbackApi(int id) async {
  final response = await buildHttpResponse(
    'competition-feedback/$id',
    method: HttpMethod.DELETE,
  );

  return await handleResponse(response);
}