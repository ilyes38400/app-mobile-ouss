// lib/models/mental_preparation_response.dart

class MentalPreparation {
  final int id;
  final String title;
  final String slug;
  final String description; // HTML
  final String videoType;   // 'upload' ou 'external'
  final String videoUrl;    // URL YouTube ou URL directe MP4
  final String status;
  final String? imageUrl;   // ← nouvelle propriété

  // Nouvelles propriétés pour la logique payante
  final String? programType;
  final double? price;
  final bool? userHasAccess;
  final String? accessReason;
  final bool? requiresPurchase;
  final bool? requiresSubscription;

  MentalPreparation({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.videoType,
    required this.videoUrl,
    required this.status,
    this.imageUrl,
    this.programType,
    this.price,
    this.userHasAccess,
    this.accessReason,
    this.requiresPurchase,
    this.requiresSubscription,
  });

  factory MentalPreparation.fromJson(Map<String, dynamic> json) {
    print("🔍 DEBUG Mental fromJson: ${json['title']}");
    print("   - Raw JSON: $json");
    print("   - user_has_access: ${json['user_has_access']} (type: ${json['user_has_access'].runtimeType})");
    print("   - program_type: ${json['program_type']}");
    print("   - price: ${json['price']}");

    return MentalPreparation(
      id:          json['id'] as int,
      title:       json['title'] ?? '',
      slug:        json['slug'] ?? '',
      description: json['description'] ?? '',
      videoType:   json['video_type'] ?? '',
      videoUrl:    json['video_url'] ?? '',
      status:      json['status'] ?? '',
      imageUrl:    json['mental_image'] as String?,  // ← on prend mental_image selon le backend

      // Nouvelles propriétés
      programType: json['program_type'] as String?,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      userHasAccess: json['user_has_access'] as bool?,
      accessReason: json['access_reason'] as String?,
      requiresPurchase: json['requires_purchase'] as bool?,
      requiresSubscription: json['requires_subscription'] as bool?,
    );
  }
}

class MentalPreparationResponse {
  final List<MentalPreparation> data;

  MentalPreparationResponse({ required this.data });

  factory MentalPreparationResponse.fromJson(Map<String, dynamic> json) {
    // Le backend getList() retourne { "pagination": {...}, "data": [...] }
    // Donc on prend json['data'] directement
    final raw = json['data'];
    List<MentalPreparation> list;

    if (raw is List) {
      // C'est une liste d'objets (cas normal de getList)
      list = raw.map((e) => MentalPreparation.fromJson(e)).toList();
      print("🔍 DEBUG: ${list.length} programmes mentaux chargés");
      for (var item in list) {
        print("   - ${item.title} (type: ${item.programType}, access: ${item.userHasAccess})");
      }
    } else if (raw is Map<String, dynamic>) {
      // C'est un seul objet
      list = [MentalPreparation.fromJson(raw)];
    } else {
      print("❌ DEBUG: Format data inattendu: $raw");
      list = [];
    }

    return MentalPreparationResponse(data: list);
  }
}
