import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth.dart';
import '../../core/theme.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.local_parking, size: 44, color: AppColors.blue),
                const SizedBox(height: 8),
                const Text('ParkVolt', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.navy)),
                const Text('Smart parking & EV charging', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey)),
                const SizedBox(height: 24),
                const Text('Continue as (demo login)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                for (final u in demoUsers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.tonalIcon(
                      onPressed: () => ref.read(userProvider.notifier).login(u),
                      icon: Icon(u.isAdmin ? Icons.admin_panel_settings : Icons.school),
                      label: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(u.name)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
