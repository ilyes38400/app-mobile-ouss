class GoalTypeStats {
  final int physique;
  final int alimentaire;
  final int mental;

  GoalTypeStats({
    required this.physique,
    required this.alimentaire,
    required this.mental,
  });

  factory GoalTypeStats.fromJson(Map<String, dynamic> json) {
    print("🔍 DEBUG: GoalTypeStats.fromJson reçu: $json");

    try {
      return GoalTypeStats(
        physique: json['physique'] ?? 0,
        alimentaire: json['alimentaire'] ?? 0,
        mental: json['mental'] ?? 0,
      );
    } catch (e) {
      print("❌ ERROR: Erreur dans GoalTypeStats.fromJson: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'physique': physique,
      'alimentaire': alimentaire,
      'mental': mental,
    };
  }
}

class GoalStatsData {
  final int totalAchievements;
  final int thisMonth;
  final int thisYear;
  final GoalTypeStats byType;
  final GoalTypeStats byTypeThisMonth;

  GoalStatsData({
    required this.totalAchievements,
    required this.thisMonth,
    required this.thisYear,
    required this.byType,
    required this.byTypeThisMonth,
  });

  factory GoalStatsData.fromJson(Map<String, dynamic> json) {
    print("🔍 DEBUG: GoalStatsData.fromJson reçu: $json");

    try {
      return GoalStatsData(
        totalAchievements: json['total_achievements'] ?? 0,
        thisMonth: json['this_month'] ?? 0,
        thisYear: json['this_year'] ?? 0,
        byType: GoalTypeStats.fromJson(json['by_type'] ?? {}),
        byTypeThisMonth: GoalTypeStats.fromJson(json['by_type_this_month'] ?? {}),
      );
    } catch (e) {
      print("❌ ERROR: Erreur dans GoalStatsData.fromJson: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'total_achievements': totalAchievements,
      'this_month': thisMonth,
      'this_year': thisYear,
      'by_type': byType.toJson(),
      'by_type_this_month': byTypeThisMonth.toJson(),
    };
  }
}

class GoalStatsResponse {
  final bool success;
  final GoalStatsData? data;
  final String? message;

  GoalStatsResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory GoalStatsResponse.fromJson(Map<String, dynamic> json) {
    print("🔍 DEBUG: GoalStatsResponse.fromJson reçu: $json");

    try {
      return GoalStatsResponse(
        success: json['success'] ?? false,
        message: json['message'],
        data: json['data'] != null ? GoalStatsData.fromJson(json['data']) : null,
      );
    } catch (e) {
      print("❌ ERROR: Erreur dans GoalStatsResponse.fromJson: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class GoalAchievement {
  final int id;
  final int userId;
  final int goalChallengeId;
  final String goalType;
  final String achievedAt;
  final String? notes;

  GoalAchievement({
    required this.id,
    required this.userId,
    required this.goalChallengeId,
    required this.goalType,
    required this.achievedAt,
    this.notes,
  });

  factory GoalAchievement.fromJson(Map<String, dynamic> json) {
    return GoalAchievement(
      id: json['id'],
      userId: json['user_id'],
      goalChallengeId: json['goal_challenge_id'],
      goalType: json['goal_type'],
      achievedAt: json['achieved_at'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_challenge_id': goalChallengeId,
      'goal_type': goalType,
      'achieved_at': achievedAt,
      'notes': notes,
    };
  }
}

class GoalAchievementListResponse {
  final bool success;
  final List<GoalAchievement>? data;
  final String? message;

  GoalAchievementListResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory GoalAchievementListResponse.fromJson(Map<String, dynamic> json) {
    try {
      List<GoalAchievement>? achievements;

      if (json['data'] != null) {
        final List<dynamic> dataList = json['data'] is List
            ? json['data']
            : (json['data']['data'] ?? []);
        achievements = dataList.map((item) => GoalAchievement.fromJson(item)).toList();
      }

      return GoalAchievementListResponse(
        success: json['success'] ?? false,
        message: json['message'],
        data: achievements,
      );
    } catch (e) {
      print("❌ ERROR: Erreur dans GoalAchievementListResponse.fromJson: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((item) => item.toJson()).toList(),
    };
  }
}