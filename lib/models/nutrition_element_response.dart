class NutritionElement {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String imageUrl;

  NutritionElement({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.imageUrl,
  });

  factory NutritionElement.fromJson(Map<String, dynamic> json) {
    return NutritionElement(
      id: json['id'],
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}

class NutritionElementResponse {
  final List<NutritionElement> data;

  NutritionElementResponse({ required this.data });

  factory NutritionElementResponse.fromJson(Map<String, dynamic> json) {
    return NutritionElementResponse(
      data: List<Map<String, dynamic>>.from(json['data'])
          .map((e) => NutritionElement.fromJson(e))
          .toList(),
    );
  }
}
