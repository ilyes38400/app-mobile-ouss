class ProgramResponse {
  final List<Program> programs;

  ProgramResponse({required this.programs});

  factory ProgramResponse.fromJson(Map<String, dynamic> json) {
    print('ici');
    print(json['data']);
    return ProgramResponse(
      programs: (json['data'] as List)
          .map((e) => Program.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Program {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final List<FileInfo> files; // Changer en List<FileInfo>
  final String? videoUrl;

  Program({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.files,
    this.videoUrl,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      files: (json['files'] as List<dynamic>)
          .map((file) => FileInfo.fromJson(file as Map<String, dynamic>))
          .toList(), // Transformer la liste en objets FileInfo
      videoUrl: json['video_url'],
    );
  }
}

class FileInfo {
  final String filename;
  final String url;

  FileInfo({
    required this.filename,
    required this.url,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
