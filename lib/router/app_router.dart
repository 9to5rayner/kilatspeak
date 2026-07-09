import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth_screen.dart';
import '../screens/launch_screen.dart';
import '../screens/room_screen.dart';
import '../screens/contacts_screen.dart';
import '../screens/recording_screen.dart';
import '../screens/export_screen.dart';

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

/// The app's single GoRouter instance, exposed via Riverpod so screens
/// can access navigation-related state later (e.g. redirect logic based
/// on auth state) without passing the router down through constructors.
///
/// Phase 2: just wires up the six stub screens with simple named routes.
/// Phase 3+ will add real navigation logic (auth-gated redirects, passing
/// arguments like room codes / contact info between screens, and a
/// StatefulShellRoute for the Chat/Contacts bottom nav — the Flutter
/// equivalent of BottomNavHelper's FLAG_ACTIVITY_REORDER_TO_FRONT pattern).
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
      GoRoute(
        path: AppRoutes.room,
        builder: (context, state) => const RoomScreen(),
      ),
      GoRoute(
        path: AppRoutes.contacts,
        builder: (context, state) => const ContactsScreen(),
      ),
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
