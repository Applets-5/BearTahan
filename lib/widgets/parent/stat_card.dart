import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const Color titleColor = Color(0xFF333333); // Dark Charcoal
    const Color subtitleColor = Color(0xFF666666); // Medium Slate Grey

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              // Dynamically calculate sizes based on width
              final iconSize = (availableWidth * 0.25).clamp(24.0, 48.0);
              final valueSize = (availableWidth * 0.15).clamp(14.0, 24.0);
              final labelSize = (availableWidth * 0.08).clamp(10.0, 14.0);

              return Padding(
                padding: EdgeInsets.all(availableWidth * 0.08),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: color, size: iconSize),
                        SizedBox(height: availableWidth * 0.02),
                        Text(
                          value,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: titleColor,
                            fontSize: valueSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          label,
                          style: AppTextStyles.tiny.copyWith(
                            color: subtitleColor,
                            fontSize: labelSize,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
