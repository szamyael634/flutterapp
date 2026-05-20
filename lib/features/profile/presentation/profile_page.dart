import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../auth/data/auth_repository.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: AsyncValueView(
        value: profile,
        data: (user) {
          _nameController.text = user.fullName;
          _phoneController.text = user.phone ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(user.email),
                      Text('Role: ${user.role.name}'),
                      Text('Approval: ${user.approvalStatus.name}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  await ref.read(authRepositoryProvider).signOut();
                  if (mounted) {
                    scaffoldMessenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('Logged out')),
                      );
                  }
                },
                child: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
