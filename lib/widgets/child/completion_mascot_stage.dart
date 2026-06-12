import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/mascot_widget.dart';

class CompletionMascotStage extends StatefulWidget {
  const CompletionMascotStage({
    super.key,
    required this.childId,
    required this.passed,
    required this.stars,
  });

  final String? childId;
  final bool passed;
  final int stars;

  @override
  State<CompletionMascotStage> createState() => _CompletionMascotStageState();
}

class _CompletionMascotStageState extends State<CompletionMascotStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  String _successBubbleText() {
    switch (widget.stars) {
      case 1:
        return 'Good job! Keep going!';
      case 2:
        return 'Great work!';
      case 3:
        return 'Amazing! You did your best!';
      default:
        return 'Well done! Keep it up!';
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passed = widget.passed;

    const double mascotLeft = 64;
    const double bubbleLeft = mascotLeft + 40;

    return SizedBox(
      width: 260,
      height: 210,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (passed) ...[
                Positioned(
                  left: 22,
                  top: 72 - (value * 4),
                  child: const _SparkleEffect(size: 24, opacity: 0.90),
                ),
                Positioned(
                  left: 36,
                  top: 118 + (value * 3),
                  child: const _SparkleEffect(size: 18, opacity: 0.78),
                ),
                Positioned(
                  right: 22,
                  top: 72 + (value * 4),
                  child: const _SparkleEffect(size: 24, opacity: 0.90),
                ),
                Positioned(
                  right: 36,
                  top: 118 - (value * 3),
                  child: const _SparkleEffect(size: 18, opacity: 0.78),
                ),
                Positioned(
                  left: bubbleLeft,
                  top: 0,
                  child: Transform.scale(
                    scale: 1 + (value * 0.04),
                    child: _MascotSpeechBubble(
                      text: _successBubbleText(),
                      success: true,
                    ),
                  ),
                ),
              ] else ...[
                Positioned(
                  left: bubbleLeft,
                  top: 2,
                  child: Transform.translate(
                    offset: Offset(0, value * 4),
                    child: const _MascotSpeechBubble(
                      text: 'Keep trying, you’re learning!',
                      success: false,
                    ),
                  ),
                ),
              ],
              Positioned(
                left: mascotLeft,
                bottom: 0,
                child: ActiveMascotWidget(
                  childId: widget.childId,
                  size: passed ? 132 : 120,
                  showBackground: false,
                  mood: passed ? MascotMood.celebrating : MascotMood.crying,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SparkleEffect extends StatelessWidget {
  const _SparkleEffect({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Text(
        '✨',
        style: TextStyle(fontSize: size, color: AppColors.star),
      ),
    );
  }
}

class _MascotSpeechBubble extends StatelessWidget {
  const _MascotSpeechBubble({required this.text, required this.success});

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final fillColor = success
        ? const Color(0xFFFFF7D6)
        : AppColors.destructiveLight;

    final borderColor = success
        ? AppColors.star.withValues(alpha: 0.75)
        : AppColors.destructive.withValues(alpha: 0.45);

    final textColor = success ? AppColors.foreground : AppColors.destructive;

    return CustomPaint(
      painter: _CuteDialogBubblePainter(
        fillColor: fillColor,
        borderColor: borderColor,
      ),
      child: Container(
        width: 185,
        height: 82,
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: Text(
          text,
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CuteDialogBubblePainter extends CustomPainter {
  const _CuteDialogBubblePainter({
    required this.fillColor,
    required this.borderColor,
  });

  final Color fillColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    path.addOval(Rect.fromLTWH(6, 4, size.width - 12, size.height - 22));

    final tailPath = Path()
      ..moveTo(72, size.height - 26)
      ..lineTo(48, size.height - 2)
      ..lineTo(54, size.height - 34)
      ..close();

    final fullPath = Path.combine(PathOperation.union, path, tailPath);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fullPath, fillPaint);
    canvas.drawPath(fullPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CuteDialogBubblePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
