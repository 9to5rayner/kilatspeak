import 'package:flutter/material.dart';

/// Placeholder for the Room screen (create/join ephemeral rooms).
/// Real logic will be added in Phase 6.
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room (stub)')),
      body: Center(
        child: Text(
          'Room screen — Phase 2 stub',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
