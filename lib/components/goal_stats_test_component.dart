import 'package:flutter/material.dart';

class GoalStatsTestComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("📊 DEBUG: GoalStatsTestComponent build() appelé");
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text("🧪 Test Component", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Si vous voyez ceci, le problème n'est pas dans l'emplacement du widget"),
        ],
      ),
    );
  }
}