// lib/models/home_information_model.dart

class HomeInformationModel {
  final int id;
  final String title;
  final String videoUrl;

  HomeInformationModel({
    required this.id,
    required this.title,
    required this.videoUrl,
  });

  factory HomeInformationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {}; // Récupération du champ "data" de la réponse
    return HomeInformationModel(
      id: data['id'] ?? 0,
      title: data['title'] ?? '',
      videoUrl: data['video_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'video_url': videoUrl,
    };
  }
}
