import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';
import '../../router/app_router.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addChild() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No logged in parent found.');
      }

      // Save to Firestore sub-collection: parents/{uid}/children/{childId}
      final childRef = await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .add({
            'name': name,
            'avatar': '🐻',
            'stars': 0,
            'activeOutfitID': null,
            'hasSelectedStarterMascot': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        context.go(AppRouter.mascotSelectionFor(childRef.id));
      }
    } catch (e) {
      debugPrint('Error adding child: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add child. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Learner')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryLight,
              child: Text('🐻', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Child\'s Name',
                hintText: 'e.g. Shi Yun',
              ),
              autofocus: true,
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Create Profile',
              onPressed: _addChild,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
