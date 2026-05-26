import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BearHeadShape extends CustomPainter {
  final Color color;
  final Color? borderColor;
  final double borderWidth;

  BearHeadShape({
    required this.color,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = _getBearPath(size);
    canvas.drawPath(path, paint);

    if (borderWidth > 0 && borderColor != null) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawPath(path, borderPaint);
    }
  }

  Path _getBearPath(Size size) {
    final headRadius = size.width * 0.38;
    final earRadius = size.width * 0.16;
    
    // Centering the whole shape (head + ears)
    // The ears stick out above the head, so we shift the center down slightly
    // to make the visual center of the whole bear head align with the widget center.
    final center = Offset(size.width / 2, size.height * 0.54);

    final headPath = Path()
      ..addOval(Rect.fromCircle(
        center: center,
        radius: headRadius,
      ));

    final leftEarPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx - headRadius * 0.7, center.dy - headRadius * 0.75),
        radius: earRadius,
      ));

    final rightEarPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx + headRadius * 0.7, center.dy - headRadius * 0.75),
        radius: earRadius,
      ));

    // Combine paths to create a single silhouette
    // This prevents border lines from showing inside the ears
    var combinedPath = Path.combine(PathOperation.union, headPath, leftEarPath);
    combinedPath = Path.combine(PathOperation.union, combinedPath, rightEarPath);
    
    return combinedPath;
  }

  @override
  bool shouldRepaint(covariant BearHeadShape oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.borderColor != borderColor || 
           oldDelegate.borderWidth != borderWidth;
  }
}

class LevelNode extends StatelessWidget {
  final int levelNumber;
  final int stars;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isActive;
  final bool isBoss;
  final VoidCallback onTap;

  const LevelNode({
    super.key,
    required this.levelNumber,
    required this.stars,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isActive,
    required this.isBoss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = isBoss ? 120.0 : 90.0;
    
    Color nodeColor;
    if (!isUnlocked) {
      nodeColor = AppColors.muted;
    } else if (isActive) {
      nodeColor = AppColors.primary;
    } else if (isCompleted) {
      nodeColor = AppColors.secondary;
    } else {
      nodeColor = AppColors.primaryLight;
    }

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isActive)
                  _PulseAnimation(
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: BearHeadShape(
                        color: nodeColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                if (isBoss && isCompleted)
                  _SparkleDecoration(
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: BearHeadShape(
                        color: nodeColor,
                        borderColor: Colors.white,
                        borderWidth: 4,
                      ),
                    ),
                  )
                else
                  CustomPaint(
                    size: Size(size, size),
                    painter: BearHeadShape(
                      color: nodeColor,
                      borderColor: isActive ? Colors.white : null,
                      borderWidth: isActive ? 4 : 0,
                    ),
                  ),
                _buildIcon(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (!isBoss)
            Text(
              'Level $levelNumber',
              style: AppTextStyles.bodyBold.copyWith(
                color: isUnlocked ? AppColors.foreground : AppColors.mutedText,
              ),
            ),
          if (!isBoss) _buildStars(),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (isBoss) {
      return const Icon(
        Icons.emoji_events_rounded,
        size: 48,
        color: Colors.white,
      );
    }
    if (!isUnlocked) {
      return const Icon(
        Icons.lock_rounded,
        size: 32,
        color: AppColors.mutedText,
      );
    }
    if (isCompleted) {
      return const Icon(
        Icons.check_rounded,
        size: 40,
        color: Colors.white,
      );
    }
    return const Icon(
      Icons.play_arrow_rounded,
      size: 48,
      color: Colors.white,
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Icon(
          index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 20,
          color: index < stars ? AppColors.star : AppColors.border,
        );
      }),
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;
  const _PulseAnimation({required this.child});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

class _SparkleDecoration extends StatefulWidget {
  final Widget child;
  const _SparkleDecoration({required this.child});

  @override
  State<_SparkleDecoration> createState() => _SparkleDecorationState();
}

class _SparkleDecorationState extends State<_SparkleDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        RotationTransition(
          turns: _controller,
          child: const Icon(
            Icons.brightness_7_rounded,
            size: 130,
            color: Color(0x33FFCC33),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class PathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  PathPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      
      // Control points for curvy S-shape
      final cp1 = Offset(p0.dx, p0.dy + (p1.dy - p0.dy) / 2);
      final cp2 = Offset(p1.dx, p1.dy - (p1.dy - p0.dy) / 2);
      
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    // Draw dashed path
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 8.0;
    double distance = 0.0;
    
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0; // Reset for next metric if any
    }
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) => true;
}

class ChapterDivider extends StatelessWidget {
  final String title;
  const ChapterDivider({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.whiteTitle.copyWith(
            color: AppColors.secondaryText,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class LevelWindingPath extends StatelessWidget {
  final Map<String, int> starMap;
  final String subjectId;
  final String? childId;
  final void Function(String levelId, bool isBoss) onLevelTap;

  const LevelWindingPath({
    super.key,
    required this.starMap,
    required this.subjectId,
    required this.onLevelTap,
    this.childId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centerX = width / 2;
        final horizontalOffset = width * 0.22;
        const verticalStep = 160.0;

        final List<Offset> points = [];
        final List<Widget> nodes = [];

        int visualIndex = 0;
        for (int i = 0; i < 8; i++) {
          final levelId = 'l${i + 1}';
          final stars = starMap[levelId] ?? 0;
          bool isUnlocked = i == 0 || (starMap['l$i'] ?? 0) > 0;
          bool isCompleted = stars > 0;
          bool isActive = isUnlocked && !isCompleted;
          bool isBoss = i == 4;

          // Calculate position for visual layout (excluding dividers for path)
          double x;
          int pattern = visualIndex % 4;
          if (pattern == 0) x = centerX;
          else if (pattern == 1) x = centerX + horizontalOffset;
          else if (pattern == 2) x = centerX;
          else x = centerX - horizontalOffset;

          final y = visualIndex * verticalStep + 80.0;
          points.add(Offset(x, y));

          nodes.add(
            Positioned(
              left: x - (isBoss ? 60 : 45),
              top: y - (isBoss ? 60 : 45),
              child: LevelNode(
                levelNumber: i + 1,
                stars: stars,
                isUnlocked: isUnlocked,
                isCompleted: isCompleted,
                isActive: isActive,
                isBoss: isBoss,
                onTap: () => onLevelTap(levelId, isBoss),
              ),
            ),
          );

          visualIndex++;
          
          // Add Chapter Divider after Boss (Level 5 / Index 4)
          if (i == 4) {
            // We need to shift the next nodes down to accommodate the divider
            // But for simplicity in a Stack, we'll just add the divider as a widget
            nodes.add(
              Positioned(
                left: 0,
                right: 0,
                top: visualIndex * verticalStep + 20,
                child: const ChapterDivider(title: 'Chapter 2'),
              ),
            );
            visualIndex++; // Increment visual index to skip space for divider
          }
        }

        return SizedBox(
          height: visualIndex * verticalStep + 100,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(width, visualIndex * verticalStep),
                painter: PathPainter(
                  points: points,
                  color: AppColors.primary,
                ),
              ),
              ...nodes,
            ],
          ),
        );
      },
    );
  }
}
