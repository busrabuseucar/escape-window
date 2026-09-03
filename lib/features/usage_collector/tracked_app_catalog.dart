class TrackedAppOption {
  const TrackedAppOption({
    required this.label,
    required this.packageName,
    required this.category,
  });

  final String label;
  final String packageName;
  final String category;
}

class TrackedAppCatalog {
  const TrackedAppCatalog._();

  /// Static MVP catalog. We intentionally do not request broad installed-app
  /// visibility (QUERY_ALL_PACKAGES) just to populate this screen.
  static const options = <TrackedAppOption>[
    TrackedAppOption(
      label: 'Instagram',
      packageName: 'com.instagram.android',
      category: 'Sosyal medya',
    ),
    TrackedAppOption(
      label: 'TikTok',
      packageName: 'com.zhiliaoapp.musically',
      category: 'Kısa video',
    ),
    TrackedAppOption(
      label: 'YouTube',
      packageName: 'com.google.android.youtube',
      category: 'Video',
    ),
    TrackedAppOption(
      label: 'X',
      packageName: 'com.twitter.android',
      category: 'Sosyal medya',
    ),
    TrackedAppOption(
      label: 'Facebook',
      packageName: 'com.facebook.katana',
      category: 'Sosyal medya',
    ),
    TrackedAppOption(
      label: 'Snapchat',
      packageName: 'com.snapchat.android',
      category: 'Sosyal medya',
    ),
    TrackedAppOption(
      label: 'Reddit',
      packageName: 'com.reddit.frontpage',
      category: 'Topluluk',
    ),
  ];

  static const defaultPackages = <String>{
    'com.instagram.android',
    'com.zhiliaoapp.musically',
    'com.google.android.youtube',
  };
}
