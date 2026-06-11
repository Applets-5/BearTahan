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

class _RewardManagementScreenState
    extends ConsumerState<RewardManagementScreen> {
  final Set<String> _processingClaimIds = {};

  void _onEdit(Reward reward) {
    _showRewardDialog(reward);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving reward: $e')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining reward: $e')),
        );
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reward deleted')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting reward: $e')),
        );
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

    return SafeArea(
      child: rewardsAsync.when(
        data: (rewards) {
          final availableRewards = rewards
              .where((r) => r.status == 'available')
              .toList();
          final redeemedRewards = rewards
              .where((r) => r.status == 'redeemed')
              .toList();
          final pendingClaims =
              claimsAsync.value?.where((claim) => claim.isPending).toList() ??
              [];
          final resolvedClaims =
              claimsAsync.value?.where((claim) => !claim.isPending).toList() ??
              [];

          final children = childrenAsync.value ?? [];

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Manage Rewards',
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showRewardDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const Text(
                'Set goals for your child',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: AppSpacing.md),
              if (selectedChildId == null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    'Select a child on the dashboard to manage reward claims.',
                    style: AppTextStyles.small,
                  ),
                ),
              ] else if (claimsAsync.isLoading) ...[
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ] else ...[
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
                if (pendingClaims.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Text(
                      'No pending reward claims.',
                      style: AppTextStyles.small,
                    ),
                  )
                else
                  ...pendingClaims.map((claim) {
                    final isProcessing = _processingClaimIds.contains(claim.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: RewardCard(
                        title: claim.rewardName,
                        description:
                            '${claim.childName} claimed this reward on ${DateFormat('dd MMM yyyy, hh:mm a').format(claim.claimedAt)}.',
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
              const Text('Available rewards', style: AppTextStyles.tiny),
              const SizedBox(height: AppSpacing.sm),
              if (availableRewards.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'No rewards yet. Click "Add" to create one!',
                      style: AppTextStyles.small,
                    ),
                  ),
                ),
              ...availableRewards.map((r) {
                String? childName;
                if (r.targetChildId != null) {
                  final target = children
                      .where((c) => c.uid == r.targetChildId)
                      .toList();
                  if (target.isNotEmpty) {
                    childName = target.first.name;
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: RewardCard(
                    title: r.title,
                    description: r.description,
                    cost: r.cost,
                    childName: childName,
                    onEdit: () => _onEdit(r),
                    onDelete: () => _onDelete(r),
                  ),
                );
              }),
              if (redeemedRewards.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text('Redeemed', style: AppTextStyles.tiny),
                const SizedBox(height: AppSpacing.sm),
                ...redeemedRewards.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: RewardCard(
                      title: r.title,
                      description: r.description,
                      cost: r.cost,
                      status: r.status,
                      onEdit: () => _onEdit(r),
                      onDelete: () => _onDelete(r),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const Text('Claim history', style: AppTextStyles.tiny),
              const SizedBox(height: AppSpacing.sm),
              if (selectedChildId == null)
                const SizedBox.shrink()
              else if (claimsAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (resolvedClaims.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    'No completed reward claims yet.',
                    style: AppTextStyles.small,
                  ),
                )
              else
                ...resolvedClaims.map(
                  (claim) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ClaimHistoryTile(claim: claim),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ClaimHistoryTile extends StatelessWidget {
  const _ClaimHistoryTile({required this.claim});

  final RewardClaim claim;

  Color _statusColor() {
    switch (claim.status) {
      case 'approved':
        return AppColors.accent;
      case 'rejected':
        return AppColors.destructive;
      case 'expired':
        return AppColors.mutedText;
      default:
        return AppColors.primary;
    }
  }

  IconData _statusIcon() {
    switch (claim.status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'expired':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAt = claim.resolvedAt ?? claim.claimedAt;
    final color = _statusColor();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(), color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(claim.rewardName, style: AppTextStyles.bodyBold),
                Text(
                  '${claim.childName} - ${claim.starCost} stars - ${DateFormat('dd MMM yyyy, hh:mm a').format(resolvedAt)}',
                  style: AppTextStyles.tiny,
                ),
              ],
            ),
          ),
          Text(claim.status, style: AppTextStyles.tiny.copyWith(color: color)),
        ],
      ),
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.reward == null ? 'Reward added' : 'Reward updated',
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error saving reward: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _adjustCost(int delta) {
    final current = int.tryParse(_costController.text) ?? 0;
    final newValue = (current + delta).clamp(0, 9999);
    _costController.text = newValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);
    final children = childrenAsync.value ?? [];

    return AlertDialog(
      title: Text(widget.reward == null ? 'New Reward' : 'Edit Reward'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Reward name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedChildId,
                hint: const Text('All Children'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Children'),
                  ),
                  ...children.map(
                    (c) => DropdownMenuItem(value: c.uid, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedChildId = v),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Star Cost', style: AppTextStyles.tiny),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _CostBtn(icon: Icons.remove, onTap: () => _adjustCost(-1)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: TextFormField(
                        controller: _costController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => v == null || int.tryParse(v) == null
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ),
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
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.reward == null ? 'Create' : 'Save'),
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
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.mutedText),
      ),
    );
  }
}
