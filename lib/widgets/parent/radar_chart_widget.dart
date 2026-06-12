import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/subject_weakness_info.dart';

class SubjectRadarChart extends StatefulWidget {
  final Map<String, SubjectWeaknessInfo> subjectData;

  const SubjectRadarChart({super.key, required this.subjectData});

  @override
  State<SubjectRadarChart> createState() => _SubjectRadarChartState();
}

class _SubjectRadarChartState extends State<SubjectRadarChart> {
  int _touchedIndex = -1;
  Offset? _touchPosition;

  @override
  Widget build(BuildContext context) {
    final List<RadarEntry> childEntries = [
      RadarEntry(value: (widget.subjectData['bm']?.strengthScore ?? 0) * 100),
      RadarEntry(value: (widget.subjectData['bi']?.strengthScore ?? 0) * 100),
      RadarEntry(value: (widget.subjectData['math']?.strengthScore ?? 0) * 100),
      RadarEntry(value: (widget.subjectData['sci']?.strengthScore ?? 0) * 100),
      RadarEntry(value: (widget.subjectData['bc']?.strengthScore ?? 0) * 100),
    ];

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              radarTouchData: RadarTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, RadarTouchResponse? response) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSpot == null) {
                    setState(() {
                      _touchedIndex = -1;
                      _touchPosition = null;
                    });
                    return;
                  }
                  setState(() {
                    _touchedIndex = response.touchedSpot!.touchedRadarEntryIndex;
                    _touchPosition = event.localPosition;
                  });
                },
              ),
              dataSets: [
                _buildLayer(100, opacity: 0.04),
                _buildLayer(80, opacity: 0.06),
                _buildLayer(60, opacity: 0.08),
                _buildLayer(40, opacity: 0.10),
                _buildLayer(20, opacity: 0.15),
                RadarDataSet(
                  fillColor: AppColors.primary.withValues(alpha: 0.2),
                  borderColor: Colors.transparent,
                  entryRadius: 0,
                  dataEntries: childEntries,
                  borderWidth: 0,
                ),
                RadarDataSet(
                  fillColor: Colors.transparent,
                  borderColor: AppColors.primary,
                  entryRadius: 5.5,
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
                  case 0:
                    label = 'BM';
                    break;
                  case 1:
                    label = 'EN';
                    break;
                  case 2:
                    label = 'MATH';
                    break;
                  case 3:
                    label = 'SCI';
                    break;
                  case 4:
                    label = 'BC';
                    break;
                  default:
                    return const RadarChartTitle(text: '');
                }
                return RadarChartTitle(text: label, angle: 0);
              },
              tickCount: 5,
              ticksTextStyle: const TextStyle(color: Colors.transparent),
              tickBorderData: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 1.2,
              ),
              gridBorderData: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 1.2,
              ),
            ),
          ),
        ),
        if (_touchedIndex != -1 && _touchPosition != null)
          Positioned(
            left: _touchPosition!.dx,
            top: _touchPosition!.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -1.1),
              child: _buildTooltipOverlay(),
            ),
          ),
      ],
    );
  }

  Widget _buildTooltipOverlay() {
    String subjectId;
    switch (_touchedIndex) {
      case 0:
        subjectId = 'bm';
        break;
      case 1:
        subjectId = 'bi';
        break;
      case 2:
        subjectId = 'math';
        break;
      case 3:
        subjectId = 'sci';
        break;
      case 4:
        subjectId = 'bc';
        break;
      default:
        return const SizedBox();
    }

    final data = widget.subjectData[subjectId];
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.95),
        borderRadius: AppRadius.r(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.subjectName,
            style: AppTextStyles.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Strength: ${(data.strengthScore * 100).toStringAsFixed(0)}%',
            style: AppTextStyles.tiny.copyWith(color: Colors.white),
          ),
          Text(
            'Weakest: ${data.weakestChapter}',
            style: AppTextStyles.tiny.copyWith(color: Colors.white),
          ),
          Text(
            'Accuracy: ${data.accuracy.toStringAsFixed(0)}%',
            style: AppTextStyles.tiny.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  RadarDataSet _buildLayer(
    double value, {
    double opacity = 0,
    double borderAlpha = 0,
  }) {
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
