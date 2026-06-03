import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';

class StarHistoryScreen extends ConsumerWidget {
  const StarHistoryScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = ref.watch(parentIdProvider);
    final transactionsAsync = ref.watch(
      starTransactionsProvider((parentId: parentId, childId: childId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Star History', style: AppTextStyles.cardTitle),
        centerTitle: true,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'No history yet. Start learning to earn stars!',
                style: AppTextStyles.small,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isEarn = tx.type == 'earn';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isEarn
                      ? AppColors.accentLight
                      : AppColors.destructiveLight,
                  child: Icon(
                    isEarn ? Icons.add : Icons.remove,
                    color: isEarn ? AppColors.accent : AppColors.destructive,
                  ),
                ),
                title: Text(tx.description, style: AppTextStyles.bodyBold),
                subtitle: Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(tx.timestamp),
                  style: AppTextStyles.tiny,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEarn ? '+${tx.amount}' : '-${tx.amount.abs()}',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: isEarn
                            ? AppColors.accent
                            : AppColors.destructive,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 16, color: AppColors.star),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
