class GoalChallenge {
  final int id;
  final String title;
  final String description;

  GoalChallenge({required this.id,required this.title,required this.description});

  factory GoalChallenge.fromJson(Map<String,dynamic> json) => GoalChallenge(
    id: json['id'],
    title: json['title'],
    description: json['description'],
  );
}

class GoalChallengeResponse {
  final List<GoalChallenge> data;
  GoalChallengeResponse({required this.data});
  factory GoalChallengeResponse.fromJson(Map<String,dynamic> j)=> GoalChallengeResponse(
      data: List.from(j['data']).map((e)=>GoalChallenge.fromJson(e)).toList()
  );
}
