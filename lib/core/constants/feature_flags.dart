/// Feature flags controlling rollout of capabilities.
class FeatureFlags {
  FeatureFlags._();

  /// Whether payment reminders are enabled in the UI.
  /// Set to false for v1.0, to be re-enabled in v1.1.
  static const bool kRemindersEnabled = false;
}
