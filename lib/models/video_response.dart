class VideoMobileResponse {
  final String videoUrl;

  VideoMobileResponse({required this.videoUrl});

  factory VideoMobileResponse.fromJson(Map<String, dynamic> json) {
    // Supprimer les barres obliques inversées dans l'URL
    String videoUrl = json['videoUrl'];
    videoUrl = videoUrl.replaceAll(r'\/', ''); // Supprimer les barres obliques inversées
    print('video : '+ videoUrl);
    return VideoMobileResponse(
      videoUrl: videoUrl,
    );
  }
}
