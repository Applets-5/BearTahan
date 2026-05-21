import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../providers/data_providers.dart';

class MascotWidget extends StatelessWidget {
  const MascotWidget({
    super.key,
    this.size = 72,
    this.message,
    this.locked = false,
    this.outfitId = 'scholar_bear',
  });

  final double size;
  final String? message;
  final bool locked;
  final String outfitId;

  static const Map<String, String> outfitImages = {
    'scholar_bear': 'assets/images/bear1.png',
    'chef_bear': 'assets/images/bear2.png',
    'astro_bear': 'assets/images/bear3.png',
    'pirate_bear': 'assets/images/bear4.png',
    'super_bear': 'assets/images/bear5.png',
    'explorer_bear': 'assets/images/bear6.png',
  };

  @override
  Widget build(BuildContext context) {
    final imagePath = outfitImages[outfitId] ?? outfitImages['scholar_bear']!;

    final mascot = Container(
      height: size,
      width: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: AppColors.imagePlaceholder,
        borderRadius: AppRadius.r(AppRadius.xl),
      ),
      child: locked
          ? Icon(Icons.lock, color: AppColors.mutedText, size: size * .45)
          : Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.pets_rounded,
                color: AppColors.mutedText,
                size: size * .45,
              ),
            ),
    );

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

class ActiveMascotWidget extends ConsumerWidget {
  const ActiveMascotWidget({
    super.key,
    this.childId,
    this.size = 72,
    this.message,
  });

  final String? childId;
  final double size;
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    if (user == null || childId == null) {
      return MascotWidget(size: size, message: message);
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

        return MascotWidget(size: size, message: message, outfitId: outfitId);
      },
    );
  }
}
