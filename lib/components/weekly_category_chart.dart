import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/weekly_category.dart';

class WeeklyCategoryChart extends StatelessWidget {
  final WeeklyCategoryDataset dataset;

  const WeeklyCategoryChart({super.key, required this.dataset});

  /// Couleurs fixes par catégorie
  static const List<Color> kFixedColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
  ];

  String _ddmm(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _weekTooltip(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return 'Semaine du ${_ddmm(start)}/${start.year} au ${_ddmm(end)}/${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (dataset.points.isEmpty || dataset.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final weekStarts = dataset.points.map((p) => p.weekStart).toList();

    // Courbes: 1 par catégorie
    final lines = <LineChartBarData>[];
    for (var i = 0; i < dataset.categories.length; i++) {
      final cat = dataset.categories[i];
      final spots = <FlSpot>[];
      for (var x = 0; x < dataset.points.length; x++) {
        final p = dataset.points[x];
        final y = p.values[cat];
        if (y != null) spots.add(FlSpot(x.toDouble(), y));
      }
      if (spots.isEmpty) continue;

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          color: kFixedColors[i % kFixedColors.length],
          dotData: FlDotData(show: true),
        ),
      );
    }

    const double minY = 1.0;
    const double maxY = 5.0;
    const double yInterval = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (dataset.points.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: yInterval,
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 34,
                    showTitles: true,
                    interval: yInterval,
                    getTitlesWidget: (value, _) =>
                        Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 11)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= weekStarts.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _ddmm(weekStarts[idx]), // ✅ format jj/MM
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((ts) {
                      final idx = ts.x.toInt();
                      final start =
                      (idx >= 0 && idx < weekStarts.length) ? weekStarts[idx] : null;
                      final cat = (ts.barIndex >= 0 && ts.barIndex < dataset.categories.length)
                          ? dataset.categories[ts.barIndex]
                          : '';
                      final header = start != null ? _weekTooltip(start) : '';
                      return LineTooltipItem(
                        '$cat\n$header : ${ts.y.toStringAsFixed(2)}',
                        const TextStyle(fontWeight: FontWeight.w600),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: lines,
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(dataset.categories.length, (i) {
            return _LegendDot(
              label: dataset.categories[i],
              color: kFixedColors[i % kFixedColors.length],
            );
          }),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
