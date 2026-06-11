import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

class ParentProfileDetailScreen extends ConsumerStatefulWidget {
  const ParentProfileDetailScreen({super.key});

  @override
  ConsumerState<ParentProfileDetailScreen> createState() =>
      _ParentProfileDetailScreenState();
}

class _ParentProfileDetailScreenState
    extends ConsumerState<ParentProfileDetailScreen> {
  final _parentNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isEditingParent = false;
  bool _isLoading = false;
  bool _showAvatarPickerRow = false;
  String? _selectedAvatar;

  final List<String> _avatars = [
    '🐻', '🐼', '🐨', '🦁', '🐯', '🐮', '🐸', '🐵', '🐔', '🐷',
  ];

  @override
  void dispose() {
    _parentNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveParentProfile() async {
    final parentId = ref.read(parentIdProvider);
    if (parentId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final updates = {
        'name': _parentNameController.text,
        'username': _usernameController.text,
        'phoneNumber': _phoneController.text,
      };
      if (_selectedAvatar != null) {
        updates['avatarPath'] = _selectedAvatar!;
      }

      await ref.read(firestoreServiceProvider).updateParentSettings(parentId, updates);
      setState(() {
        _isEditingParent = false;
        _showAvatarPickerRow = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _cancelEdit(Map<String, dynamic> settings) {
    setState(() {
      _isEditingParent = false;
      _showAvatarPickerRow = false;
      _parentNameController.text = settings['name'] ?? 'Parent';
      _usernameController.text = settings['username'] ?? '';
      _phoneController.text = settings['phoneNumber'] ?? '';
      _selectedAvatar = null;
    });
  }

  void _showChildDialog([UserProfile? child]) {
    final nameController = TextEditingController(text: child?.name);
    final ageController = TextEditingController(text: child?.age?.toString());
    String selectedGrade = child?.grade ?? 'Standard 1';

    final grades = List.generate(6, (i) => 'Standard ${i + 1}');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(child == null ? 'Add Child' : 'Edit Child'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGrade,
                      decoration: const InputDecoration(labelText: 'Grade'),
                      items: grades.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedGrade = v);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final parentId = ref.read(parentIdProvider);
                    if (parentId.isEmpty) return;

                    final data = {
                      'name': nameController.text,
                      'age': int.tryParse(ageController.text) ?? 0,
                      'grade': selectedGrade,
                    };

                    try {
                      if (child == null) {
                        await ref.read(firestoreServiceProvider).addChild(parentId, data);
                      } else {
                        await ref.read(firestoreServiceProvider).updateChild(parentId, child.uid, data);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentSettingsAsync = ref.watch(parentSettingsProvider);
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.mutedText),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile & Children'),
        actions: [
          if (!_isEditingParent)
            TextButton(
              onPressed: () => setState(() => _isEditingParent = true),
              child: const Text(
                'Edit',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: parentSettingsAsync.when(
        data: (settings) {
          if (!_isEditingParent && _selectedAvatar == null) {
            _parentNameController.text = settings['name'] ?? 'Parent';
            _usernameController.text = settings['username'] ?? '';
            _phoneController.text = settings['phoneNumber'] ?? '';
          }
          final currentAvatar = _selectedAvatar ?? settings['avatarPath'] ?? '🐻';
          final email = FirebaseAuth.instance.currentUser?.email ?? settings['email'] ?? 'Not set';

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _buildSectionLabel('Parent account'),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.border, width: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      children: [
                        // Profile Hero
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _isEditingParent ? () => setState(() => _showAvatarPickerRow = !_showAvatarPickerRow) : null,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        currentAvatar,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                    ),
                                    if (_isEditingParent)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                settings['name'] ?? 'Parent',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.foreground),
                              ),
                              Text(
                                settings['username'] != null ? '@${settings['username']}' : 'Username not set',
                                style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 0.5, color: AppColors.border),
                        
                        // Avatar Picker Row
                        if (_showAvatarPickerRow) ...[
                          _buildAvatarPicker(),
                          const Divider(height: 0.5, color: AppColors.border),
                        ],

                        // Fields
                        _buildFieldRow(
                          icon: Icons.person,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primaryContainer,
                          label: 'Name',
                          value: _parentNameController.text,
                          controller: _parentNameController,
                          isEditing: _isEditingParent,
                        ),
                        _buildFieldRow(
                          icon: Icons.alternate_email,
                          iconColor: AppColors.subjectScience,
                          iconBg: AppColors.accentLight,
                          label: 'Username',
                          value: _usernameController.text != '' ? '@${_usernameController.text}' : '',
                          controller: _usernameController,
                          isEditing: _isEditingParent,
                          prefix: '@',
                        ),
                        _buildFieldRow(
                          icon: Icons.mail_outline,
                          iconColor: AppColors.subjectBm,
                          iconBg: const Color(0xFFE6F1FB),
                          label: 'Email',
                          value: email,
                          isReadOnly: true,
                          actionLabel: 'Cannot change',
                        ),
                        _buildFieldRow(
                          icon: Icons.phone_outlined,
                          iconColor: AppColors.subjectMandarin,
                          iconBg: AppColors.secondaryContainer,
                          label: 'Phone',
                          value: _phoneController.text,
                          controller: _phoneController,
                          isEditing: _isEditingParent,
                        ),
                        _buildFieldRow(
                          icon: Icons.lock_outline,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primaryContainer,
                          label: 'Password',
                          value: '••••••••',
                          actionLabel: 'Change',
                          onAction: () => context.push(AppRouter.changePassword),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Children Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionLabel('Children'),
                      GestureDetector(
                        onTap: () => _showChildDialog(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Add child', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  childrenAsync.when(
                    data: (children) {
                      if (children.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: Text('No children added yet'),
                          ),
                        );
                      }
                      return Column(
                        children: children.map((child) => _buildChildCard(child)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Danger Zone
                  GestureDetector(
                    onTap: null, // Account deletion logic
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.destructive, width: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.destructive, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delete account', style: TextStyle(fontSize: 14, color: AppColors.destructive, fontWeight: FontWeight.w600)),
                                Text('Permanently remove all data', style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.destructive, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Space for save bar
                ],
              ),
              if (_isEditingParent)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _cancelEdit(settings),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedText)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveParentProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Save changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _avatars.length,
        itemBuilder: (context, index) {
          final avatar = _avatars[index];
          final isSelected = _selectedAvatar == avatar;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedAvatar = avatar;
              _showAvatarPickerRow = false;
            }),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(avatar, style: const TextStyle(fontSize: 20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    TextEditingController? controller,
    bool isEditing = false,
    bool isReadOnly = false,
    String? actionLabel,
    VoidCallback? onAction,
    String? prefix,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                if (isEditing && !isReadOnly && controller != null)
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      fillColor: AppColors.muted,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                      prefixText: prefix,
                    ),
                    style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isReadOnly ? AppColors.mutedText : AppColors.foreground,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: actionLabel == 'Cannot change' ? 11 : 12,
                  color: actionLabel == 'Cannot change' ? AppColors.mutedText : AppColors.primary,
                  fontWeight: actionLabel == 'Cannot change' ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChildCard(UserProfile child) {
    // Placeholder stats
    final stars = child.lifetimeStarsEarned;
    final streak = child.streakCount;
    const avgScore = '72%'; // Need actual data if possible
    
    final goalType = child.dailyGoal?.type ?? 'lessons';
    final todayLabel = goalType == 'minutes' ? 'Min today' : 'Today';
    final todayProgress = '${child.dailyGoal?.todayProgress ?? 0}/${child.dailyGoal?.target ?? 3}';
    final todayColor = (child.dailyGoal?.todayProgress ?? 0) >= (child.dailyGoal?.target ?? 3) 
        ? AppColors.subjectScience 
        : (goalType == 'minutes' ? AppColors.destructive : AppColors.foreground);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: child.avatarPath == '🐼' ? const Color(0xFFE6F1FB) : const Color(0xFFEAF3DE),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(child.avatarPath ?? '🦁', style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                      Text(
                        '${child.grade ?? "Standard 1"} · Age ${child.age ?? 7} · Goal: ${child.dailyGoal?.target ?? 3} ${child.dailyGoal?.unitLabel ?? "lessons"}/day',
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildIconBtn(Icons.edit_outlined, AppColors.mutedText, () => _showChildDialog(child)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0.5, color: AppColors.border),
          Row(
            children: [
              _buildStat(stars.toString(), 'Stars', AppColors.primary),
              _buildStat(streak.toString(), 'Day streak', AppColors.subjectScience),
              _buildStat(avgScore, 'Avg score', AppColors.subjectMandarin),
              _buildStat(todayProgress, todayLabel, todayColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildStat(String value, String label, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: valueColor)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}

