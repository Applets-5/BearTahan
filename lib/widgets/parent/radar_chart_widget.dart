import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SubjectRadarChart extends StatelessWidget {
  final Map<String, double> subjectScores;

  const SubjectRadarChart({super.key, required this.subjectScores});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.circle,
              radarTouchData: RadarTouchData(enabled: false),
              dataSets: [
                RadarDataSet(
                  fillColor: AppColors.primary.withValues(alpha: 0.2),
                  borderColor: AppColors.primary,
                  entryRadius: 4,
                  dataEntries: [
                    RadarEntry(value: subjectScores['bm'] ?? 0),
                    RadarEntry(value: subjectScores['bi'] ?? 0),
                    RadarEntry(value: subjectScores['math'] ?? 0),
                    RadarEntry(value: subjectScores['sci'] ?? 0),
                    RadarEntry(value: subjectScores['bc'] ?? 0),
                  ],
                  borderWidth: 2.5,
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.transparent),
              titlePositionPercentageOffset: 0.2,
              titleTextStyle: AppTextStyles.tiny.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.foreground,
              ),
              getTitle: (index, angle) {
                switch (index) {
                  case 0:
                    return const RadarChartTitle(text: 'BM');
                  case 1:
                    return const RadarChartTitle(text: 'EN');
                  case 2:
                    return const RadarChartTitle(text: 'MATH');
                  case 3:
                    return const RadarChartTitle(text: 'SCI');
                  case 4:
                    return const RadarChartTitle(text: 'BC');
                  default:
                    return const RadarChartTitle(text: '');
                }
              },
              tickCount: 4,
              ticksTextStyle: const TextStyle(color: Colors.transparent),
              gridBorderData: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(label: 'BM', color: AppColors.subjectBm),
        _LegendItem(label: 'English', color: AppColors.subjectEnglish),
        _LegendItem(label: 'Math', color: AppColors.subjectMath),
        _LegendItem(label: 'Science', color: AppColors.subjectScience),
        _LegendItem(label: 'Mandarin', color: AppColors.subjectMandarin),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.tiny),
      ],
    );
  }
}
