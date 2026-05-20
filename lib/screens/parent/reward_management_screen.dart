import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reward.dart';
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
  bool showForm = false;
  Reward? editingReward;

  void _onEdit(Reward reward) {
    setState(() {
      editingReward = reward;
      showForm = true;
    });
  }

  void _onDelete(Reward reward) async {
    final parentId = ref.read(parentIdProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
      try {
        await ref
            .read(firestoreServiceProvider)
            .deleteReward(parentId, reward.id);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Reward deleted')),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error deleting reward: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewardsAsync = ref.watch(rewardsProvider);

    return SafeArea(
      child: rewardsAsync.when(
        data: (rewards) {
          final pendingClaims = rewards.where((r) => r.status == 'pending').toList();
          final availableRewards = rewards.where((r) => r.status == 'available').toList();
          final redeemedRewards = rewards.where((r) => r.status == 'redeemed').toList();

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
                    onPressed: () {
                      setState(() {
                        editingReward = null;
                        showForm = !showForm;
                      });
                    },
                    icon: Icon(showForm ? Icons.close : Icons.add),
                    label: Text(showForm ? 'Cancel' : 'Add'),
                  ),
                ],
              ),
              const Text('Set goals for your child', style: AppTextStyles.small),
              const SizedBox(height: AppSpacing.md),
              if (showForm)
                _RewardForm(
                  reward: editingReward,
                  onSuccess: () {
                    setState(() {
                      showForm = false;
                      editingReward = null;
                    });
                  },
                ),
              if (pendingClaims.isNotEmpty) ...[
                Text(
                  'Pending claims (${pendingClaims.length})',
                  style: AppTextStyles.tiny,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...pendingClaims.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: RewardCard(
                      title: r.title,
                      description: r.description,
                      cost: r.cost,
                      status: r.status,
                      primaryLabel: 'Approve',
                      onPrimary: () {
                        // Handle approval logic here or in a separate task
                      },
                      onEdit: () => _onEdit(r),
                      onDelete: () => _onDelete(r),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text('Available rewards', style: AppTextStyles.tiny),
              const SizedBox(height: AppSpacing.sm),
              if (availableRewards.isEmpty && !showForm)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'No rewards yet. Click "Add" to create one!',
                      style: AppTextStyles.small,
                    ),
                  ),
                ),
              ...availableRewards.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: RewardCard(
                    title: r.title,
                    description: r.description,
                    cost: r.cost,
                    onEdit: () => _onEdit(r),
                    onDelete: () => _onDelete(r),
                  ),
                ),
              ),
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RewardForm extends ConsumerStatefulWidget {
  final Reward? reward;
  final VoidCallback onSuccess;

  const _RewardForm({this.reward, required this.onSuccess});

  @override
  ConsumerState<_RewardForm> createState() => _RewardFormState();
}

class _RewardFormState extends ConsumerState<_RewardForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _costController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reward?.title);
    _descriptionController = TextEditingController(
      text: widget.reward?.description,
    );
    _costController = TextEditingController(
      text: widget.reward?.cost.toString() ?? '',
    );
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
      );

      if (widget.reward == null) {
        await ref.read(firestoreServiceProvider).addReward(parentId, reward);
      } else {
        await ref.read(firestoreServiceProvider).updateReward(parentId, reward);
      }

      widget.onSuccess();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reward == null ? 'New Reward' : 'Edit Reward',
              style: AppTextStyles.bodyBold,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Reward name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(hintText: 'Description'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(hintText: 'Star cost'),
              keyboardType: TextInputType.number,
              validator:
                  (v) =>
                      v == null || int.tryParse(v) == null
                          ? 'Enter a valid number'
                          : null,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
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
                    : Text(widget.reward == null ? 'Create' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
