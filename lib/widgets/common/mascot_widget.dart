import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../providers/data_providers.dart';

enum MascotMood { idle, cheering, crying, celebrating }

final Set<String> _decodedMascotAssets = <String>{};

class WalkingMascotStage extends StatefulWidget {
  const WalkingMascotStage({
    super.key,
    required this.child,
    required this.mascotSize,
    this.height = 180,
    this.duration = const Duration(milliseconds: 4800),
    this.isWalking = true,
  });

  final Widget child;
  final double mascotSize;
  final double height;
  final Duration duration;
  final bool isWalking;

  @override
  State<WalkingMascotStage> createState() => _WalkingMascotStageState();
}

class _WalkingMascotStageState extends State<WalkingMascotStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.isWalking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WalkingMascotStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.isWalking != widget.isWalking) {
      if (widget.isWalking) {
        _controller.repeat();
      } else {
        _controller
          ..stop()
          ..value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travelDistance = math.max(
            0.0,
            constraints.maxWidth - widget.mascotSize,
          );

          return AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (context, child) {
              final travelPhase = _controller.value * math.pi * 2;
              final stepPhase = _controller.value * math.pi * 12;
              final horizontalProgress = (math.sin(travelPhase) + 1) / 2;
              final walkingRight = math.cos(travelPhase) >= 0;
              final bounce = widget.isWalking
                  ? math.sin(stepPhase).abs() * 12
                  : 0.0;
              final wobble = widget.isWalking
                  ? math.sin(stepPhase) * 0.075 * (walkingRight ? 1 : -1)
                  : 0.0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset(
                        travelDistance * horizontalProgress,
                        -bounce,
                      ),
                      child: Transform.rotate(
                        angle: wobble,
                        alignment: Alignment.bottomCenter,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(
                            walkingRight ? 1 : -1,
                            1,
                            1,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class MascotWidget extends StatelessWidget {
  const MascotWidget({
    super.key,
    this.size = 72,
    this.message,
    this.locked = false,
    this.outfitId = 'scholar_bear',
    this.showBackground = true,
    this.mood = MascotMood.idle,
  });

  final double size;
  final String? message;
  final bool locked;
  final String outfitId;
  final bool showBackground;
  final MascotMood mood;

  static const Map<String, String> outfitImages = {
    'scholar_bear': 'assets/images/bear1.png',
    'chef_bear': 'assets/images/bear2.png',
    'astro_bear': 'assets/images/bear3.png',
    'pirate_bear': 'assets/images/bear4.png',
    'super_bear': 'assets/images/bear5.png',
    'explorer_bear': 'assets/images/bear6.png',
  };

  static const Map<String, String> cryOutfitImages = {
    'scholar_bear': 'assets/images/cry_bear1_scholar.png',
    'chef_bear': 'assets/images/cry_bear2_chef.png',
    'astro_bear': 'assets/images/cry_bear3_astro.png',
    'pirate_bear': 'assets/images/cry_bear4_pirate.png',
    'super_bear': 'assets/images/cry_bear5_super.png',
    'explorer_bear': 'assets/images/cry_bear6_explorer.png',
  };

  static const Map<String, String> cheerOutfitImages = {
    'scholar_bear': 'assets/images/cheer_bear5_scholar.png',
    'chef_bear': 'assets/images/cheer_bear2_chef.png',
    'astro_bear': 'assets/images/cheer_bear6_astro.png',
    'pirate_bear': 'assets/images/cheer_bear4_pirate.png',
    'super_bear': 'assets/images/cheer_bear3_super.png',
    'explorer_bear': 'assets/images/cheer_bear1_explorer.png',
  };

  static String imagePathFor(String outfitId, MascotMood mood) {
    return switch (mood) {
      MascotMood.crying =>
        cryOutfitImages[outfitId] ??
            outfitImages[outfitId] ??
            outfitImages['scholar_bear']!,
      MascotMood.cheering || MascotMood.celebrating =>
        cheerOutfitImages[outfitId] ??
            outfitImages[outfitId] ??
            outfitImages['scholar_bear']!,
      MascotMood.idle =>
        outfitImages[outfitId] ?? outfitImages['scholar_bear']!,
    };
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = imagePathFor(outfitId, mood);

    final image = locked
        ? Icon(Icons.lock, color: AppColors.mutedText, size: size * .45)
        : Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.pets_rounded,
              color: AppColors.mutedText,
              size: size * .45,
            ),
          );

    final mascotBody = showBackground
        ? Container(
            height: size,
            width: size,
            padding: EdgeInsets.all(size * 0.08),
            decoration: BoxDecoration(
              color: AppColors.imagePlaceholder,
              borderRadius: AppRadius.r(AppRadius.xl),
            ),
            child: image,
          )
        : SizedBox(height: size, width: size, child: image);

    final mascot = mood == MascotMood.idle
        ? mascotBody
        : _AnimatedMascotFrame(mood: mood, child: mascotBody);

    if (message == null) return mascot;

    return Row(
      children: [
        mascot,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.mascotBubble,
              borderRadius: AppRadius.r(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Text(message!, style: AppTextStyles.bodyBold),
          ),
        ),
      ],
    );
  }
}

class _AnimatedMascotFrame extends StatefulWidget {
  const _AnimatedMascotFrame({required this.mood, required this.child});

  final MascotMood mood;
  final Widget child;

  @override
  State<_AnimatedMascotFrame> createState() => _AnimatedMascotFrameState();
}

class _AnimatedMascotFrameState extends State<_AnimatedMascotFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _durationForMood(widget.mood),
    )..repeat(reverse: widget.mood != MascotMood.celebrating);
  }

  @override
  void didUpdateWidget(covariant _AnimatedMascotFrame oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mood != widget.mood) {
      _controller
        ..duration = _durationForMood(widget.mood)
        ..reset()
        ..repeat(reverse: widget.mood != MascotMood.celebrating);
    }
  }

  Duration _durationForMood(MascotMood mood) {
    switch (mood) {
      case MascotMood.cheering:
        return const Duration(milliseconds: 750);
      case MascotMood.crying:
        return const Duration(milliseconds: 520);
      case MascotMood.celebrating:
        return const Duration(milliseconds: 900);
      case MascotMood.idle:
        return const Duration(milliseconds: 900);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final wave = math.sin(value * math.pi * 2);

        switch (widget.mood) {
          case MascotMood.cheering:
            final popValue = math.sin(value * math.pi);

            return Transform.translate(
              offset: Offset(0, -22 * popValue),
              child: Transform.scale(
                scale: 1 + (0.45 * popValue),
                child: child,
              ),
            );

          case MascotMood.crying:
            return Transform.translate(
              offset: Offset(2.8 * wave, 1.5 * value),
              child: Transform.rotate(angle: 0.025 * wave, child: child),
            );

          case MascotMood.celebrating:
            return Transform.translate(
              offset: Offset(0, -10 * math.sin(value * math.pi)),
              child: Transform.rotate(
                angle: 0.07 * math.sin(value * math.pi * 4),
                child: Transform.scale(
                  scale: 1 + (0.12 * math.sin(value * math.pi)),
                  child: child,
                ),
              ),
            );

          case MascotMood.idle:
            return child ?? const SizedBox.shrink();
        }
      },
      child: widget.child,
    );
  }
}

class ActiveMascotWidget extends ConsumerWidget {
  const ActiveMascotWidget({
    super.key,
    this.childId,
    this.size = 72,
    this.message,
    this.showBackground = true,
    this.mood = MascotMood.idle,
    this.hideUntilLoaded = false,
  });

  final String? childId;
  final double size;
  final String? message;
  final bool showBackground;
  final MascotMood mood;
  final bool hideUntilLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    if (user == null || childId == null) {
      return MascotWidget(
        size: size,
        message: message,
        showBackground: showBackground,
        mood: mood,
      );
    }

    final profile = ref.watch(userProfileProvider(childId!));

    return profile.when(
      loading: () => hideUntilLoaded
          ? SizedBox(height: size, width: size)
          : MascotWidget(
              size: size,
              message: message,
              outfitId: 'scholar_bear',
              showBackground: showBackground,
              mood: mood,
            ),
      error: (error, stackTrace) => hideUntilLoaded
          ? SizedBox(height: size, width: size)
          : MascotWidget(
              size: size,
              message: message,
              outfitId: 'scholar_bear',
              showBackground: showBackground,
              mood: mood,
            ),
      data: (profile) => _PrecachedMascot(
        outfitId: profile.activeMascotOutfit,
        size: size,
        message: message,
        showBackground: showBackground,
        mood: mood,
      ),
    );
  }
}

class _PrecachedMascot extends StatefulWidget {
  const _PrecachedMascot({
    required this.outfitId,
    required this.size,
    required this.message,
    required this.showBackground,
    required this.mood,
  });

  final String outfitId;
  final double size;
  final String? message;
  final bool showBackground;
  final MascotMood mood;

  @override
  State<_PrecachedMascot> createState() => _PrecachedMascotState();
}

class _PrecachedMascotState extends State<_PrecachedMascot> {
  bool _ready = false;
  String? _loadingPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prepareImage();
  }

  @override
  void didUpdateWidget(covariant _PrecachedMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outfitId != widget.outfitId ||
        oldWidget.mood != widget.mood) {
      _prepareImage();
    }
  }

  void _prepareImage() {
    final imagePath = MascotWidget.imagePathFor(widget.outfitId, widget.mood);
    if (_loadingPath == imagePath) return;

    _loadingPath = imagePath;
    if (_decodedMascotAssets.contains(imagePath)) {
      _ready = true;
      return;
    }

    _ready = false;
    precacheImage(AssetImage(imagePath), context).then((_) {
      _decodedMascotAssets.add(imagePath);
      if (mounted && _loadingPath == imagePath) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return SizedBox(height: widget.size, width: widget.size);
    }

    return MascotWidget(
      size: widget.size,
      message: widget.message,
      outfitId: widget.outfitId,
      showBackground: widget.showBackground,
      mood: widget.mood,
    );
  }
}
