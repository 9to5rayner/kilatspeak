/// A fully-resolved message in the walkie-talkie conversation, ported from
/// ChatMessage.kt.
///
/// PERSISTED fields (written to Firebase RTDB via toMap()):
///   id, senderId, senderNickname, timestampMs, originalText,
///   translatedText, sourceLang, targetLang
///
/// LOCAL-ONLY fields (excluded from toMap() — Kotlin used @get:Exclude for
/// these; Dart's firebase_database has no reflection-based exclusion
/// mechanism, so we simply don't include them in the map we write):
///   isIncoming, isPending, isSentToFirebase, localAudioPath,
///   ttsError, isGeneratingTts
class ChatMessage {
  const ChatMessage({
    this.id = '',
    this.senderId = '',
    this.senderNickname = '',
    this.timestampMs = 0,
    this.originalText = '',
    this.translatedText = '',
    this.sourceLang = 'INDONESIAN',
    this.targetLang = 'ENGLISH',
    this.isIncoming = false,
    this.isPending = false,
    this.isSentToFirebase = false,
    this.localAudioPath,
    this.isGeneratingTts = false,
    this.ttsError,
  });

  // ── Persisted to Firebase ─────────────────────────────────────────────────
  final String id;
  final String senderId;
  final String senderNickname;
  final int timestampMs;
  final String originalText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;

  // ── Local-only UI state ───────────────────────────────────────────────────
  final bool isIncoming;
  final bool isPending;
  final bool isSentToFirebase;
  final String? localAudioPath;
  final bool isGeneratingTts;
  final String? ttsError;

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderNickname,
    int? timestampMs,
    String? originalText,
    String? translatedText,
    String? sourceLang,
    String? targetLang,
    bool? isIncoming,
    bool? isPending,
    bool? isSentToFirebase,
    String? localAudioPath,
    bool? isGeneratingTts,
    String? ttsError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderNickname: senderNickname ?? this.senderNickname,
      timestampMs: timestampMs ?? this.timestampMs,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      isIncoming: isIncoming ?? this.isIncoming,
      isPending: isPending ?? this.isPending,
      isSentToFirebase: isSentToFirebase ?? this.isSentToFirebase,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      isGeneratingTts: isGeneratingTts ?? this.isGeneratingTts,
      ttsError: ttsError ?? this.ttsError,
    );
  }

  /// Only persisted fields are written to Firebase — matches @get:Exclude
  /// semantics from the Kotlin version.
  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'senderNickname': senderNickname,
        'timestampMs': timestampMs,
        'originalText': originalText,
        'translatedText': translatedText,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
      };

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderNickname: map['senderNickname'] as String? ?? '',
      timestampMs: map['timestampMs'] as int? ?? 0,
      originalText: map['originalText'] as String? ?? '',
      translatedText: map['translatedText'] as String? ?? '',
      sourceLang: map['sourceLang'] as String? ?? 'INDONESIAN',
      targetLang: map['targetLang'] as String? ?? 'ENGLISH',
    );
  }
}
