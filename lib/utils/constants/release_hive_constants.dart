class ReleaseHiveConstants {

  /// Key prefix for release upload drafts
  static const String draftPrefix = 'release_draft_';

  /// Key prefix for cached file bytes (web resume support)
  static const String fileBytesPrefix = 'release_file_';

  /// Key prefix for cached cover bytes
  static const String coverBytesPrefix = 'release_cover_';

  /// Key for the active draft ID (only one draft at a time)
  static const String activeDraftId = 'active_release_draft_id';

  /// Key for last update timestamp
  static const String lastUpdate = 'release_cache_last_update';

}
