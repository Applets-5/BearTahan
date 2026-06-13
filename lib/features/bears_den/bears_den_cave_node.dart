import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class BearsDenCaveNode extends StatefulWidget {
  const BearsDenCaveNode({super.key, required this.onTap, this.stars = 0});

  final VoidCallback onTap;
  final int stars;

  @override
  State<BearsDenCaveNode> createState() => _BearsDenCaveNodeState();
}

class _BearsDenCaveNodeState extends State<BearsDenCaveNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 1,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: AppRadius.r(AppRadius.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            height: 106,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: _glow,
                  child: Container(
                    width: 96,
                    height: 82,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66F59E0B),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(112, 96),
                  painter: const _GoldenCavePainter(),
                ),
                const Positioned(
                  top: 42,
                  child: Icon(
                    Icons.pets_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                Positioned(
                  right: -2,
                  top: 0,
                  child: Transform.rotate(
                    angle: 0.12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.destructive,
                        borderRadius: AppRadius.r(AppRadius.sm),
                        boxShadow: AppShadows.card,
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Text("Bear's Den", style: AppTextStyles.bodyBold),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(2, (index) {
              return Icon(
                index < widget.stars
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 20,
                color: index < widget.stars ? AppColors.star : AppColors.border,
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: AppRadius.r(AppRadius.lg),
            ),
            child: const Text(
              'Chapter Mix',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldenCavePainter extends CustomPainter {
  const _GoldenCavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cave = Path()
      ..moveTo(size.width * 0.08, size.height * 0.92)
      ..lineTo(size.width * 0.08, size.height * 0.54)
      ..quadraticBezierTo(
        size.width * 0.1,
        size.height * 0.08,
        size.width * 0.5,
        size.height * 0.05,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.08,
        size.width * 0.92,
        size.height * 0.54,
      )
      ..lineTo(size.width * 0.92, size.height * 0.92)
      ..close();

    canvas.drawPath(
      cave,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      cave,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final entrance = Path()
      ..moveTo(size.width * 0.27, size.height * 0.92)
      ..lineTo(size.width * 0.27, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.29,
        size.height * 0.4,
        size.width * 0.5,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.71,
        size.height * 0.4,
        size.width * 0.73,
        size.height * 0.68,
      )
      ..lineTo(size.width * 0.73, size.height * 0.92)
      ..close();

    canvas.drawPath(
      entrance,
      Paint()
        ..color = const Color(0xFF92400E)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _GoldenCavePainter oldDelegate) => false;
}
