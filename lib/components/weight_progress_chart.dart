import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/weight_entry.dart';

class WeightProgressChart extends StatelessWidget {
  final List<WeightEntry> history;
  final double ideal;
  final VoidCallback onAddWeight;
  final VoidCallback onEditIdeal;
  final int periodInDays;

  const WeightProgressChart({
    super.key,
    required this.history,
    required this.ideal,
    required this.onAddWeight,
    required this.onEditIdeal,
    this.periodInDays = 30,
  });


  String _formatDateLabel(DateTime date) {
    // Format unique "jj/mm" pour tous les affichages
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return "$day/$month";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double? currentWeight = double.tryParse(userStore.weight);

    // Construire un historique même vide, mais avec le poids initial
    final fullHistory = <WeightEntry>[
      if (currentWeight != null)
        WeightEntry(
          id: -1,
          date: DateTime.now().subtract(const Duration(days: 1)),
          weight: currentWeight,
        ),
      ...history
    ];

    final lastDate = fullHistory.last.date;
    final futureDates = List.generate(2, (i) => lastDate.add(Duration(days: 7 * (i + 1))));

    final allDates = [...fullHistory.map((e) => e.date), ...futureDates];
    final spots = fullHistory.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final allWeights = fullHistory.map((e) => e.weight).toList() + [ideal];
    final minWeight = allWeights.reduce((a, b) => a < b ? a : b);
    final maxWeight = allWeights.reduce((a, b) => a > b ? a : b);

    final minY = (minWeight - 10).clamp(0, double.infinity).toDouble();
    final maxY = (maxWeight + 10).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Suivi de poids",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onEditIdeal,
                    icon: const Icon(Icons.edit, color: Colors.black54),
                    tooltip: "Modifier le poids idéal",
                  ),
                  IconButton(
                    onPressed: onAddWeight,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: (allDates.length - 1).toDouble(),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) =>
                          Text("${value.toInt()}", style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= allDates.length) return const SizedBox();
                        
                        // 4 positions équidistantes visuellement sur l'axe
                        final totalLength = allDates.length - 1;
                        final positions = [0.0, totalLength * 0.33, totalLength * 0.66, totalLength.toDouble()];
                        
                        // Vérifier si l'index actuel correspond à une des positions
                        for (double position in positions) {
                          if (index == position.round()) {
                            // Calculer une date artificielle basée sur la période
                            final now = DateTime.now();
                            final daysSinceStart = (periodInDays * (position / totalLength)).round();
                            final displayDate = now.subtract(Duration(days: periodInDays - daysSinceStart));
                            
                            return Text(
                              _formatDateLabel(displayDate),
                              style: const TextStyle(fontSize: 11),
                            );
                          }
                        }
                        
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: spots,
                    barWidth: 3,
                    color: theme.primaryColor,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withOpacity(0.3),
                          Colors.transparent
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  )
                ],
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: ideal,
                    color: Colors.green,
                    strokeWidth: 2.5,
                    dashArray: [8, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      labelResolver: (_) => "Poids idéal",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
