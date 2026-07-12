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
## Phase 4a — DONE
- Added flutter_secure_storage (10.3.1) and crypto (3.0.7) packages
- Created lib/services/secure_storage_service.dart (equivalent of SecurePrefs.kt),
  wraps Android Keystore / iOS Keychain via flutter_secure_storage
- Ported 8 Kotlin data model classes to plain Dart classes in lib/models/:
  Language, TranscriptEntry, ChatMessage, ContactEntry, ContactRequest + SentRequest,
  DirectRoom, UserProfile, AppNotification
- Architecture note: Dart's firebase_database has no reflection-based object
  mapping like Kotlin's SDK (snapshot.getValue(Class)) — every model has explicit
  toMap()/fromMap() methods instead
- DirectRoom.computeRoomId() ported using package:crypto's sha256 (matches Kotlin's
  MessageDigest SHA-256 exactly); generateEncryptionKey() uses Random.secure()
  (Dart's SecureRandom equivalent)
- Dart has no built-in data-class copy() — hand-wrote copyWith() on TranscriptEntry
  and ChatMessage following standard Dart immutable-state conventions
- Fixed 2 issues caught by `flutter analyze`:
  - Removed deprecated `encryptedSharedPreferences` param (flutter_secure_storage 10.x
    auto-migrates ciphers now, param is a no-op and being removed in v11)
  - Fixed stale test/widget_test.dart referencing nonexistent `MyApp` class
    (leftover from Phase 2's main.dart rewrite — analyzer wasn't run until now)
- `flutter analyze` and `flutter test` both clean

## Next: Phase 4b — Port RoomCrypto (AES-256-GCM + PBKDF2 encryption)
Deferred to its own session — security-sensitive code deserves focused attention.
Will use package:cryptography for AES-256-GCM. Two construction modes to port:
  - Ephemeral rooms: PBKDF2-HMAC-SHA256 (100,000 iterations) key derivation from room code
  - Direct rooms: raw 256-bit key (already generated in DirectRoom.generateEncryptionKey())
Wire format unchanged: Base64(IV[12 bytes] || GCM-ciphertext[n+16 bytes])
Plan: verify Dart-encrypted messages decrypt correctly, ideally cross-check against
known test vectors rather than only round-tripping within Dart alone.
## Phase 4b — DONE
- Added cryptography (2.9.0) package for AES-256-GCM + PBKDF2
- Ported RoomCrypto.kt to lib/crypto/room_crypto.dart:
  - RoomCrypto.forRoomCode() — ephemeral rooms, PBKDF2-HMAC-SHA256 (100,000
    iterations) lazy key derivation, memoized via cached Future<SecretKeyData>
  - RoomCrypto.forRawKey() — direct/contact rooms, uses pre-existing 256-bit
    key from DirectRoom.generateEncryptionKey() directly, no PBKDF2
  - Wire format unchanged: Base64(IV[12 bytes] || GCM-ciphertext || GCM-tag[16 bytes])
  - Uses AesGcm.with256bits() from package:cryptography
- DECISION: PBKDF2 password encoding uses standard UTF-8, NOT guaranteed
  byte-compatible with old Kotlin app's javax.crypto.spec.PBEKeySpec char[]
  handling. Treated as acceptable since KilatSpeak is a fresh rewrite with
  new users — not decrypting old Kotlin-encrypted ephemeral room messages.
  Salt constant kept identical to Kotlin's ("com.example.groqtranscriber.roomkey")
  since it's an internal parameter never shown to users.
- Wrote 12 unit tests in test/crypto/room_crypto_test.dart covering:
  round-trip encryption (both room modes), cross-instance decryption
  (simulating two devices sharing a room code), case-insensitivity/trimming,
  wrong-key rejection, GCM tamper detection (single-byte flip breaks
  decryption), and malformed/truncated input handling
- All 12 tests passing — verified via `flutter test`, no device needed

## Data model + crypto layer (Phase 4a + 4b) is now complete:
lib/models/ (8 classes), lib/services/secure_storage_service.dart,
lib/crypto/room_crypto.dart — all ready to be wired into a real Firebase
repository layer in Phase 5.

## Next: Phase 5 — Firebase repository layer
Port FirebaseRepository.kt, ContactRepository.kt, NotificationRepository.kt
to Dart using package:firebase_database. Stream-based sendMessage/
listenForMessages equivalents. Logic-only phase — no UI yet, verify with
a throwaway test screen or debug prints before building real screens on top.
## Phase 5 — DONE
- Added firebase_database (12.4.4) package
- Ported all three Kotlin repository classes to lib/services/:
  - firebase_repository.dart — message send/receive for both ephemeral and
    direct rooms. sendMessage() encrypts via RoomCrypto then writes;
    listenForMessages() uses ref.onChildAdded stream (Dart equivalent of
    Kotlin's ChildEventListener), filters to new/other-sender messages only,
    decrypts, drops+logs messages that fail decryption
  - contact_repository.dart — full contact request lifecycle (send/accept/
    decline with the same 3-guard checks as Kotlin), direct room creation
    on accept, 3 real-time listeners (contacts, incoming requests, sent
    requests), email lookup/uid lookup
  - notification_repository.dart — RTDB notification queue with
    attachedAt-timestamp filtering (foreground-only for now, per the
    Phase 10 free-tier decision already logged)
- Architecture notes / decisions made during the port:
  - Dart's firebase_database uses Streams (onChildAdded, onValue) instead
    of Kotlin's ChildEventListener/ValueEventListener callback interfaces —
    same semantics, different syntax
  - No UUID package added — notification/message IDs use Firebase's own
    ref().push().key instead of Kotlin's UUID.randomUUID(). Functionally
    equivalent (unique, sortable) but different string format. Flagged as
    a deliberate choice, not silently changed.
  - Kotlin's suspend functions + suspendCancellableCoroutine map directly
    onto plain Dart async/await Futures — no bridging layer needed
  - Learned correct Dart initializing-formal syntax: `required this._field`
    exposes the PUBLIC (non-underscore) name at call sites, e.g.
    `ContactRepository(myUid: ..., myName: ..., myEmail: ...)`
- `flutter analyze`: zero issues (errors or info-level) after fixes

## UI DIRECTION NOTE (for Phase 6 onward)
User wants the chat/messaging UI inspired by WhatsApp's layout conventions
(familiar structure — chat list, bubble alignment, bottom input bar) for
easy user adoption, while keeping KilatSpeak's own navy/gold/cream visual
identity rather than copying WhatsApp's actual color scheme. Apply this
directive starting with Phase 6 (Launch/Room screens) and especially
Phase 9 (the core Recording/Chat screen).

## Next: Phase 6 — Launch & Room screens
API key entry (wired to SecureStorageService), language picker, room
code generate/join (ephemeral rooms), bottom nav (Chat/Contacts) using
go_router's StatefulShellRoute.