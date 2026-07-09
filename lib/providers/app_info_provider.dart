import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A trivial Riverpod provider used only to prove the pattern works
/// end-to-end (provider defined -> read in a widget -> value displayed).
///
/// This will be deleted once real providers exist (Phase 3 onward,
/// starting with an auth state provider). Its only job right now is to
/// be something we can point at in Phase 2's smoke-test screen.
final appVersionProvider = Provider<String>((ref) => 'KilatSpeak v0.1 (Phase 2 skeleton)');
