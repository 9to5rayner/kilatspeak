import 'package:flutter/material.dart';

/// Placeholder for the Contacts screen.
/// Real logic will be added in Phase 7.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts (stub)')),
      body: Center(
        child: Text(
          'Contacts screen — Phase 2 stub',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
