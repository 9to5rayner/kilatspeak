import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_info_provider.dart';

/// Placeholder for the Auth screen (Google Sign-In).
/// Real logic will be added in Phase 3.
///
/// Phase 2: also serves as the smoke test for Riverpod — reads
/// appVersionProvider and displays it, proving provider -> widget wiring
/// works before we build anything real on top of it.
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Auth (stub)')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Auth screen — Phase 2 stub',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              appVersion,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
