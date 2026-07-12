import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

/// Web Client ID from google-services.json (client_type: 3).
/// This is tied to the Firebase project, not the platform-specific app —
/// same value your old Kotlin app used (WEB_CLIENT_ID in AuthActivity.kt).
/// Required by GoogleSignIn.instance.initialize() as serverClientId,
/// which enables Firebase to verify the Google ID token server-side.
const String kGoogleWebClientId =
    '99859064289-q5ntou392sqsja1ed75163dm4l91mtfg.apps.googleusercontent.com';

Future<void> main() async {
  // Required before any async setup (Firebase, GoogleSignIn) runs before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // google_sign_in 7.x requires explicit initialize() before authenticate()
  // can be called anywhere in the app — skipping this throws a StateError.
  await GoogleSignIn.instance.initialize(
    serverClientId: kGoogleWebClientId,
  );

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
