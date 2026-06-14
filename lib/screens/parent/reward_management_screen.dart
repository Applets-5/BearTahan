import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/reward.dart';
import '../../models/reward_claim.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parent/reward_card.dart';

class RewardManagementScreen extends ConsumerStatefulWidget {
  const RewardManagementScreen({super.key});

  @override
  ConsumerState<RewardManagementScreen> createState() =>
      _RewardManagementScreenState();
}

class _RewardManagementScreenState extends ConsumerState<RewardManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _processingClaimIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onEdit(Reward reward) {
    _showRewardDialog(reward);
  }

  void _onRevertClaim(RewardClaim claim) async {
    final parentId = ref.read(parentIdProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revert Claim'),
        content: const Text(
          'Moving this claim back to "Pending" will refund any stars deducted if it was approved. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revert'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _processingClaimIds.add(claim.id));
      try {
        await ref
            .read(firestoreServiceProvider)
            .revertRewardClaim(parentId, claim);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim moved back to Pending')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error reverting: $e')));
      } finally {
        if (mounted) {
          setState(() => _processingClaimIds.remove(claim.id));
        }
      }
    }
  }

  void _onDeleteClaim(RewardClaim claim) async {
    final parentId = ref.read(parentIdProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Claim History'),
        content: const Text(
          'Are you sure you want to remove this transaction from history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await ref
            .read(firestoreServiceProvider)
            .deleteRewardClaim(parentId, claim);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Claim history deleted')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  void _showRewardDialog([Reward? reward]) {
    showDialog(
      context: context,
      builder: (context) => _RewardDialog(reward: reward),
    );
  }

  void _onApprove(RewardClaim claim) async {
    final parentId = ref.read(parentIdProvider);
    setState(() => _processingClaimIds.add(claim.id));
    try {
      await ref
          .read(firestoreServiceProvider)
          .approveRewardClaim(parentId, claim);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reward "${claim.rewardName}" approved!'),
          backgroundColor: AppColors.accent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving reward: $e')));
    } finally {
      if (mounted) {
        setState(() => _processingClaimIds.remove(claim.id));
      }
    }
  }

  void _onDecline(RewardClaim claim) async {
    final parentId = ref.read(parentIdProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Request'),
        content: const Text(
          'Are you sure you want to decline this request? Stars will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _processingClaimIds.add(claim.id));
      try {
        await ref
            .read(firestoreServiceProvider)
            .rejectRewardClaim(parentId, claim);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request declined. Stars were not deducted.'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error declining reward: $e')));
      } finally {
        if (mounted) {
          setState(() => _processingClaimIds.remove(claim.id));
        }
      }
    }
  }

  void _onDelete(Reward reward) async {
    final parentId = ref.read(parentIdProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reward'),
        content: Text('Are you sure you want to delete "${reward.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await ref
            .read(firestoreServiceProvider)
            .deleteReward(parentId, reward.id);

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reward deleted')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting reward: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewardsAsync = ref.watch(rewardsProvider);
    final parentId = ref.watch(parentIdProvider);
    final selectedChildId = ref.watch(childIdProvider);
    final childrenAsync = ref.watch(childrenProvider);
    final claimsAsync = selectedChildId == null
        ? const AsyncValue<List<RewardClaim>>.data([])
        : ref.watch(
            rewardClaimsProvider((
              parentId: parentId,
              childId: selectedChildId,
            )),
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: childrenAsync.when(
          data: (children) {
            final selectedChild = children.firstWhere(
              (c) => c.uid == selectedChildId,
              orElse: () => children.first,
            );
            return Row(
              children: [
                PopupMenuButton<String>(
                  onSelected: (id) {
                    ref.read(childIdProvider.notifier).update(id);
                  },
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.r(AppRadius.lg),
                  ),
                  itemBuilder: (context) => children.map((child) {
                    return PopupMenuItem<String>(
                      value: child.uid,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.face,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(child.name, style: AppTextStyles.bodyBold),
                              Text(
                                'Streak: ${child.streakCount} days',
                                style: AppTextStyles.tiny,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.r(AppRadius.xl),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.child_care,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          selectedChild.name,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: IconButton.filled(
              onPressed: () => _showRewardDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: rewardsAsync.when(
          data: (rewards) {
            final availableRewards = rewards
                .where(
                  (r) =>
                      r.status == 'available' &&
                      (r.targetChildId == null ||
                          r.targetChildId == selectedChildId),
                )
                .toList();
            final redeemedRewards = rewards
                .where(
                  (r) =>
                      r.status == 'redeemed' &&
                      (r.claimedByChildId == selectedChildId),
                )
                .toList();
            final pendingClaims =
                claimsAsync.value?.where((claim) => claim.isPending).toList() ??
                [];
            final resolvedClaims =
                claimsAsync.value
                    ?.where((claim) => !claim.isPending)
                    .toList() ??
                [];

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (selectedChildId == null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'No pending reward claims for now',
                      style: AppTextStyles.small,
                    ),
                  ),
                ] else if (claimsAsync.isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ] else if (pendingClaims.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Pending claims (${pendingClaims.length})',
                        style: AppTextStyles.tiny,
                      ),
                      if (_processingClaimIds.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...pendingClaims.map((claim) {
                    final isProcessing = _processingClaimIds.contains(claim.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: RewardCard(
                        title: claim.rewardName,
                        description:
                            'Requested on ${DateFormat('dd MMM yyyy, hh:mm a').format(claim.claimedAt)}.',
                        cost: claim.starCost,
                        status: claim.status,
                        primaryLabel: isProcessing ? 'Approving...' : 'Approve',
                        primaryEnabled: !isProcessing,
                        onPrimary: () => _onApprove(claim),
                        secondaryLabel: isProcessing ? 'Working...' : 'Decline',
                        secondaryEnabled: !isProcessing,
                        onSecondary: () => _onDecline(claim),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Tabbed Navigation
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(4),
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.r(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.mutedText,
                    labelStyle: AppTextStyles.bodyBold,
                    unselectedLabelStyle: AppTextStyles.body,
                    tabs: const [
                      Tab(text: 'Available'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),

                // Tab Content via conditional rendering
                if (_tabController.index == 0) ...[
                  // Available Rewards Tab
                  if (availableRewards.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No rewards yet. Click "+" to create one!',
                          style: AppTextStyles.small,
                        ),
                      ),
                    ),
                  ...availableRewards.map((r) => _buildSwipeableRewardCard(r)),
                  if (redeemedRewards.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Redeemed', style: AppTextStyles.tiny),
                    const SizedBox(height: AppSpacing.sm),
                    ...redeemedRewards.map((r) => _buildSwipeableRewardCard(r)),
                  ],
                  _buildManagementInstruction(),
                ] else ...[
                  // Claim History Tab
                  if (selectedChildId == null)
                    const SizedBox.shrink()
                  else if (resolvedClaims.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(
                        child: Text(
                          'No completed reward claims yet.',
                          style: AppTextStyles.small,
                        ),
                      ),
                    )
                  else
                    ...resolvedClaims.map((claim) {
                      final resolvedAt = claim.resolvedAt ?? claim.claimedAt;
                      final isRejected = claim.status == 'rejected';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 8,
                                bottom: 6,
                              ),
                              child: Text(
                                DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(resolvedAt),
                                style: AppTextStyles.tiny.copyWith(
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _SwipeableActionWrapper(
                              onEdit: () {
                                if (isRejected) {
                                  _onApprove(claim);
                                } else {
                                  _onRevertClaim(claim);
                                }
                              },
                              editLabel: isRejected ? 'Approve' : 'Revert',
                              editIcon: isRejected
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.undo_rounded,
                              editColor: isRejected
                                  ? AppColors.accent
                                  : Colors.orange.shade400,
                              onDelete: () => _onDeleteClaim(claim),
                              child: RewardCard(
                                title: claim.rewardName,
                                description: claim.rewardDescription,
                                cost: claim.starCost,
                                status: claim.status,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  _buildManagementInstruction(),
                ],
                const SizedBox(height: 80),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildManagementInstruction() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Center(
        child: Text(
          'Swipe left to manage rewards',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mutedText,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeableRewardCard(Reward r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _SwipeableActionWrapper(
        onEdit: () => _onEdit(r),
        onDelete: () => _onDelete(r),
        child: RewardCard(
          title: r.title,
          description: r.description,
          cost: r.cost,
          status: r.status,
        ),
      ),
    );
  }
}

class _SwipeableActionWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editLabel;
  final IconData editIcon;
  final Color? editColor;

  const _SwipeableActionWrapper({
    required this.child,
    required this.onEdit,
    required this.onDelete,
    this.editLabel = 'Edit',
    this.editIcon = Icons.edit_rounded,
    this.editColor,
  });

  @override
  State<_SwipeableActionWrapper> createState() =>
      _SwipeableActionWrapperState();
}

class _SwipeableActionWrapperState extends State<_SwipeableActionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  static const double _actionWidth = 80;
  static const double _totalWidth = _actionWidth * 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      if (_dragExtent > 0) _dragExtent = 0;
      if (_dragExtent < -_totalWidth - 20) _dragExtent = -_totalWidth - 20;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent < -_totalWidth / 2) {
      _open();
    } else {
      _close();
    }
  }

  void _open() {
    _controller.forward(from: _dragExtent / -_totalWidth);
    _controller.animateTo(1.0, curve: Curves.easeOut);
    setState(() => _dragExtent = -_totalWidth);
  }

  void _close() {
    _controller.animateTo(0.0, curve: Curves.easeOut);
    setState(() => _dragExtent = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.muted,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    _close();
                    widget.onEdit();
                  },
                  child: Container(
                    width: _actionWidth,
                    color: widget.editColor ?? Colors.blue.shade400,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.editIcon, color: Colors.white),
                        const SizedBox(height: 4),
                        Text(
                          widget.editLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _close();
                    widget.onDelete();
                  },
                  child: Container(
                    width: _actionWidth,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.white),
                        SizedBox(height: 4),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double offset = _dragExtent;
            if (_controller.isAnimating) {
              offset = -_controller.value * _totalWidth;
            }
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            behavior: HitTestBehavior.opaque,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _RewardDialog extends ConsumerStatefulWidget {
  final Reward? reward;
  const _RewardDialog({this.reward});
  @override
  ConsumerState<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends ConsumerState<_RewardDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _costController;
  String? _selectedChildId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reward?.title);
    _descriptionController = TextEditingController(
      text: widget.reward?.description,
    );
    _costController = TextEditingController(
      text: widget.reward?.cost.toString() ?? '10',
    );
    _selectedChildId = widget.reward?.targetChildId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final parentId = ref.read(parentIdProvider);
    try {
      final reward = Reward(
        id: widget.reward?.id ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        cost: int.parse(_costController.text),
        status: widget.reward?.status ?? 'available',
        targetChildId: _selectedChildId,
      );
      if (widget.reward == null) {
        await ref.read(firestoreServiceProvider).addReward(parentId, reward);
      } else {
        await ref.read(firestoreServiceProvider).updateReward(parentId, reward);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _adjustCost(int delta) {
    final current = int.tryParse(_costController.text) ?? 0;
    _costController.text = (current + delta).clamp(0, 9999).toString();
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);
    final children = childrenAsync.value ?? [];
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.r(AppRadius.xl)),
      title: Text(widget.reward == null ? 'New Reward' : 'Edit Reward'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Reward name',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.r(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.r(AppSpacing.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedChildId,
                borderRadius: AppRadius.r(AppRadius.lg),
                dropdownColor: AppColors.card,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: InputDecoration(
                  labelText: 'Assign to child',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.r(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text('All Children'),
                selectedItemBuilder: (context) {
                  return [
                    const Text('All Children'),
                    ...children.map((c) => Text(c.name)),
                  ];
                },
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'All Children',
                      style: AppTextStyles.body.copyWith(
                        color: _selectedChildId == null
                            ? AppColors.primary
                            : null,
                      ),
                    ),
                  ),
                  ...children.map(
                    (c) => DropdownMenuItem(
                      value: c.uid,
                      child: Text(
                        c.name,
                        style: AppTextStyles.body.copyWith(
                          color: _selectedChildId == c.uid
                              ? AppColors.primary
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedChildId = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _CostBtn(icon: Icons.remove, onTap: () => _adjustCost(-1)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Star Cost',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.r(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _CostBtn(icon: Icons.add, onTap: () => _adjustCost(1)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CostBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CostBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
