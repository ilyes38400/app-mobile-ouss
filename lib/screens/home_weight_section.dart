import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../models/weight_entry.dart';
import '../../components/weight_progress_chart.dart';
import '../../components/add_weight_dialog.dart';
import '../network/rest_api.dart';

class HomeWeightSection extends StatefulWidget {
  const HomeWeightSection({super.key});

  @override
  State<HomeWeightSection> createState() => _HomeWeightSectionState();
}

enum WeightPeriod { oneMonth, threeMonths, sixMonths, oneYear }

class _HomeWeightSectionState extends State<HomeWeightSection> {
  List<WeightEntry> _history = [];
  WeightPeriod _selectedPeriod = WeightPeriod.oneMonth;

  int _getPeriodInDays(WeightPeriod period) {
    switch (period) {
      case WeightPeriod.oneMonth:
        return 30;
      case WeightPeriod.threeMonths:
        return 90;
      case WeightPeriod.sixMonths:
        return 180;
      case WeightPeriod.oneYear:
        return 365;
    }
  }

  @override
  void initState() {
    super.initState();
    _waitForUserIdAndLoad();
  }

  Future<void> _waitForUserIdAndLoad() async {
    while (userStore.userId == 0) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await _loadHistory();
  }

  Future<void> _showEditIdealWeightDialog() async {
    final ctrl = TextEditingController(text: userStore.idealWeight.trim());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le poids idéal"),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: "Ex : 65.0"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newIdeal = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (newIdeal == null) return;

              try {
                await updateIdealWeightApi(newIdeal);
                userStore.setIdealWeight(newIdeal.toString()); // si MobX ou autre observable
                setState(() {}); // met à jour l’affichage du graphique
                Navigator.pop(context);
              } catch (e) {
                print("Erreur mise à jour poids idéal : $e");
                Navigator.pop(context);
              }
            },
            child: const Text("Sauvegarder"),
          ),
        ],
      ),
    );
  }

  List<WeightEntry> _getFilteredHistory() {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_selectedPeriod) {
      case WeightPeriod.oneMonth:
        cutoffDate = now.subtract(Duration(days: 30));
        break;
      case WeightPeriod.threeMonths:
        cutoffDate = now.subtract(Duration(days: 90));
        break;
      case WeightPeriod.sixMonths:
        cutoffDate = now.subtract(Duration(days: 180));
        break;
      case WeightPeriod.oneYear:
        cutoffDate = now.subtract(Duration(days: 365));
        break;
    }

    return _history.where((entry) => entry.date.isAfter(cutoffDate)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  String _getPeriodLabel(WeightPeriod period) {
    switch (period) {
      case WeightPeriod.oneMonth:
        return '1M';
      case WeightPeriod.threeMonths:
        return '3M';
      case WeightPeriod.sixMonths:
        return '6M';
      case WeightPeriod.oneYear:
        return '1A';
    }
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: WeightPeriod.values.map((period) {
          final isSelected = period == _selectedPeriod;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
              ),
              child: Text(
                _getPeriodLabel(period),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _loadHistory() async {
    try {
      final response = await getUserWeightsApi();
      setState(() {
        _history = response.data
          ..sort((a, b) => a.date.compareTo(b.date));
      });
    } catch (e) {
      print("Erreur chargement poids : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ideal = double.tryParse(userStore.idealWeight.trim()) ?? 70.0;

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
        children: [
          _buildPeriodSelector(),
          WeightProgressChart(
            history: _getFilteredHistory(),
            ideal: ideal,
            periodInDays: _getPeriodInDays(_selectedPeriod),
            onAddWeight: () async {
              await showAddWeightDialog(context, _loadHistory);
            },
            onEditIdeal: _showEditIdealWeightDialog,
          ),
        ],
      ),
    );
  }
}
