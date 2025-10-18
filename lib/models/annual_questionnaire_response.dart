class AnnualQuestionnaireResponse {
  final String participantEmail;
  final String type;
  final String generatedAt;
  final AnnualRadarChart radarChart;

  AnnualQuestionnaireResponse({
    required this.participantEmail,
    required this.type,
    required this.generatedAt,
    required this.radarChart,
  });

  factory AnnualQuestionnaireResponse.fromJson(Map<String, dynamic> json) {
    return AnnualQuestionnaireResponse(
      participantEmail: json['participant_email'] ?? '',
      type: json['type'] ?? '',
      generatedAt: json['generated_at'] ?? '',
      radarChart: AnnualRadarChart.fromJson(json['radar_chart'] ?? {}),
    );
  }

  // Pour compatibilité avec le code existant
  List<AnnualCategoryResult> get data => radarChart.details;
}

class AnnualRadarChart {
  final List<String> categories;
  final List<double> scores;
  final List<AnnualCategoryResult> details;

  AnnualRadarChart({
    required this.categories,
    required this.scores,
    required this.details,
  });

  factory AnnualRadarChart.fromJson(Map<String, dynamic> json) {
    return AnnualRadarChart(
      categories: (json['categories'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      scores: (json['scores'] as List? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      details: (json['details'] as List? ?? [])
          .map((e) => AnnualCategoryResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AnnualCategoryResult {
  final String category;
  final double averageScore;
  final String positiveResponse;
  final String negativeResponse;
  final int totalResponses;
  final DateTime? firstResponse;
  final DateTime? lastResponse;

  AnnualCategoryResult({
    required this.category,
    required this.averageScore,
    required this.positiveResponse,
    required this.negativeResponse,
    required this.totalResponses,
    this.firstResponse,
    this.lastResponse,
  });

  factory AnnualCategoryResult.fromJson(Map<String, dynamic> json) {
    return AnnualCategoryResult(
      category: json['category'] as String,
      averageScore: (json['score'] as num).toDouble(),
      positiveResponse: json['positive_feedback'] as String? ?? '',
      negativeResponse: json['negative_feedback'] as String? ?? '',
      totalResponses: json['total_responses'] as int? ?? 0,
      firstResponse: null, // pas dans ta structure API
      lastResponse: json['last_response'] != null 
          ? DateTime.parse(json['last_response'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'average_score': averageScore,
    'positive_response': positiveResponse,
    'negative_response': negativeResponse,
    'total_responses': totalResponses,
    'first_response': firstResponse?.toIso8601String(),
    'last_response': lastResponse?.toIso8601String(),
  };
}