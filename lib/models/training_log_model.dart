class TrainingLogRequest {
  final String discipline;
  final String dominance; // mental, physique, technique, tactique
  final String duration; // 15min, 30min, 45min, 1h, 1h15, 1h30, 1h45, 2h, 2h15, 2h30, 2h45, 3h
  final double intensity; // 0-10
  final double ifp; // 0-10 (Indice de Fatigue Physique)
  final double engagement; // 0-10
  final double focus; // 0-10
  final double stress; // 0-10
  final String? comment;
  final bool productive; // oui/non

  TrainingLogRequest({
    required this.discipline,
    required this.dominance,
    required this.duration,
    required this.intensity,
    required this.ifp,
    required this.engagement,
    required this.focus,
    required this.stress,
    this.comment,
    required this.productive,
  });

  Map<String, dynamic> toJson() {
    return {
      'discipline': discipline,
      'dominance': dominance,
      'duration': duration,
      'intensity': intensity,
      'ifp': ifp,
      'engagement': engagement,
      'focus': focus,
      'stress': stress,
      'comment': comment,
      'productive': productive,
    };
  }

  factory TrainingLogRequest.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse numeric values from string or number
    double _parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    return TrainingLogRequest(
      discipline: json['discipline']?.toString() ?? '',
      dominance: json['dominance']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      intensity: _parseDouble(json['intensity'], 5.0),
      ifp: _parseDouble(json['ifp'], 5.0),
      engagement: _parseDouble(json['engagement'], 5.0),
      focus: _parseDouble(json['focus'], 5.0),
      stress: _parseDouble(json['stress'], 5.0),
      comment: json['comment']?.toString(),
      productive: json['productive'] == true || json['productive'] == 1 || json['productive']?.toString().toLowerCase() == 'true',
    );
  }
}

class TrainingLogResponse {
  final bool success;
  final String message;
  final TrainingLogData? data;

  TrainingLogResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory TrainingLogResponse.fromJson(Map<String, dynamic> json) {
    return TrainingLogResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? TrainingLogData.fromJson(json['data'])
          : null,
    );
  }
}

class TrainingLogData {
  final int id;
  final String discipline;
  final String dominance;
  final String duration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TrainingLogScores scores;

  TrainingLogData({
    required this.id,
    required this.discipline,
    required this.dominance,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
    required this.scores,
  });

  factory TrainingLogData.fromJson(Map<String, dynamic> json) {
    return TrainingLogData(
      id: json['id'] ?? 0,
      discipline: json['discipline'] ?? '',
      dominance: json['dominance'] ?? '',
      duration: json['duration'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      scores: TrainingLogScores.fromJson(json['scores'] ?? {}),
    );
  }
}

class TrainingLogScores {
  final double intensity;
  final double ifp;
  final double engagement;
  final double focus;
  final double stress;
  final String? comment;
  final bool productive;

  TrainingLogScores({
    required this.intensity,
    required this.ifp,
    required this.engagement,
    required this.focus,
    required this.stress,
    this.comment,
    required this.productive,
  });

  factory TrainingLogScores.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse numeric values from string or number
    double _parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    return TrainingLogScores(
      intensity: _parseDouble(json['intensity'], 5.0),
      ifp: _parseDouble(json['ifp'], 5.0),
      engagement: _parseDouble(json['engagement'], 5.0),
      focus: _parseDouble(json['focus'], 5.0),
      stress: _parseDouble(json['stress'], 5.0),
      comment: json['comment']?.toString(),
      productive: json['productive'] == true || json['productive'] == 1 || json['productive']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intensity': intensity,
      'ifp': ifp,
      'engagement': engagement,
      'focus': focus,
      'stress': stress,
      'comment': comment,
      'productive': productive,
    };
  }
}

// Modèle pour la liste des carnets d'entraînement
class TrainingLogListResponse {
  final List<TrainingLogData> data;
  final int total;
  final int currentPage;
  final int lastPage;

  TrainingLogListResponse({
    required this.data,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  factory TrainingLogListResponse.fromJson(Map<String, dynamic> json) {
    return TrainingLogListResponse(
      data: (json['data'] as List?)
          ?.map((e) => TrainingLogData.fromJson(e))
          .toList() ?? [],
      total: json['total'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
    );
  }
}

// Constantes pour les options de sélection
class TrainingLogOptions {
  static const List<String> dominances = [
    'mental',
    'physique',
    'technique',
    'tactique',
  ];

  static const List<String> durations = [
    '15min',
    '30min',
    '45min',
    '1h',
    '1h15',
    '1h30',
    '1h45',
    '2h',
    '2h15',
    '2h30',
    '2h45',
    '3h',
  ];

  static String getDominanceLabel(String dominance) {
    switch (dominance) {
      case 'mental':
        return 'Mental';
      case 'physique':
        return 'Physique';
      case 'technique':
        return 'Technique';
      case 'tactique':
        return 'Tactique';
      default:
        return dominance;
    }
  }

  static String getDurationLabel(String duration) {
    return duration;
  }
}