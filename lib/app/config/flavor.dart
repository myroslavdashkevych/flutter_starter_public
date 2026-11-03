enum Flavor {
  dev,
  prod;

  /// Whether crash reports and analytics are sent: always in dev, where the
  /// Firebase project exists for this, and outside debug builds in prod.
  bool collectsUsageData({required bool isDebug}) => this == dev || !isDebug;

  /// Maps the value of `appFlavor`. A missing or unknown name means the app was
  /// built without a valid `--flavor`, so it fails at startup.
  static Flavor fromName(String? name) => switch (name) {
    'dev' => dev,
    'prod' => prod,
    _ => throw StateError('Unknown flavor: $name'),
  };
}
