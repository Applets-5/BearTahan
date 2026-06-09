import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class MascotSelectionScreen extends StatefulWidget {
  const MascotSelectionScreen({super.key, required this.childId});

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No logged in parent found.');
      }

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .doc(widget.childId)
          .set({
            'activeOutfitID': selectedOutfitId,
            'hasSelectedStarterMascot': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;
      context.go(AppRouter.selectProfile);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save outfit: $e')));
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
          content: Text(
            '${outfit.name} is locked. Keep learning to unlock it!',
          ),
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
    if (widget.childId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pick your bear')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 64,
                  color: AppColors.mutedText,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Create a child profile before choosing a bear.',
                  style: AppTextStyles.cardTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Create Profile',
                  icon: Icons.add_rounded,
                  onPressed: () => context.go(AppRouter.createProfile),
                ),
              ],
            ),
          ),
        ),
      );
    }

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

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseAuth.instance.currentUser == null
                        ? null
                        : FirebaseFirestore.instance
                              .collection('parents')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('children')
                              .doc(widget.childId)
                              .collection('questProgress')
                              .snapshots(),
                    builder: (context, snapshot) {
                      final unlockedIds = <String>{'scholar_bear'};
                      for (final doc in snapshot.data?.docs ?? []) {
                        if (doc.data()['isUnlocked'] == true) {
                          unlockedIds.add(doc.id);
                        }
                      }

                      final availableOutfits = outfits
                          .map(
                            (outfit) => outfit.copyWith(
                              unlocked: unlockedIds.contains(outfit.id),
                            ),
                          )
                          .toList();

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: availableOutfits.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.9,
                            ),
                        itemBuilder: (context, index) {
                          final outfit = availableOutfits[index];
                          final isSelected = selectedOutfitId == outfit.id;

                          return _MascotOutfitCard(
                            outfit: outfit,
                            isSelected: isSelected,
                            onTap: () => selectOutfit(outfit),
                          );
                        },
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

  _MascotOutfit copyWith({bool? unlocked}) {
    return _MascotOutfit(
      id: id,
      name: name,
      imagePath: imagePath,
      unlocked: unlocked ?? this.unlocked,
    );
  }
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

    Widget bearImage = Image.asset(
      outfit.imagePath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.pets_rounded,
        color: AppColors.mutedText,
        size: AppSpacing.xxxl,
      ),
    );

    if (!outfit.unlocked) {
      bearImage = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.mutedText,
          BlendMode.srcIn,
        ),
        child: bearImage,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.r(AppRadius.xl),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.white,
              borderRadius: AppRadius.r(AppRadius.xl),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: bearImage),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  outfit.unlocked ? outfit.name : 'Locked',
                  style: AppTextStyles.tiny.copyWith(
                    fontWeight: FontWeight.bold,
                    color: outfit.unlocked
                        ? AppColors.foreground
                        : AppColors.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          if (!outfit.unlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.45),
                  borderRadius: AppRadius.r(AppRadius.xl),
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

          if (isSelected && outfit.unlocked)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}
