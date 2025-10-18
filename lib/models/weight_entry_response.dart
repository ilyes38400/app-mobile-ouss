import 'weight_entry.dart';

class WeightEntryResponse {
  final List<WeightEntry> data;

  WeightEntryResponse({required this.data});

  factory WeightEntryResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    List<WeightEntry> list;

    if (raw is List) {
      list = raw.map((e) => WeightEntry.fromJson(e)).toList();
    } else if (raw is Map<String, dynamic>) {
      list = [WeightEntry.fromJson(raw)];
    } else {
      list = [];
    }

    return WeightEntryResponse(data: list);
  }
}
