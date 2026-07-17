import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth_screen.dart';
import '../screens/launch_screen.dart';
import '../screens/room_screen.dart';
import '../screens/contacts_screen.dart';
import '../screens/recording_screen.dart';
import '../screens/export_screen.dart';
import '../widgets/bottom_nav_shell.dart';

/// Route path constants — used instead of hardcoded strings everywhere,
/// so a path typo becomes a compile error instead of a silent bug.
class AppRoutes {
  AppRoutes._();

  static const auth = '/';
  static const launch = '/launch';
  static const room = '/room';
  static const contacts = '/contacts';
  static const recording = '/recording';
  static const export = '/export';
}

/// The app's single GoRouter instance, exposed via Riverpod.
///
/// PHASE 6b UPDATE: Room and Contacts are now wrapped in a
/// StatefulShellRoute.indexedStack — the go_router equivalent of the
/// Kotlin app's BottomNavHelper (which used
/// Intent.FLAG_ACTIVITY_REORDER_TO_FRONT to switch between RoomActivity
/// and ContactsActivity while preserving each screen's state).
/// StatefulShellRoute achieves the same practical effect: each branch
/// (tab) keeps its own navigation stack and widget state alive when you
/// switch away and back, instead of being rebuilt from scratch.
///
/// Auth, Launch, Recording, and Export stay as plain top-level routes
/// OUTSIDE the shell — none of those screens show the bottom nav bar in
/// the Kotlin app either (only RoomActivity/ContactsActivity did).
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.auth,
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.launch,
        builder: (context, state) => const LaunchScreen(),
      ),

      // ── Bottom-nav shell: Room (Chat) + Contacts tabs ──────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.room,
                builder: (context, state) => const RoomScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.contacts,
                builder: (context, state) => const ContactsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes (no bottom nav) ─────────────────────────────
      GoRoute(
        path: AppRoutes.recording,
        builder: (context, state) => const RecordingScreen(),
      ),
      GoRoute(
        path: AppRoutes.export,
        builder: (context, state) => const ExportScreen(),
      ),
    ],
  );
});
