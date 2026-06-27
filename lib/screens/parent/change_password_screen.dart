import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final parentId = ref.read(parentIdProvider);

      // Re-authenticate first
      await firestoreService.reauthenticate(_oldPasswordController.text);

      // Update password
      await firestoreService.updatePassword(
        parentId,
        _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(parentSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Password')),
      body: settingsAsync.when(
        data: (settings) {
          final length = settings['passwordLength'] ?? 8;
          if (_oldPasswordController.text.isEmpty && !_isLoading) {
            _oldPasswordController.text = List.filled(length, 'x').join();
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _buildPasswordField(
                    controller: _oldPasswordController,
                    label: 'Old Password',
                    obscure: _obscureOld,
                    onToggle: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _updatePassword,
                      child: const Text('Change Password'),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyBold),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: _PawIcon(
                key: ValueKey(obscure),
                isFilled: !obscure,
                color: AppColors.secondaryText,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}

class _PawIcon extends StatelessWidget {
  const _PawIcon({required this.isFilled, required this.color, super.key});

  final bool isFilled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24.0, 24.0),
      painter: _PawPainter(isFilled: isFilled, color: color),
    );
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter({required this.isFilled, required this.color});

  final bool isFilled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Draw the 4 toes
    // Toe 1 (left-most)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.20, h * 0.42),
        width: w * 0.18,
        height: h * 0.24,
      ),
      paint,
    );

    // Toe 2 (middle-left)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.40, h * 0.26),
        width: w * 0.20,
        height: h * 0.28,
      ),
      paint,
    );

    // Toe 3 (middle-right)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.60, h * 0.26),
        width: w * 0.20,
        height: h * 0.28,
      ),
      paint,
    );

    // Toe 4 (right-most)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.80, h * 0.42),
        width: w * 0.18,
        height: h * 0.24,
      ),
      paint,
    );

    // Draw main pad
    final path = Path();
    path.moveTo(w * 0.5, h * 0.88);
    path.quadraticBezierTo(w * 0.18, h * 0.88, w * 0.24, h * 0.68);
    path.quadraticBezierTo(w * 0.5, w * 0.46, w * 0.76, h * 0.68);
    path.quadraticBezierTo(w * 0.82, h * 0.88, w * 0.5, h * 0.88);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PawPainter oldDelegate) {
    return oldDelegate.isFilled != isFilled || oldDelegate.color != color;
  }
}
