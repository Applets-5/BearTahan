import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/outfit_quest.dart';
import '../../theme/app_theme.dart';
import '../common/mascot_widget.dart';

class LuckyDrawDialog extends StatefulWidget {
  const LuckyDrawDialog({
    super.key,
    required this.quest,
    required this.onEquipNow,
  });

  final OutfitQuest quest;
  final VoidCallback onEquipNow;

  @override
  State<LuckyDrawDialog> createState() => _LuckyDrawDialogState();
}

class _LuckyDrawDialogState extends State<LuckyDrawDialog>
    with TickerProviderStateMixin {
  late final AnimationController _coinController;
  late final AnimationController _spinController;
  late final AnimationController _shakeController;
  late final AnimationController _handleController;
  late final AnimationController _ballOutController;
  late final AnimationController _openBallController;
  late final AnimationController _sparkleController;

  late final Animation<double> _coinMove;
  late final Animation<double> _shakeMove;
  late final Animation<double> _handleTurn;
  late final Animation<double> _ballScale;
  late final Animation<double> _openScale;

  int _stage = 0;
  bool _showDoorBall = false;

  /*
    stage 0 = waiting for coin drag
    stage 1 = coin inserted, waiting for spin
    stage 2 = spinning
    stage 3 = big yellow ball screen
    stage 4 = reward opened
  */

  @override
  void initState() {
    super.initState();

    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _handleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _ballOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _openBallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _coinMove = CurvedAnimation(
      parent: _coinController,
      curve: Curves.easeInOutBack,
    );

    _shakeMove =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    _handleTurn = Tween<double>(begin: 0, end: 0.55).animate(
      CurvedAnimation(parent: _handleController, curve: Curves.easeInOutBack),
    );

    _ballScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _ballOutController, curve: Curves.elasticOut),
    );

    _openScale = Tween<double>(begin: 0.35, end: 1.2).animate(
      CurvedAnimation(parent: _openBallController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _coinController.dispose();
    _spinController.dispose();
    _shakeController.dispose();
    _handleController.dispose();
    _ballOutController.dispose();
    _openBallController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Future<void> _insertCoin() async {
    if (_stage != 0) return;

    await _coinController.forward(from: 0);

    if (!mounted) return;

    setState(() {
      _stage = 1;
    });
  }

  Future<void> _spinMachine() async {
    if (_stage != 1) return;

    setState(() {
      _stage = 2;
    });

    await Future.wait([
      _spinController.forward(from: 0),
      _shakeController.forward(from: 0),
      _handleController.forward(from: 0),
    ]);

    if (!mounted) return;

    // Ball comes out from the machine door first.
    setState(() {
      _stage = 3;
      _showDoorBall = true;
    });

    await _ballOutController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;

    // Automatically switch to big yellow ball screen.
    setState(() {
      _showDoorBall = false;
    });
  }

  Future<void> _openBall() async {
    if (_stage != 3) return;

    await _openBallController.forward(from: 0);

    if (!mounted) return;

    setState(() {
      _stage = 4;
    });

    await _sparkleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isMachineStage = _stage <= 2 || _showDoorBall;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: isMachineStage
                  ? AnimatedBuilder(
                      key: const ValueKey('machine'),
                      animation: Listenable.merge([
                        _coinController,
                        _spinController,
                        _shakeController,
                        _handleController,
                        _ballOutController,
                      ]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeMove.value, 0),
                          child: _LuckyMachineWidget(
                            coinMoveValue: _coinMove.value,
                            spinValue: _spinController.value,
                            handleValue: _handleTurn.value,
                            ballOutValue: _ballOutController.value,
                            stage: _stage,
                            onCoinTap: _insertCoin,
                            onSpinTap: _spinMachine,
                          ),
                        );
                      },
                    )
                  : _BallRewardScene(
                      key: const ValueKey('ballReward'),
                      stage: _stage,
                      ballScale: _ballScale.value,
                      openScale: _openScale.value,
                      sparkleValue: _sparkleController.value,
                      quest: widget.quest,
                      onBallTap: _openBall,
                      onDoneTap: widget.onEquipNow,
                    ),
            ),
          ),

          Positioned(
            right: 18,
            top: 18,
            child: GestureDetector(
              onTap: _stage == 2 ? null : () => Navigator.of(context).pop(),
              child: Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: _stage == 2
                      ? AppColors.mutedText.withValues(alpha: 0.35)
                      : AppColors.mutedText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuckyMachineWidget extends StatelessWidget {
  const _LuckyMachineWidget({
    required this.coinMoveValue,
    required this.spinValue,
    required this.handleValue,
    required this.ballOutValue,
    required this.stage,
    required this.onCoinTap,
    required this.onSpinTap,
  });

  final double coinMoveValue;
  final double spinValue;
  final double handleValue;
  final double ballOutValue;
  final int stage;
  final VoidCallback onCoinTap;
  final VoidCallback onSpinTap;

  @override
  Widget build(BuildContext context) {
    final ballColors = <Color>[
      const Color(0xFFFF7C73),
      const Color(0xFFFFCE4F),
      const Color(0xFF79D7FF),
      const Color(0xFF89E3A0),
      const Color(0xFFC78AFF),
      const Color(0xFFFFB063),
      const Color(0xFF8DB7FF),
      const Color(0xFFFF9BD5),
    ];

    const coinStart = Offset(142, 126);
    const coinEnd = Offset(153, 252);

    final coinX = coinStart.dx + (coinEnd.dx - coinStart.dx) * coinMoveValue;
    final coinY = coinStart.dy + (coinEnd.dy - coinStart.dy) * coinMoveValue;

    return SizedBox(
      width: 330,
      height: 430,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            child: Text(
              stage == 0
                  ? 'Drag the coin into the slot'
                  : stage == 1
                  ? 'Tap the spin button'
                  : stage == 2
                  ? 'Spinning...'
                  : 'Ball is coming out...',
              style: AppTextStyles.bodyBold.copyWith(
                fontSize: 20,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // left bear ear
          Positioned(left: 38, top: 50, child: _BearMachineEar()),

          // right bear ear
          Positioned(right: 38, top: 50, child: _BearMachineEar()),

          // small cute top cap
          Positioned(
            top: 48,
            child: Container(
              width: 88,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6D4A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: const Color(0xFF8F3A35), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // bear head machine body
          Positioned(
            top: 68,
            child: Container(
              width: 280,
              height: 192,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F5).withValues(alpha: 0.94),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(125),
                  topRight: Radius.circular(125),
                  bottomLeft: Radius.circular(58),
                  bottomRight: Radius.circular(58),
                ),
                border: Border.all(color: const Color(0xFF8F3A35), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(96),
                  topRight: Radius.circular(96),
                  bottomLeft: Radius.circular(41),
                  bottomRight: Radius.circular(41),
                ),
                child: Stack(
                  children: [
                    ...List.generate(ballColors.length, (index) {
                      final angle =
                          spinValue * 2 * math.pi +
                          (index * 2 * math.pi / ballColors.length);

                      const centerX = 112.0;
                      const centerY = 92.0;
                      const radiusX = 76.0;
                      const radiusY = 46.0;

                      final x = centerX + radiusX * math.cos(angle);
                      final y = centerY + radiusY * math.sin(angle);

                      return Positioned(
                        left: x,
                        top: y,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: ballColors[index],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 5,
                                offset: const Offset(1, 3),
                              ),
                            ],
                          ),
                          child: Align(
                            alignment: const Alignment(-0.35, -0.45),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 238,
            child: DragTarget<int>(
              onWillAcceptWithDetails: (_) => stage == 0,
              onAcceptWithDetails: (_) => onCoinTap(),
              builder: (context, candidateData, rejectedData) {
                final hovering = candidateData.isNotEmpty;

                return SizedBox(
                  width: 120,
                  height: 54,
                  child: Center(
                    child: Container(
                      width: 96,
                      height: 38,
                      decoration: BoxDecoration(
                        color: hovering
                            ? const Color(0xFFFF8EA1)
                            : const Color(0xFFFF6D78),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: const Color(0xFF8F3A35),
                          width: 3,
                        ),
                        boxShadow: hovering
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFC94A,
                                  ).withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Container(
                          width: 66,
                          height: 15,
                          decoration: BoxDecoration(
                            color: const Color(0xFF84413A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFC94A),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            top: 264,
            child: SizedBox(
              width: 310,
              height: 166,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _CuteGachaBasePainter()),
                  ),

                  // cute highlight line on left
                  Positioned(
                    left: 24,
                    top: 28,
                    child: Container(
                      width: 5,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  // small cute dots
                  Positioned(
                    left: 139,
                    top: 26,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB53728).withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 24,
                    top: 25,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD27A).withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 17,
                    top: 44,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD27A).withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // left prize door
                  Positioned(
                    left: 32,
                    top: 42,
                    child: Container(
                      width: 94,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE04427),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        border: Border.all(
                          color: const Color(0xFF8F3A35),
                          width: 3.5,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (stage == 3)
                            Positioned(
                              left: 15,
                              bottom: -8 + (1 - ballOutValue) * 35,
                              child: Transform.scale(
                                scale: 0.65 + (ballOutValue * 0.35),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC94A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFFA000),
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFC94A,
                                        ).withValues(alpha: 0.45),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Align(
                                    alignment: const Alignment(-0.35, -0.45),
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.32,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // small middle slot

                  // right spin button
                  Positioned(
                    right: 31,
                    top: 30,
                    child: GestureDetector(
                      onTap: stage == 1 ? onSpinTap : null,
                      child: Container(
                        width: 94,
                        height: 94,
                        decoration: BoxDecoration(
                          color: stage == 1
                              ? const Color(0xFFFFB21F)
                              : const Color(0xFFFFC43A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF8F3A35),
                            width: 4,
                          ),
                          boxShadow: stage == 1
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFC94A,
                                    ).withValues(alpha: 0.50),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: handleValue * math.pi,
                            child: Container(
                              width: 24,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE9A8),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFF8F3A35),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // small bear logo
                  Positioned(
                    left: 132,
                    top: 116,
                    child: Opacity(
                      opacity: 0.75,
                      child: Column(
                        children: [
                          const Text(
                            'ʕ•ᴥ•ʔ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'BEAR',
                            style: AppTextStyles.tiny.copyWith(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: coinX,
            top: coinY,
            child: stage == 0
                ? Draggable<int>(
                    data: 1,
                    feedback: const Material(
                      color: Colors.transparent,
                      child: _LuckyCoin(size: 45),
                    ),
                    childWhenDragging: const Opacity(
                      opacity: 0.25,
                      child: _LuckyCoin(size: 45),
                    ),
                    child: const _LuckyCoin(size: 45),
                  )
                : const SizedBox.shrink(),
          ),

          if (stage == 0)
            const Positioned(
              left: 134,
              top: 166,
              child: _AnimatedHandPointer(angle: 0),
            ),

          if (stage == 1)
            const Positioned(
              left: 202,
              top: 355,
              child: _AnimatedHandPointer(angle: 0),
            ),
        ],
      ),
    );
  }
}

class _LuckyCoin extends StatelessWidget {
  const _LuckyCoin({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC94A),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF8F3A35),
          width: size > 30 ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.star_rounded,
          size: size > 30 ? 24 : 13,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _BearMachineEar extends StatelessWidget {
  const _BearMachineEar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F5).withValues(alpha: 0.96),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8F3A35), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD6DE).withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _AnimatedHandPointer extends StatefulWidget {
  const _AnimatedHandPointer({required this.angle});

  final double angle;

  @override
  State<_AnimatedHandPointer> createState() => _AnimatedHandPointerState();
}

class _AnimatedHandPointerState extends State<_AnimatedHandPointer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _moveAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _moveAnimation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _moveAnimation.value),
            child: Transform.rotate(
              angle: widget.angle,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: const Text(
          '👆',
          style: TextStyle(
            fontSize: 48,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BallRewardScene extends StatelessWidget {
  const _BallRewardScene({
    super.key,
    required this.stage,
    required this.ballScale,
    required this.openScale,
    required this.sparkleValue,
    required this.quest,
    required this.onBallTap,
    required this.onDoneTap,
  });

  final int stage;
  final double ballScale;
  final double openScale;
  final double sparkleValue;
  final OutfitQuest quest;
  final VoidCallback onBallTap;
  final VoidCallback onDoneTap;

  @override
  Widget build(BuildContext context) {
    final rewardOpened = stage == 4;

    return SizedBox(
      width: 360,
      height: 520,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 22,
            child: Column(
              children: [
                Text(
                  rewardOpened ? 'Congratulations!' : 'Tap to open',
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 24,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (rewardOpened) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      'You got ${quest.name}',
                      style: AppTextStyles.bodyBold.copyWith(
                        fontSize: 16,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (rewardOpened)
            Positioned(
              top: 112,
              child: _WowRewardEffect(sparkleValue: sparkleValue),
            ),

          Positioned(
            top: rewardOpened ? 150 : 155,
            child: GestureDetector(
              onTap: rewardOpened ? null : onBallTap,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: rewardOpened
                    ? Transform.scale(
                        key: const ValueKey('reward_only'),
                        scale: openScale,
                        child: _ZoomRewardOutfit(quest: quest),
                      )
                    : Transform.scale(
                        key: const ValueKey('closed_ball'),
                        scale: ballScale,
                        child: const _ClosedLuckyBall(),
                      ),
              ),
            ),
          ),

          if (rewardOpened)
            Positioned(
              bottom: 24,
              child: GestureDetector(
                onTap: onDoneTap,
                child: Container(
                  height: 46,
                  width: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: AppShadows.card,
                  ),
                  child: Text(
                    'Done',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomRewardOutfit extends StatelessWidget {
  const _ZoomRewardOutfit({required this.quest});

  final OutfitQuest quest;

  @override
  Widget build(BuildContext context) {
    final imagePath = MascotWidget.outfitImages[quest.id] ?? quest.imagePath;

    return SizedBox(
      width: 210,
      height: 210,
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.pets_rounded,
            size: 120,
            color: AppColors.mutedText,
          );
        },
      ),
    );
  }
}

class _ClosedLuckyBall extends StatelessWidget {
  const _ClosedLuckyBall();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC94A),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFA000), width: 6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC94A).withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Align(
        alignment: const Alignment(-0.35, -0.45),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _WowRewardEffect extends StatelessWidget {
  const _WowRewardEffect({required this.sparkleValue});

  final double sparkleValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: CustomPaint(painter: _WowRewardPainter(progress: sparkleValue)),
    );
  }
}

class _WowRewardPainter extends CustomPainter {
  _WowRewardPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final rayPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.star.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final animatedRadius = 80 + (math.sin(progress * math.pi * 2) * 6);

    canvas.drawCircle(center, animatedRadius, glowPaint);
    canvas.drawCircle(center, animatedRadius + 20, ringPaint);

    for (int i = 0; i < 18; i++) {
      final angle = (math.pi * 2 / 18) * i + progress;
      final startRadius = 92 + (i % 2) * 8;
      final endRadius = 118 + (i % 3) * 8;

      final start = Offset(
        center.dx + math.cos(angle) * startRadius,
        center.dy + math.sin(angle) * startRadius,
      );

      final end = Offset(
        center.dx + math.cos(angle) * endRadius,
        center.dy + math.sin(angle) * endRadius,
      );

      canvas.drawLine(start, end, rayPaint);
    }

    for (int i = 0; i < 10; i++) {
      final angle = (math.pi * 2 / 10) * i - progress;
      final radius = 122 + (math.sin(progress * math.pi * 2 + i) * 8);

      final dot = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      canvas.drawCircle(dot, 4.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WowRewardPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CuteGachaBasePainter extends CustomPainter {
  const _CuteGachaBasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPath = Path()
      ..moveTo(36, 2)
      ..lineTo(size.width - 36, 2)
      ..quadraticBezierTo(size.width - 8, 2, size.width - 4, 36)
      ..lineTo(size.width - 2, size.height - 42)
      ..quadraticBezierTo(
        size.width - 8,
        size.height - 5,
        size.width - 43,
        size.height - 2,
      )
      ..lineTo(43, size.height - 2)
      ..quadraticBezierTo(8, size.height - 5, 4, size.height - 42)
      ..lineTo(4, 36)
      ..quadraticBezierTo(8, 2, 36, 2)
      ..close();

    canvas.drawShadow(bodyPath, Colors.black.withValues(alpha: 0.18), 8, false);

    final fillPaint = Paint()
      ..color = const Color(0xFFFF4B2E)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF8F3A35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawPath(bodyPath, fillPaint);
    canvas.drawPath(bodyPath, borderPaint);

    final topHighlightPaint = Paint()
      ..color = const Color(0xFFFF7054).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      const Offset(48, 18),
      Offset(size.width - 52, 18),
      topHighlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CuteGachaBasePainter oldDelegate) {
    return false;
  }
}
