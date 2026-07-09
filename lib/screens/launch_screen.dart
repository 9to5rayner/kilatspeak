import 'package:flutter/material.dart';

/// Placeholder for the Launch screen (API key entry, language picker).
/// Real logic will be added in Phase 6.
class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Launch (stub)')),
      body: Center(
        child: Text(
          'Launch screen — Phase 2 stub',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
