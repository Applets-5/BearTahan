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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEditingParent = false;
  bool _isLoading = false;

  final List<String> _avatars = [
    '🐻',
    '🐼',
    '🐨',
    '🐯',
    '🦁',
    '🐮',
    '🐷',
    '🐸',
    '🐵',
    '🐔',
  ];

  @override
  void dispose() {
    _parentNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveParentProfile(Map<String, dynamic> currentSettings) async {
    final parentId = ref.read(parentIdProvider);
    if (parentId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(firestoreServiceProvider).updateParentSettings(parentId, {
        'name': _parentNameController.text,
        'username': _usernameController.text,
        'phoneNumber': _phoneController.text,
      });
      setState(() => _isEditingParent = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
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

  void _showAvatarPicker(String currentAvatar) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose Avatar', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.md),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      final parentId = ref.read(parentIdProvider);
                      await ref
                          .read(firestoreServiceProvider)
                          .updateParentSettings(parentId, {
                            'avatarPath': _avatars[index],
                          });
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Center(
                      child: Text(
                        _avatars[index],
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
                        await ref
                            .read(firestoreServiceProvider)
                            .addChild(parentId, data);
                      } else {
                        await ref
                            .read(firestoreServiceProvider)
                            .updateChild(parentId, child.uid, data);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      appBar: AppBar(title: const Text('Profile Details')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Parent Profile Section
              const Text('Parent Account', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.md),
              parentSettingsAsync.when(
                data: (settings) {
                  if (!_isEditingParent) {
                    _parentNameController.text = settings['name'] ?? 'Parent';
                    _usernameController.text = settings['username'] ?? '';
                    _emailController.text =
                        FirebaseAuth.instance.currentUser?.email ??
                        settings['email'] ??
                        '';
                    _phoneController.text = settings['phoneNumber'] ?? '';
                  }
                  final avatar = settings['avatarPath'] ?? '🐻';

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppRadius.r(AppRadius.lg),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showAvatarPicker(avatar),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primaryContainer,
                                child: Text(
                                  avatar,
                                  style: const TextStyle(fontSize: 30),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settings['name'] ?? 'Parent',
                                    style: AppTextStyles.bodyBold,
                                  ),
                                  Text(
                                    settings['username'] != null &&
                                            settings['username']!.isNotEmpty
                                        ? '@${settings['username']}'
                                        : 'Username not set',
                                    style: AppTextStyles.tiny,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isEditingParent ? Icons.check : Icons.edit,
                              ),
                              onPressed: () {
                                if (_isEditingParent) {
                                  _saveParentProfile(settings);
                                } else {
                                  final length =
                                      settings['passwordLength'] ?? 8;
                                  setState(() {
                                    _isEditingParent = true;
                                    _passwordController.text = List.filled(
                                      length,
                                      'x',
                                    ).join();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        if (_isEditingParent) ...[
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _parentNameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            onTap: () => context.push(AppRouter.changePassword),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  hintText: '********',
                                  suffixIcon: Icon(Icons.chevron_right),
                                ),
                                readOnly: true,
                                obscureText: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Login email',
                              helperText:
                                  'Email changes are not available in this version.',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            readOnly: true,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Child Management Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Children', style: AppTextStyles.cardTitle),
                  TextButton.icon(
                    onPressed: () => _showChildDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Child'),
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
                    children: children.map((child) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.r(AppRadius.lg),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.secondaryContainer,
                              child: Icon(Icons.face, color: AppColors.primary),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    child.name,
                                    style: AppTextStyles.bodyBold,
                                  ),
                                  Text(
                                    '${child.grade ?? "Standard 1"} • Age: ${child.age ?? "?"}',
                                    style: AppTextStyles.tiny,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showChildDialog(child),
                            ),
                            IconButton(
                              tooltip:
                                  'Child deletion is unavailable until all associated data can be removed safely.',
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              onPressed: null,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: AppSpacing.xxl),
              TextButton.icon(
                onPressed: null,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  'Account deletion unavailable',
                  style: TextStyle(color: Colors.red),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
