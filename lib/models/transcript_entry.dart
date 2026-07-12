/// Local UI/session state for a single recorded utterance and its
/// translation pipeline, ported from TranscriptEntry.kt.
///
/// This is NOT persisted to Firebase directly — SessionStore (Phase 4b/5)
/// handles local JSON persistence, and FirebaseRepository (Phase 5) maps
/// the confirmed subset of fields to/from ChatMessage for network sync.
///
/// Dart has no built-in data-class copy() like Kotlin, so copyWith() is
/// hand-written below — this is the standard Dart pattern for immutable
/// state objects and is what Riverpod state updates will use throughout
/// the app (e.g. `state = entry.copyWith(isTranslating: true)`).
class TranscriptEntry {
  const TranscriptEntry({
    required this.id,
    required this.timestampStart,
    required this.timestampEnd,
    this.originalText = '',
    this.translatedText = '',
    this.isEdited = false,
    this.audioFilePath,
    this.senderNickname = '',
    this.isIncoming = false,
    this.isTranscribing = false,
    this.isAwaitingConfirmation = false,
    this.isTranslating = false,
    this.isGeneratingTts = false,
    this.translationError,
    this.ttsError,
    this.isSendingToFirebase = false,
    this.isSentToFirebase = false,
    this.sendError,
  });

  /// Convenience constructor matching Kotlin's default
  /// `id = System.currentTimeMillis()` behavior.
  factory TranscriptEntry.now({
    required int timestampStart,
    required int timestampEnd,
    String originalText = '',
    String senderNickname = '',
    bool isIncoming = false,
    bool isTranscribing = false,
  }) {
    return TranscriptEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      timestampStart: timestampStart,
      timestampEnd: timestampEnd,
      originalText: originalText,
      senderNickname: senderNickname,
      isIncoming: isIncoming,
      isTranscribing: isTranscribing,
    );
  }

  final int id;
  final int timestampStart;
  final int timestampEnd;
  final String originalText;
  final String translatedText;
  final bool isEdited;
  final String? audioFilePath;
  final String senderNickname;
  final bool isIncoming;

  // ── Transient pipeline states — NOT persisted to local JSON store ────────
  final bool isTranscribing;
  final bool isAwaitingConfirmation;
  final bool isTranslating;
  final bool isGeneratingTts;
  final String? translationError;
  final String? ttsError;
  final bool isSendingToFirebase;
  final bool isSentToFirebase;
  final String? sendError;

  TranscriptEntry copyWith({
    int? id,
    int? timestampStart,
    int? timestampEnd,
    String? originalText,
    String? translatedText,
    bool? isEdited,
    String? audioFilePath,
    String? senderNickname,
    bool? isIncoming,
    bool? isTranscribing,
    bool? isAwaitingConfirmation,
    bool? isTranslating,
    bool? isGeneratingTts,
    String? translationError,
    String? ttsError,
    bool? isSendingToFirebase,
    bool? isSentToFirebase,
    String? sendError,
    // Explicit "clear" flags for nullable fields — Dart can't distinguish
    // "not passed" from "passed as null" otherwise, since copyWith's
    // parameters are themselves nullable. Matches the pattern needed
    // wherever Kotlin's copy(field = null) was used (e.g. clearing errors).
    bool clearAudioFilePath = false,
    bool clearTranslationError = false,
    bool clearTtsError = false,
    bool clearSendError = false,
  }) {
    return TranscriptEntry(
      id: id ?? this.id,
      timestampStart: timestampStart ?? this.timestampStart,
      timestampEnd: timestampEnd ?? this.timestampEnd,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      isEdited: isEdited ?? this.isEdited,
      audioFilePath: clearAudioFilePath ? null : (audioFilePath ?? this.audioFilePath),
      senderNickname: senderNickname ?? this.senderNickname,
      isIncoming: isIncoming ?? this.isIncoming,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      isAwaitingConfirmation: isAwaitingConfirmation ?? this.isAwaitingConfirmation,
      isTranslating: isTranslating ?? this.isTranslating,
      isGeneratingTts: isGeneratingTts ?? this.isGeneratingTts,
      translationError: clearTranslationError ? null : (translationError ?? this.translationError),
      ttsError: clearTtsError ? null : (ttsError ?? this.ttsError),
      isSendingToFirebase: isSendingToFirebase ?? this.isSendingToFirebase,
      isSentToFirebase: isSentToFirebase ?? this.isSentToFirebase,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
    );
  }

  /// For local JSON persistence (SessionStore equivalent, Phase 5).
  /// Transient pipeline fields are deliberately excluded — matches
  /// SessionStore.load()'s reset-on-load behavior in the Kotlin app.
  Map<String, dynamic> toJson() => {
        'id': id,
        'timestampStart': timestampStart,
        'timestampEnd': timestampEnd,
        'originalText': originalText,
        'translatedText': translatedText,
        'isEdited': isEdited,
        'audioFilePath': audioFilePath,
        'senderNickname': senderNickname,
        'isIncoming': isIncoming,
      };

  factory TranscriptEntry.fromJson(Map<String, dynamic> json) {
    return TranscriptEntry(
      id: json['id'] as int,
      timestampStart: json['timestampStart'] as int,
      timestampEnd: json['timestampEnd'] as int,
      originalText: json['originalText'] as String? ?? '',
      translatedText: json['translatedText'] as String? ?? '',
      isEdited: json['isEdited'] as bool? ?? false,
      audioFilePath: json['audioFilePath'] as String?,
      senderNickname: json['senderNickname'] as String? ?? '',
      // isIncoming, and all transient fields, always reset to false on
      // load — matches SessionStore.load()'s explicit reset behavior.
      isIncoming: false,
    );
  }
}
