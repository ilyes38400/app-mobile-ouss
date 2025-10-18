import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/annual_questionnaire_response.dart';
import '../utils/app_colors.dart';

class StarDiagramComponent extends StatelessWidget {
  final List<AnnualCategoryResult> data;
  final double size;

  const StarDiagramComponent({
    Key? key,
    required this.data,
    this.size = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        width: size,
        height: size,
        child: Center(
          child: Text(
            'Aucune donnée disponible',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: primaryColor.withOpacity(0.2),
              borderColor: primaryColor,
              entryRadius: 3,
              borderWidth: 2,
              dataEntries: data.map((category) {
                return RadarEntry(value: category.averageScore);
              }).toList(),
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          getTitle: (index, angle) {
            if (index >= 0 && index < data.length) {
              return RadarChartTitle(
                text: _formatCategoryName(data[index].category),
                angle: 0,
              );
            }
            return RadarChartTitle(text: '');
          },
          tickCount: 5,
          ticksTextStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
          tickBorderData: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
    );
  }

  String _formatCategoryName(String category) {
    if (category.length > 12) {
      return '${category.substring(0, 10)}...';
    }
    return category;
  }
}

class AnnualReportDialog extends StatelessWidget {
  final List<AnnualCategoryResult> data;

  const AnnualReportDialog({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bilan Annuel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),
            StarDiagramComponent(
              data: data,
              size: 280,
            ),
            SizedBox(height: 20),
            Container(
              height: 200,
              child: SingleChildScrollView(
                child: Column(
                  children: data.map((category) {
                    return _buildCategoryCard(category);
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                'Fermer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(AnnualCategoryResult category) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category.category,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(category.averageScore),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.averageScore.toStringAsFixed(1)}/10',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return Colors.red;
  }
}