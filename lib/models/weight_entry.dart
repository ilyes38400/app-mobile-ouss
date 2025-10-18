class WeightEntry {
  final int id;
  final double weight;
  final DateTime date;

  WeightEntry({
    required this.id,
    required this.weight,
    required this.date,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    id: json['id'],
    weight: double.parse(json['weight'].toString()),
    date: DateTime.parse(json['date']),
  );

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'date': date.toIso8601String(),
  };
}
