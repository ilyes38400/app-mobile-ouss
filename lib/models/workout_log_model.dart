class WorkoutType {
  final int id;
  final String title;

  WorkoutType({required this.id, required this.title});

  factory WorkoutType.fromJson(Map<String, dynamic> json) {
    return WorkoutType(
      id: json['id'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}

class WorkoutLogModel {
  final int? id;
  final DateTime date;
  final int workoutTypeId;
  final WorkoutType? workoutType;
  final String? intensityLevel;
  final int? durationMinutes;
  final bool? isManualEntry;
  final String? notes;

  WorkoutLogModel({
    this.id,
    required this.date,
    required this.workoutTypeId,
    this.workoutType,
    this.intensityLevel,
    this.durationMinutes,
    this.isManualEntry,
    this.notes,
  });

  factory WorkoutLogModel.fromJson(Map<String, dynamic> json) {
    return WorkoutLogModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      workoutTypeId: json['workout_type_id'],
      workoutType: json['workout_type'] != null 
          ? WorkoutType.fromJson(json['workout_type'])
          : null,
      intensityLevel: json['intensity_level'],
      durationMinutes: json['duration_minutes'],
      isManualEntry: json['is_manual_entry'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'workout_type_id': workoutTypeId,
      if (intensityLevel != null) 'intensity_level': intensityLevel,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (isManualEntry != null) 'is_manual_entry': isManualEntry,
      if (notes != null) 'notes': notes,
    };
  }
}

class WorkoutLogListResponse {
  final List<WorkoutLogModel> data;

  WorkoutLogListResponse({required this.data});

  factory WorkoutLogListResponse.fromJson(Map<String, dynamic> json) {
    return WorkoutLogListResponse(
      data: (json['data'] as List)
          .map((item) => WorkoutLogModel.fromJson(item))
          .toList(),
    );
  }
}
