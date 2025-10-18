class CompetitionFeedbackRequest {
  final String competitionName;
  final DateTime competitionDate;
  final int situationResponse; // 1 = Défi, 2 = Menace
  final int victoryResponse; // 1 = Recherche victoire, 2 = Évitement défaite
  final double difficultyLevel;
  final double motivation;
  final double focus;
  final double negativeFocus;
  final double mentalPresence;
  final String clearObjective;
  final double physicalSensations;
  final double emotionalStability;
  final double stressTension;
  final double decisionMaking;
  final double competitionEntry;
  final double maximumEffort;
  final double automaticity;
  final double idealSelfRating;
  final String? performanceComment;

  CompetitionFeedbackRequest({
    required this.competitionName,
    required this.competitionDate,
    required this.situationResponse,
    required this.victoryResponse,
    required this.difficultyLevel,
    required this.motivation,
    required this.focus,
    required this.negativeFocus,
    required this.mentalPresence,
    required this.clearObjective,
    required this.physicalSensations,
    required this.emotionalStability,
    required this.stressTension,
    required this.decisionMaking,
    required this.competitionEntry,
    required this.maximumEffort,
    required this.automaticity,
    required this.idealSelfRating,
    this.performanceComment,
  });

  Map<String, dynamic> toJson() {
    return {
      'competition_name': competitionName,
      'competition_date': competitionDate.toIso8601String(),
      'situation_response': situationResponse,
      'victory_response': victoryResponse,
      'difficulty_level': difficultyLevel,
      'motivation': motivation,
      'focus': focus,
      'negative_focus': negativeFocus,
      'mental_presence': mentalPresence,
      'clear_objective': clearObjective,
      'physical_sensations': physicalSensations,
      'emotional_stability': emotionalStability,
      'stress_tension': stressTension,
      'decision_making': decisionMaking,
      'competition_entry': competitionEntry,
      'maximum_effort': maximumEffort,
      'automaticity': automaticity,
      'ideal_self_rating': idealSelfRating,
      'performance_comment': performanceComment,
    };
  }

  factory CompetitionFeedbackRequest.fromJson(Map<String, dynamic> json) {
    return CompetitionFeedbackRequest(
      competitionName: json['competition_name'] ?? '',
      competitionDate: DateTime.parse(json['competition_date']),
      situationResponse: json['situation_response'] ?? 1,
      victoryResponse: json['victory_response'] ?? 1,
      difficultyLevel: (json['difficulty_level'] as num?)?.toDouble() ?? 5.0,
      motivation: (json['motivation'] as num?)?.toDouble() ?? 5.0,
      focus: (json['focus'] as num?)?.toDouble() ?? 5.0,
      negativeFocus: (json['negative_focus'] as num?)?.toDouble() ?? 5.0,
      mentalPresence: (json['mental_presence'] as num?)?.toDouble() ?? 5.0,
      clearObjective: json['clear_objective'] ?? '',
      physicalSensations: (json['physical_sensations'] as num?)?.toDouble() ?? 5.0,
      emotionalStability: (json['emotional_stability'] as num?)?.toDouble() ?? 5.0,
      stressTension: (json['stress_tension'] as num?)?.toDouble() ?? 5.0,
      decisionMaking: (json['decision_making'] as num?)?.toDouble() ?? 5.0,
      competitionEntry: (json['competition_entry'] as num?)?.toDouble() ?? 5.0,
      maximumEffort: (json['maximum_effort'] as num?)?.toDouble() ?? 5.0,
      automaticity: (json['automaticity'] as num?)?.toDouble() ?? 5.0,
      idealSelfRating: (json['ideal_self_rating'] as num?)?.toDouble() ?? 5.0,
      performanceComment: json['performance_comment'],
    );
  }
}

class CompetitionFeedbackResponse {
  final bool success;
  final String message;
  final CompetitionFeedbackData? data;

  CompetitionFeedbackResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CompetitionFeedbackResponse.fromJson(Map<String, dynamic> json) {
    return CompetitionFeedbackResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? CompetitionFeedbackData.fromJson(json['data'])
          : null,
    );
  }
}

class CompetitionFeedbackData {
  final int id;
  final String competitionName;
  final DateTime competitionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CompetitionFeedbackScores scores;

  CompetitionFeedbackData({
    required this.id,
    required this.competitionName,
    required this.competitionDate,
    required this.createdAt,
    required this.updatedAt,
    required this.scores,
  });

  factory CompetitionFeedbackData.fromJson(Map<String, dynamic> json) {
    return CompetitionFeedbackData(
      id: json['id'] ?? 0,
      competitionName: json['competition_name'] ?? '',
      competitionDate: DateTime.parse(json['competition_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      scores: CompetitionFeedbackScores.fromJson(json['scores'] ?? {}),
    );
  }
}

class CompetitionFeedbackScores {
  final int situationResponse;
  final int victoryResponse;
  final double difficultyLevel;
  final double motivation;
  final double focus;
  final double negativeFocus;
  final double mentalPresence;
  final String clearObjective;
  final double physicalSensations;
  final double emotionalStability;
  final double stressTension;
  final double decisionMaking;
  final double competitionEntry;
  final double maximumEffort;
  final double automaticity;
  final double idealSelfRating;
  final String? performanceComment;

  CompetitionFeedbackScores({
    required this.situationResponse,
    required this.victoryResponse,
    required this.difficultyLevel,
    required this.motivation,
    required this.focus,
    required this.negativeFocus,
    required this.mentalPresence,
    required this.clearObjective,
    required this.physicalSensations,
    required this.emotionalStability,
    required this.stressTension,
    required this.decisionMaking,
    required this.competitionEntry,
    required this.maximumEffort,
    required this.automaticity,
    required this.idealSelfRating,
    this.performanceComment,
  });

  factory CompetitionFeedbackScores.fromJson(Map<String, dynamic> json) {
    return CompetitionFeedbackScores(
      situationResponse: json['situation_response'] ?? 1,
      victoryResponse: json['victory_response'] ?? 1,
      difficultyLevel: (json['difficulty_level'] as num?)?.toDouble() ?? 5.0,
      motivation: (json['motivation'] as num?)?.toDouble() ?? 5.0,
      focus: (json['focus'] as num?)?.toDouble() ?? 5.0,
      negativeFocus: (json['negative_focus'] as num?)?.toDouble() ?? 5.0,
      mentalPresence: (json['mental_presence'] as num?)?.toDouble() ?? 5.0,
      clearObjective: json['clear_objective'] ?? '',
      physicalSensations: (json['physical_sensations'] as num?)?.toDouble() ?? 5.0,
      emotionalStability: (json['emotional_stability'] as num?)?.toDouble() ?? 5.0,
      stressTension: (json['stress_tension'] as num?)?.toDouble() ?? 5.0,
      decisionMaking: (json['decision_making'] as num?)?.toDouble() ?? 5.0,
      competitionEntry: (json['competition_entry'] as num?)?.toDouble() ?? 5.0,
      maximumEffort: (json['maximum_effort'] as num?)?.toDouble() ?? 5.0,
      automaticity: (json['automaticity'] as num?)?.toDouble() ?? 5.0,
      idealSelfRating: (json['ideal_self_rating'] as num?)?.toDouble() ?? 5.0,
      performanceComment: json['performance_comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'situation_response': situationResponse,
      'victory_response': victoryResponse,
      'difficulty_level': difficultyLevel,
      'motivation': motivation,
      'focus': focus,
      'negative_focus': negativeFocus,
      'mental_presence': mentalPresence,
      'clear_objective': clearObjective,
      'physical_sensations': physicalSensations,
      'emotional_stability': emotionalStability,
      'stress_tension': stressTension,
      'decision_making': decisionMaking,
      'competition_entry': competitionEntry,
      'maximum_effort': maximumEffort,
      'automaticity': automaticity,
      'ideal_self_rating': idealSelfRating,
      'performance_comment': performanceComment,
    };
  }
}

// Modèle pour la liste des questionnaires de retour de compétition
class CompetitionFeedbackListResponse {
  final List<CompetitionFeedbackData> data;
  final int total;
  final int currentPage;
  final int lastPage;

  CompetitionFeedbackListResponse({
    required this.data,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  factory CompetitionFeedbackListResponse.fromJson(Map<String, dynamic> json) {
    return CompetitionFeedbackListResponse(
      data: (json['data'] as List?)
          ?.map((e) => CompetitionFeedbackData.fromJson(e))
          .toList() ?? [],
      total: json['total'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
    );
  }
}