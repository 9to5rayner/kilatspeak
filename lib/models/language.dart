/// The only two languages this app supports, ported from Language.kt.
/// A room/session always translates between exactly these two.
enum Language {
  indonesian('Indonesian', '🇮🇩'),
  english('English', '🇬🇧');

  const Language(this.displayName, this.flag);

  final String displayName;
  final String flag;

  /// The single other language — there are only ever two.
  Language get other => this == Language.indonesian ? Language.english : Language.indonesian;

  /// Parses a stored language name (e.g. from secure storage or Firebase)
  /// back into a Language, defaulting to Indonesian if unrecognized —
  /// matches Language.fromName()'s fallback behavior in the Kotlin app.
  static Language fromName(String? name) {
    return Language.values.firstWhere(
      (l) => l.name == name,
      orElse: () => Language.indonesian,
    );
  }
}
