import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../providers/data_providers.dart';

enum MascotMood { idle, cheering, crying, celebrating }

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

  @override
  Widget build(BuildContext context) {
    final imagePath = switch (mood) {
      MascotMood.crying =>
        cryOutfitImages[outfitId] ??
            outfitImages[outfitId] ??
            outfitImages['scholar_bear']!,

      MascotMood.cheering =>
        cheerOutfitImages[outfitId] ??
            outfitImages[outfitId] ??
            outfitImages['scholar_bear']!,

      MascotMood.celebrating =>
        cheerOutfitImages[outfitId] ??
            outfitImages[outfitId] ??
            outfitImages['scholar_bear']!,

      MascotMood.idle =>
        outfitImages[outfitId] ?? outfitImages['scholar_bear']!,
    };

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
  });

  final String? childId;
  final double size;
  final String? message;
  final bool showBackground;
  final MascotMood mood;

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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .doc(childId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final outfitId = data?['activeOutfitID'] as String? ?? 'scholar_bear';

        return MascotWidget(
          size: size,
          message: message,
          outfitId: outfitId,
          showBackground: showBackground,
          mood: mood,
        );
      },
    );
  }
}
