class QuestionModel {
  final int id;
  final String question;
  final int categoryId;

  QuestionModel({
    required this.id,
    required this.question,
    required this.categoryId,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int,
      question: json['question'] as String,
      categoryId: json['category_id'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'category_id': categoryId,
  };
}
