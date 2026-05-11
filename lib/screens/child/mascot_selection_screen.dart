import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class MascotSelectionScreen extends StatefulWidget {
  const MascotSelectionScreen({
    super.key,
    required this.childId,
  });

  final String childId;

  @override
  State<MascotSelectionScreen> createState() => _MascotSelectionScreenState();
}

class _MascotSelectionScreenState extends State<MascotSelectionScreen> {
  String selectedOutfitId = 'scholar_bear';
  bool isSaving = false;

  final List<_MascotOutfit> outfits = const [
    _MascotOutfit(
      id: 'scholar_bear',
      name: 'Scholar Bear',
      imagePath: 'assets/images/bear1.png',
      unlocked: true,
    ),
    _MascotOutfit(
      id: 'chef_bear',
      name: 'Chef Bear',
      imagePath: 'assets/images/bear2.png',
      unlocked: false,
    ),
    _MascotOutfit(
      id: 'astro_bear',
      name: 'Astro Bear',
      imagePath: 'assets/images/bear3.png',
      unlocked: false,
    ),
    _MascotOutfit(
      id: 'pirate_bear',
      name: 'Pirate Bear',
      imagePath: 'assets/images/bear4.png',
      unlocked: false,
    ),
    _MascotOutfit(
      id: 'super_bear',
      name: 'Super Bear',
      imagePath: 'assets/images/bear5.png',
      unlocked: false,
    ),
    _MascotOutfit(
      id: 'explorer_bear',
      name: 'Explorer Bear',
      imagePath: 'assets/images/bear6.png',
      unlocked: false,
    ),
  ];

  Future<void> saveSelectedOutfit() async {
    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .set(
        {
          'activeOutfitID': selectedOutfitId,
          'hasSelectedStarterMascot': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      context.go(AppRouter.childHome);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save outfit: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void selectOutfit(_MascotOutfit outfit) {
    if (!outfit.unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${outfit.name} is locked. Keep learning to unlock it!'),
        ),
      );
      return;
    }

    setState(() {
      selectedOutfitId = outfit.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 430),
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.r(AppRadius.xxl),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pick your bear',
                    style: AppTextStyles.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'More outfits unlock as you learn!',
                    style: AppTextStyles.small,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: outfits.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final outfit = outfits[index];
                      final isSelected = selectedOutfitId == outfit.id;

                      return _MascotOutfitCard(
                        outfit: outfit,
                        isSelected: isSelected,
                        onTap: () => selectOutfit(outfit),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  PrimaryButton(
                    label: isSaving ? 'Saving...' : 'Continue',
                    onPressed: isSaving ? null : saveSelectedOutfit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MascotOutfit {
  const _MascotOutfit({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.unlocked,
  });

  final String id;
  final String name;
  final String imagePath;
  final bool unlocked;
}

class _MascotOutfitCard extends StatelessWidget {
  const _MascotOutfitCard({
    required this.outfit,
    required this.isSelected,
    required this.onTap,
  });

  final _MascotOutfit outfit;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : AppColors.border;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.r(AppRadius.xl),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.10)
                  : Colors.white,
              borderRadius: AppRadius.r(AppRadius.xl),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Opacity(
              opacity: outfit.unlocked ? 1 : 0.35,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.asset(
                      outfit.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    outfit.name,
                    style: AppTextStyles.tiny.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          if (!outfit.unlocked)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: AppColors.mutedText,
              ),
            ),
        ],
      ),
    );
  }
}