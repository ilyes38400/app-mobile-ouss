class WorkoutStatsResponse {
  final List<WorkoutTypeStat> data;

  WorkoutStatsResponse({required this.data});

  factory WorkoutStatsResponse.fromJson(Map<String, dynamic> json) {
    return WorkoutStatsResponse(
      data: (json['data'] as List)
          .map((item) => WorkoutTypeStat.fromJson(item))
          .toList(),
    );
  }
}

class WorkoutTypeStat {
  final int id;
  final String name;
  final int count;
  final String? color;

  WorkoutTypeStat({
    required this.id,
    required this.name,
    required this.count,
    this.color,
  });

  factory WorkoutTypeStat.fromJson(Map<String, dynamic> json) {
    return WorkoutTypeStat(
      id: json['id'],
      name: json['name'],
      count: json['count'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'count': count,
      'color': color,
    };
  }
}