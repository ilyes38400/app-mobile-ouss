class GoalAchievementResponse {
  bool? success;
  String? message;
  GoalAchievementData? data;

  GoalAchievementResponse({this.success, this.message, this.data});

  GoalAchievementResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? GoalAchievementData.fromJson(json['data']) : null;
  }

  // Pour la compatibilité avec l'ancien code
  int? get achievementId => data?.id;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class GoalAchievementData {
  int? id;
  int? userId;
  int? goalChallengeId;
  String? goalType;
  String? achievedAt;
  String? notes;

  GoalAchievementData({
    this.id,
    this.userId,
    this.goalChallengeId,
    this.goalType,
    this.achievedAt,
    this.notes,
  });

  GoalAchievementData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    goalChallengeId = json['goal_challenge_id'];
    goalType = json['goal_type'];
    achievedAt = json['achieved_at'];
    notes = json['notes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['goal_challenge_id'] = this.goalChallengeId;
    data['goal_type'] = this.goalType;
    data['achieved_at'] = this.achievedAt;
    data['notes'] = this.notes;
    return data;
  }
}