# KilatSpeak — Development Progress

## App identity
- Name: KilatSpeak
- Package: com.kilattech.kilatspeak
- Stack: Flutter, Firebase (RTDB + Auth), kie.ai (Gemini 3.5 Flash STT/translate, ElevenLabs TTS via kie.ai)
- State management: Riverpod (planned, Phase 2)
- Routing: go_router (planned, Phase 2)

## Phase 1 — DONE
- flutter create with org com.kilattech, project kilatspeak
- Folder structure: lib/models, services, screens, widgets, theme, providers (with .gitkeep placeholders)
- Fixed disk space issue (C: drive) that broke first NDK download
- Fixed android/app/build.gradle.kts: removed deprecated kotlinOptions block,
  migrated to `kotlin { compilerOptions { jvmTarget.set(...) } }` syntax (AGP 9.0 compatibility)
- Confirmed build + deploy to physical Samsung Tab S7 FE (SM-T733, Android 14)
- Known non-blocking warning: project uses older Kotlin Gradle Plugin application method;
  Flutter recommends migrating to "Built-in Kotlin" eventually — deferred, not urgent
- Git repo initialized, pushed to https://github.com/9to5rayner/kilatspeak

## Environment notes
- Git needed: `git config --global --add safe.directory <path>` for each new project folder on this machine
  (or use `git config --global --add safe.directory *` to trust all folders)
- Git identity configured: user.name / user.email set globally

## Next: Phase 2 — Theme, routing, Riverpod skeleton
## Phase 2 — DONE
- Added flutter_riverpod (3.3.2) and go_router (17.3.0) via `flutter pub add`
- Created lib/theme/app_colors.dart and app_theme.dart (ported from Kotlin colors.xml)
- Created 6 stub screens: auth, launch, room, contacts, recording, export
- Created lib/router/app_router.dart with named route constants (AppRoutes class)
- Created lib/providers/app_info_provider.dart as Riverpod smoke test
- Rewired lib/main.dart: ProviderScope -> MaterialApp.router -> AppTheme
- Confirmed on physical device: navy-themed Auth stub screen renders,
  Riverpod provider value displays correctly
- Known warning (non-blocking, deferred): Kotlin Gradle Plugin migration notice

## Next: Phase 3 — Firebase connection + Google Sign-In (Auth screen)
## Phase 3 — DONE
- Installed flutterfire_cli, Firebase CLI; logged in, confirmed kiyolatte project access
- Ran flutterfire configure (Android only) -> lib/firebase_options.dart
- Added firebase_core, firebase_auth, google_sign_in (7.2.0) packages
- Added INTERNET permission to AndroidManifest.xml (was missing from Flutter template)
- Built real Google Sign-In flow in lib/screens/auth_screen.dart using
  google_sign_in 7.x's GoogleSignIn.instance.initialize()/authenticate() API
- Environment fixes along the way:
  - Created C:\Users\rayne\.android\debug.keystore manually (keytool -genkey)
  - kotlin.incremental=false added to android/gradle.properties — Kotlin's
    relocatable incremental cache crashes when project (D:) and pub cache (C:)
    are on different Windows drives ("different roots" error)
  - Windows Defender exclusions added for .gradle, AppProjects, Android SDK
    folders — fixed recurring "immutable workspace modified" cache corruption
- Debugged real SHA-1 mismatch: the certificate actually signing built APKs
  (23:84:5E:00:F8:14:33:CE:63:03:4D:93:B0:54:A1:3A:72:12:A3:F6) differed from
  the one manually created and initially registered (92:2F:BC:B7...) — likely
  AGP auto-generated its own debug keystore before our manual one existed.
  Diagnosed via `apksigner verify --print-certs` on the actual built APK.
  Added the correct fingerprint to Firebase Console; re-downloaded
  google-services.json. Sign-in now works end-to-end on physical device.
- KNOWN ISSUE (unresolved, not blocking): root cause of the dual-keystore
  situation itself not confirmed — only the symptom was fixed. Revisit if
  signing issues recur.

## Next: Phase 4 — Secure storage + data models