import 'package:flutter/material.dart';

/// Placeholder for the Export screen (share as TXT/SRT).
/// Real logic will be added in Phase 11.
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export (stub)')),
      body: Center(
        child: Text(
          'Export screen — Phase 2 stub',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
