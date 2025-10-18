// lib/models/weekly_category.dart
class WeeklyCategoryPoint {
  final String week;         // ex: "2025-W33"
  final DateTime weekStart;  // ex: 2025-08-11 (lundi)
  /// Map<NomCategorie, moyenne>
  final Map<String, double> values;

  WeeklyCategoryPoint({
    required this.week,
    required this.weekStart,
    required this.values,
  });

  factory WeeklyCategoryPoint.fromJson(Map<String, dynamic> json) {
    final Map<String, double> vals = {};
    json.forEach((k, v) {
      if (k != 'week' && k != 'week_start') {
        final parsed = (v is num) ? v.toDouble() : double.tryParse('$v');
        if (parsed != null) {
          vals[k] = parsed;
        }
      }
    });

    return WeeklyCategoryPoint(
      week: (json['week'] ?? '').toString(),
      weekStart: DateTime.parse(json['week_start']),
      values: vals,
    );
  }
}

/// Petit helper pour connaître toutes les catégories présentes
class WeeklyCategoryDataset {
  final List<WeeklyCategoryPoint> points;
  final List<String> categories;

  WeeklyCategoryDataset(this.points, this.categories);

  factory WeeklyCategoryDataset.fromList(List<WeeklyCategoryPoint> pts) {
    final set = <String>{};
    for (final p in pts) {
      set.addAll(p.values.keys);
    }
    final cats = set.toList()..sort();
    return WeeklyCategoryDataset(pts, cats);
  }
}
