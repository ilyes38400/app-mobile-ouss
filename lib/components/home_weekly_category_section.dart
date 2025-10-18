import 'package:flutter/material.dart';
import '../models/weekly_category.dart';
import '../network/rest_api.dart';
import '../main.dart';
import 'weekly_category_chart.dart';

class HomeWeeklyCategorySection extends StatefulWidget {
  const HomeWeeklyCategorySection({super.key});

  @override
  State<HomeWeeklyCategorySection> createState() => _HomeWeeklyCategorySectionState();
}

class _HomeWeeklyCategorySectionState extends State<HomeWeeklyCategorySection> {
  bool _loading = true;
  String? _error;
  WeeklyCategoryDataset? _dataset;

  @override
  void initState() {
    super.initState();
    _waitForUserIdAndLoad();
  }

  Future<void> _waitForUserIdAndLoad() async {
    while (userStore.userId == 0) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final email = userStore.email;
      print("laaa");
      print(email);
      final list = await getWeeklyCategoryAveragesApi(email);
      final ds = WeeklyCategoryDataset.fromList(list);
      setState(() {
        _dataset = ds;
        _loading = false;
      });
    } catch (e) {
      print("🔍 HomeWeeklyCategorySection: Erreur API = $e");
      setState(() {
        _error = 'Erreur chargement hebdo: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🔍 HomeWeeklyCategorySection build: loading=$_loading, error=$_error, dataset=$_dataset, points=${_dataset?.points.length}");
    
    if (_loading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFE6F2FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      print("❌ HomeWeeklyCategorySection: erreur = $_error");
      return const SizedBox.shrink();
    }
    
    if (_dataset == null) {
      print("❌ HomeWeeklyCategorySection: dataset est null");
      return const SizedBox.shrink();
    }
    
    if (_dataset!.points.isEmpty) {
      print("❌ HomeWeeklyCategorySection: dataset.points est vide");
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Évolution bilan hebdomadaire",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text("Notes par semaines",
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 12),
          WeeklyCategoryChart(dataset: _dataset!),
        ],
      ),
    );
  }
}
