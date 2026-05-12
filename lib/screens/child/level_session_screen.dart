import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class LevelSessionScreen extends StatefulWidget {
  const LevelSessionScreen({super.key, this.childId});

  final String? childId;

  @override
  State<LevelSessionScreen> createState() => _LevelSessionScreenState();
}

class _LevelSessionScreenState extends State<LevelSessionScreen> {
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  bool _timerStarted = false;

  int? selected;
  final options = const ['Kucing', 'Rumah', 'Buku', 'Bola'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSessionTimer();
    });
  }

  @override
  void dispose() {
    _stopSessionTimer();
    super.dispose();
  }

  void _startSessionTimer() {
    if (_timerStarted) return;
    _timerStarted = true;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  String _formatElapsedTime() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _completeSession() async {
    _stopSessionTimer();

    try {
      if (widget.childId != null) {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(widget.childId)
            .collection('attempts')
            .add({
              'levelId': 'example_level', // Hardcoded for mockup
              'score': 100, // Hardcoded for mockup
              'stars': 3, // Hardcoded for mockup
              'elapsedTimeSeconds': _elapsedSeconds,
              'completedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      debugPrint('Error saving attempt: $e');
    }

    if (mounted) {
      context.go(AppRouter.completionFor(widget.childId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, color: AppColors.mutedText),
                  ),
                  const Expanded(
                    child: LinearProgressIndicator(
                      value: .45,
                      minHeight: AppSpacing.md,
                      color: AppColors.subjectBm,
                      backgroundColor: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.star, color: AppColors.star),
                  const Text('3/10', style: AppTextStyles.bodyBold),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Question 4/10',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, size: 18, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          _formatElapsedTime(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'What word matches this picture?',
                style: AppTextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 104,
                width: 104,
                decoration: BoxDecoration(
                  color: AppColors.imagePlaceholder,
                  borderRadius: AppRadius.r(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.image,
                  color: AppColors.mutedText,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ...List.generate(options.length, _option),
              const Spacer(),
              if (selected != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: selected == 1
                        ? AppColors.accentLight
                        : AppColors.destructiveLight,
                    borderRadius: AppRadius.r(AppRadius.lg),
                  ),
                  child: Text(
                    selected == 1
                        ? 'Correct! Well done!'
                        : 'Not quite! The answer is "Rumah".',
                    style: AppTextStyles.bodyBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _completeSession,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(int index) {
    final picked = selected == index;
    final correct = selected != null && index == 1;
    final color = correct
        ? AppColors.accentLight
        : picked
        ? AppColors.destructiveLight
        : AppColors.card;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: selected == null ? () => setState(() => selected = index) : null,
        borderRadius: AppRadius.r(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.r(AppRadius.lg),
            border: Border.all(
              color: correct
                  ? AppColors.accent
                  : picked
                  ? AppColors.destructive
                  : AppColors.border,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.muted,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: AppTextStyles.bodyBold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(options[index], style: AppTextStyles.bodyBold),
            ],
          ),
        ),
      ),
    );
  }
}
