import 'package:flutter/material.dart';

/// Placeholder for the Recording/Chat screen — the core feature screen.
/// Real logic will be added in Phase 9.
class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recording (stub)')),
      body: Center(
        child: Text(
          'Recording screen — Phase 2 stub',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
