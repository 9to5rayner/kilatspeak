import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// The persistent bottom navigation bar wrapping the Room (Chat) and
/// Contacts tabs — ported conceptually from BottomNavHelper.kt.
///
/// [navigationShell] is provided by go_router's StatefulShellRoute; calling
/// navigationShell.goBranch(index) switches tabs while preserving each
/// branch's own navigation stack and state — the same practical effect as
/// the Kotlin version's FLAG_ACTIVITY_REORDER_TO_FRONT.
class BottomNavShell extends StatelessWidget {
  const BottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // initialLocation: true when tapping the already-selected tab
          // resets that tab's stack to its root — matches BottomNavHelper's
          // no-op-if-already-selected behavior closely enough in practice,
          // while still letting a deep stack "pop to root" on re-tap,
          // which is common, expected bottom-nav behavior.
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: AppColors.creamCard,
        indicatorColor: AppColors.goldPale,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: AppColors.navyDeep),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.navyDeep),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: AppColors.navyDeep),
            selectedIcon: Icon(Icons.people, color: AppColors.navyDeep),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }
}
