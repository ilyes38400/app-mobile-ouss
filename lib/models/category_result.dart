class CategoryResult {
  final String category;
  final double averageScore;
  final String positiveResponse;
  final String negativeResponse;

  CategoryResult({
    required this.category,
    required this.averageScore,
    required this.positiveResponse,
    required this.negativeResponse,
  });

  factory CategoryResult.fromJson(Map<String, dynamic> json) {
    return CategoryResult(
      category: json['category'] as String,
      averageScore: (json['average_score'] as num).toDouble(),
      positiveResponse: json['positive_response'] as String,
      negativeResponse: json['negative_response'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'average_score': averageScore,
    'positive_response': positiveResponse,
    'negative_response': negativeResponse,
  };
}
