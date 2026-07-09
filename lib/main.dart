import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'router/app_router.dart';

void main() {
  // ProviderScope must wrap the whole app for Riverpod providers to work
  // anywhere in the widget tree below it.
  runApp(const ProviderScope(child: KilatSpeakApp()));
}

/// Root widget. ConsumerWidget (not StatelessWidget) because it needs to
/// read appRouterProvider via Riverpod's `ref`.
class KilatSpeakApp extends ConsumerWidget {
  const KilatSpeakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'KilatSpeak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
