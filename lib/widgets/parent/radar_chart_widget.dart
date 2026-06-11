import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SubjectRadarChart extends StatelessWidget {
  final Map<String, double> subjectScores;

  const SubjectRadarChart({
    super.key,
    required this.subjectScores,
  });

  @override
  Widget build(BuildContext context) {
    final List<RadarEntry> childEntries = [
      RadarEntry(value: subjectScores['bm'] ?? 0),
      RadarEntry(value: subjectScores['bi'] ?? 0),
      RadarEntry(value: subjectScores['math'] ?? 0),
      RadarEntry(value: subjectScores['sci'] ?? 0),
      RadarEntry(value: subjectScores['bc'] ?? 0),
    ];

    return AspectRatio(
      aspectRatio: 1.3,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          radarTouchData: RadarTouchData(enabled: false),
          dataSets: [
            // 1. Background Shading: 5 Layers stacked to create the "Darkest Inner" effect
            _buildLayer(100, opacity: 0.04),
            _buildLayer(80, opacity: 0.06),
            _buildLayer(60, opacity: 0.08),
            _buildLayer(40, opacity: 0.10),
            _buildLayer(20, opacity: 0.15), // Inner tier is darkest due to stacking
            
            // 2. Child Progress Fill: Drawn under the scale lines for visibility
            RadarDataSet(
              fillColor: AppColors.primary.withValues(alpha: 0.2),
              borderColor: Colors.transparent,
              entryRadius: 0,
              dataEntries: childEntries,
              borderWidth: 0,
            ),
            
            // 3. Polygonal Scale Rings: Drawn ON TOP of the fill to show "inside and outside"
            _buildLayer(100, borderAlpha: 0.12),
            _buildLayer(80, borderAlpha: 0.12),
            _buildLayer(60, borderAlpha: 0.12),
            _buildLayer(40, borderAlpha: 0.12),
            _buildLayer(20, borderAlpha: 0.12),

            // 4. Child Progress Outline & Progress Dots (The focal point)
            RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: AppColors.primary,
              entryRadius: 5.5, // Dots reflect child's progress
              dataEntries: childEntries,
              borderWidth: 3.5,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.transparent),
          
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: AppTextStyles.tiny.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.foreground,
            fontSize: 11,
          ),
          getTitle: (index, angle) {
            String label;
            switch (index) {
              case 0: label = 'BM'; break;
              case 1: label = 'EN'; break;
              case 2: label = 'MATH'; break;
              case 3: label = 'SCI'; break;
              case 4: label = 'BC'; break;
              default: return const RadarChartTitle(text: '');
            }
            return RadarChartTitle(
              text: label,
              angle: 0, // Keep all labels upright
            );
          },
          
          tickCount: 1, 
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          tickBorderData: const BorderSide(color: Colors.transparent),
          
          // Axis Lines (Center to Axis Labels)
          gridBorderData: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1.2,
          ),
        ),
      ),
    );
  }

  /// Helper to build a background tier layer with fill and/or border
  RadarDataSet _buildLayer(double value, {double opacity = 0, double borderAlpha = 0}) {
    return RadarDataSet(
      fillColor: AppColors.primary.withValues(alpha: opacity),
      borderColor: borderAlpha > 0 
          ? AppColors.primary.withValues(alpha: borderAlpha) 
          : Colors.transparent,
      entryRadius: 0,
      dataEntries: List.generate(5, (_) => RadarEntry(value: value)),
      borderWidth: borderAlpha > 0 ? 1.2 : 0,
    );
  }
}
