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

    _shakeMove = TweenSequence<double>([
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
                      onRewardTap: widget.onEquipNow,
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
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: _stage == 2
                      ? AppColors.mutedText.withOpacity(0.35)
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
                color: AppColors.primary,
              ),
            ),
          ),

          Positioned(
            top: 44,
            child: Container(
              width: 82,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4E2F),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: const Color(0xFF8F3A35), width: 3),
              ),
            ),
          ),

          Positioned(
            top: 64,
            child: Container(
              width: 270,
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F5).withOpacity(0.92),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(100),
                  topRight: Radius.circular(100),
                  bottomLeft: Radius.circular(45),
                  bottomRight: Radius.circular(45),
                ),
                border: Border.all(color: const Color(0xFF8F3A35), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
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
                              color: Colors.white.withOpacity(0.35),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
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
                                color: Colors.white.withOpacity(0.45),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    Positioned(
                      left: 20,
                      top: 32,
                      child: Container(
                        width: 15,
                        height: 116,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 28,
                      top: 34,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 238,
            child: DragTarget<int>(
              onWillAccept: (_) => stage == 0,
              onAccept: (_) => onCoinTap(),
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
                                  color: const Color(0xFFFFC94A)
                                      .withOpacity(0.45),
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
            top: 274,
            child: Container(
              width: 270,
              height: 134,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4E2F),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                border: Border.all(color: const Color(0xFF8F3A35), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 10,
                    child: Container(
                      height: 17,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8EA1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 23,
                    bottom: 31,
                    child: Container(
                      width: 84,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD84628),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(26),
                          topRight: Radius.circular(26),
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        border: Border.all(
                          color: const Color(0xFF8F3A35),
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (stage == 3)
                            Positioned(
                              left: 10,
                              bottom: -6 + (1 - ballOutValue) * 35,
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
                                        color: const Color(0xFFFFC94A)
                                            .withOpacity(0.45),
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
                                        color: Colors.white.withOpacity(0.32),
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

                  Positioned(
                    right: 28,
                    top: 22,
                    child: GestureDetector(
                      onTap: stage == 1 ? onSpinTap : null,
                      child: Transform.rotate(
                        angle: handleValue * math.pi,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: stage == 1
                                ? const Color(0xFFFFC94A)
                                : const Color(0xFFFFDA84),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF8F3A35),
                              width: 4,
                            ),
                            boxShadow: stage == 1
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFFC94A)
                                          .withOpacity(0.45),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Container(
                              width: 23,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE8A8),
                                borderRadius: BorderRadius.circular(16),
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

                  Positioned(
                    left: 116,
                    top: 75,
                    child: Container(
                      width: 42,
                      height: 15,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC94A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF8F3A35),
                          width: 2,
                        ),
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
                : AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: stage == 2 ? 0 : 1,
                    child: const _LuckyCoin(size: 24),
                  ),
          ),

          if (stage == 0)
            Positioned(
              right: 10,
              top: 122,
              child: Transform.rotate(
                angle: -0.25,
                child: const Text(
                  '👆',
                  style: TextStyle(fontSize: 46),
                ),
              ),
            ),

          if (stage == 1)
            Positioned(
              right: 0,
              top: 305,
              child: Transform.rotate(
                angle: -0.35,
                child: const Text(
                  '👆',
                  style: TextStyle(fontSize: 46),
                ),
              ),
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
            color: Colors.black.withOpacity(0.12),
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

class _BallRewardScene extends StatelessWidget {
  const _BallRewardScene({
    super.key,
    required this.stage,
    required this.ballScale,
    required this.openScale,
    required this.sparkleValue,
    required this.quest,
    required this.onBallTap,
    required this.onRewardTap,
  });

  final int stage;
  final double ballScale;
  final double openScale;
  final double sparkleValue;
  final OutfitQuest quest;
  final VoidCallback onBallTap;
  final VoidCallback onRewardTap;

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
            top: 20,
            child: Column(
              children: [
                Text(
                  rewardOpened ? 'Congratulations!' : 'Tap to open',
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 24,
                    color: const Color(0xFFE85C8A),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (rewardOpened) ...[
                  const SizedBox(height: 8),
                  Text(
                    'You got ${quest.name}',
                    style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 20,
                      color: const Color(0xFFE85C8A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          if (rewardOpened)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: const [
                    Positioned(
                      left: 24,
                      top: 100,
                      child: Text('✨', style: TextStyle(fontSize: 28)),
                    ),
                    Positioned(
                      right: 34,
                      top: 126,
                      child: Text('✨', style: TextStyle(fontSize: 26)),
                    ),
                    Positioned(
                      left: 54,
                      top: 150,
                      child: Text('💖', style: TextStyle(fontSize: 20)),
                    ),
                    Positioned(
                      right: 52,
                      top: 96,
                      child: Text('💖', style: TextStyle(fontSize: 20)),
                    ),
                    Positioned(
                      left: 58,
                      bottom: 116,
                      child: Text('✨', style: TextStyle(fontSize: 24)),
                    ),
                    Positioned(
                      right: 56,
                      bottom: 140,
                      child: Text('✨', style: TextStyle(fontSize: 22)),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            top: rewardOpened ? 150 : 155,
            child: GestureDetector(
              onTap: rewardOpened ? onRewardTap : onBallTap,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
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
              child: Text(
                'Tap the reward to equip',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
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
        border: Border.all(
          color: const Color(0xFFFFA000),
          width: 6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC94A).withOpacity(0.45),
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
            color: Colors.white.withOpacity(0.28),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _OpenedCapsuleReward extends StatelessWidget {
  const _OpenedCapsuleReward({required this.quest});

  final OutfitQuest quest;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -8,
            child: Container(
              width: 155,
              height: 155,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD24D),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFA000),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Align(
                alignment: const Alignment(-0.35, -0.35),
                child: Container(
                  width: 34,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 6,
            child: Container(
              width: 215,
              height: 215,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC83E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFA000),
                  width: 5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC83E).withOpacity(0.35),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Align(
                alignment: const Alignment(-0.25, -0.35),
                child: Container(
                  width: 48,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 8,
            child: Container(
              width: 215,
              height: 108,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC83E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(108),
                  bottomRight: Radius.circular(108),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 76,
            child: SizedBox(
              width: 132,
              height: 132,
              child: _LuckyRewardOutfitImage(quest: quest),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuckyRewardOutfitImage extends StatelessWidget {
  const _LuckyRewardOutfitImage({required this.quest});

  final OutfitQuest quest;

  @override
  Widget build(BuildContext context) {
    final imagePath = MascotWidget.outfitImages[quest.id] ?? quest.imagePath;

    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.pets_rounded,
          size: 72,
          color: AppColors.mutedText,
        );
      },
    );
  }
}