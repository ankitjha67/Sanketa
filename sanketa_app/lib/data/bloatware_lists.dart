/// Per-brand bloatware package lists for TV debloating.
///
/// Curated from cleanyourtv analysis. Each entry marks a package as safe,
/// moderate, or risky to disable — and whether it is recommended for the
/// one-tap "Speed Up" preset.
library;

enum BloatCategory { ads, bloatware, telemetry, systemApp }

enum RiskLevel { safe, moderate, risky }

class BloatwareEntry {
  const BloatwareEntry({
    required this.packageName,
    required this.displayName,
    required this.category,
    this.description = '',
    this.riskLevel = RiskLevel.safe,
    this.isRecommended = false,
  });

  final String packageName;
  final String displayName;
  final BloatCategory category;
  final String description;
  final RiskLevel riskLevel;
  final bool isRecommended;
}

class BloatwareDatabase {
  const BloatwareDatabase._();

  static const Map<String, List<BloatwareEntry>> brands = {
    'xiaomi': _xiaomi,
    'samsung': _samsung,
    'philips': _philips,
    'hisense': _hisense,
    'tcl': _tcl,
    'sony': _sony,
    'generic': _generic,
  };

  static List<BloatwareEntry> forBrand(String brand) {
    final key = brand.toLowerCase();
    return brands[key] ?? _generic;
  }

  static List<String> get supportedBrands => brands.keys.toList();

  static String detectBrand(String model, String manufacturer) {
    final hay = '$model $manufacturer'.toLowerCase();
    if (hay.contains('xiaomi') || hay.contains('mi tv') || hay.contains('redmi')) return 'xiaomi';
    if (hay.contains('samsung') || hay.contains('tizen')) return 'samsung';
    if (hay.contains('philips')) return 'philips';
    if (hay.contains('hisense') || hay.contains('vidaa')) return 'hisense';
    if (hay.contains('tcl')) return 'tcl';
    if (hay.contains('sony') || hay.contains('bravia')) return 'sony';
    return 'generic';
  }

  static const _xiaomi = <BloatwareEntry>[
    BloatwareEntry(
      packageName: 'com.miui.systemAdSolution',
      displayName: 'MIUI Ad Services',
      category: BloatCategory.ads,
      description: 'System-level ad delivery framework',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.miui.analytics',
      displayName: 'MIUI Analytics',
      category: BloatCategory.telemetry,
      description: 'Usage telemetry and crash reporting',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.miui.msa',
      displayName: 'MSA (MIUI System Ads)',
      category: BloatCategory.ads,
      description: 'Main ad SDK embedded in system apps',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.content.center',
      displayName: 'Content Center',
      category: BloatCategory.ads,
      description: 'Sponsored content recommendations',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.shop',
      displayName: 'Mi TV Shop',
      category: BloatCategory.bloatware,
      description: 'Shopping app on the TV launcher',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.tvpush',
      displayName: 'TV Push Notifications',
      category: BloatCategory.ads,
      description: 'Push notification ads',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.glgm',
      displayName: 'Mi Game Center',
      category: BloatCategory.bloatware,
      description: 'Game store and recommendations',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.miui.hybrid',
      displayName: 'Quick Apps',
      category: BloatCategory.bloatware,
      description: 'Instant app framework with ads',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.smartshare',
      displayName: 'Smart Share',
      category: BloatCategory.bloatware,
      description: 'Built-in file sharing (replaced by cast)',
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.payment',
      displayName: 'Payment Service',
      category: BloatCategory.bloatware,
      description: 'In-TV payment processing',
    ),
    BloatwareEntry(
      packageName: 'com.mi.global.bbs',
      displayName: 'Mi Community',
      category: BloatCategory.bloatware,
      description: 'Community forum app',
    ),
    BloatwareEntry(
      packageName: 'com.miui.daemon',
      displayName: 'Mi Daemon',
      category: BloatCategory.telemetry,
      description: 'Background telemetry service',
      riskLevel: RiskLevel.moderate,
    ),
    BloatwareEntry(
      packageName: 'com.miui.cleanmaster',
      displayName: 'Clean Master',
      category: BloatCategory.bloatware,
      description: 'System cleaner with ads',
    ),
    BloatwareEntry(
      packageName: 'com.miui.miwallpaper',
      displayName: 'Mi Wallpaper',
      category: BloatCategory.bloatware,
      description: 'Wallpaper service with sponsored content',
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.calendar',
      displayName: 'Calendar',
      category: BloatCategory.bloatware,
      description: 'TV calendar app',
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.account',
      displayName: 'Mi Account',
      category: BloatCategory.bloatware,
      description: 'Xiaomi account services',
      riskLevel: RiskLevel.moderate,
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.appstore',
      displayName: 'Mi App Store',
      category: BloatCategory.bloatware,
      description: 'Xiaomi app marketplace',
      riskLevel: RiskLevel.moderate,
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.upgrade',
      displayName: 'OTA Updater',
      category: BloatCategory.systemApp,
      description: 'System update service — disabling stops OTA updates',
      riskLevel: RiskLevel.risky,
    ),
    BloatwareEntry(
      packageName: 'com.miui.securitycenter',
      displayName: 'Security Center',
      category: BloatCategory.systemApp,
      description: 'Security suite with ads and telemetry',
      riskLevel: RiskLevel.risky,
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.tvvideo',
      displayName: 'TV Video',
      category: BloatCategory.bloatware,
      description: 'Built-in video app with ads',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.miui.bugreport',
      displayName: 'Bug Report',
      category: BloatCategory.telemetry,
      description: 'Crash reporting tool',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.themecenter',
      displayName: 'Theme Center',
      category: BloatCategory.bloatware,
      description: 'Theme downloads with ads',
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.music',
      displayName: 'Mi Music',
      category: BloatCategory.bloatware,
      description: 'Built-in music player with ads',
    ),
    BloatwareEntry(
      packageName: 'com.xiaomi.mitv.karaoke',
      displayName: 'Mi Karaoke',
      category: BloatCategory.bloatware,
      description: 'Karaoke app',
    ),
  ];

  static const _samsung = <BloatwareEntry>[
    BloatwareEntry(
      packageName: 'com.samsung.android.app.spage',
      displayName: 'Samsung Free / TV Plus',
      category: BloatCategory.ads,
      description: 'Free ad-supported channels and content',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.samsung.android.smartsuggestions',
      displayName: 'Smart Suggestions',
      category: BloatCategory.ads,
      description: 'Personalized ad recommendations',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.samsung.instantplay',
      displayName: 'Instant Play',
      category: BloatCategory.ads,
      description: 'Auto-play ad content on home screen',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.samsung.tv.bixby',
      displayName: 'Bixby',
      category: BloatCategory.bloatware,
      description: 'Samsung voice assistant',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.samsung.tv.game',
      displayName: 'Samsung Game',
      category: BloatCategory.bloatware,
      description: 'Game streaming service',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.samsung.tv.game.launcher',
      displayName: 'Game Launcher',
      category: BloatCategory.bloatware,
      description: 'Game discovery and launcher',
    ),
    BloatwareEntry(
      packageName: 'com.samsung.tv.samsung-health',
      displayName: 'Samsung Health TV',
      category: BloatCategory.bloatware,
      description: 'Health and fitness on TV',
    ),
    BloatwareEntry(
      packageName: 'com.samsung.tv.ambient',
      displayName: 'Ambient Mode',
      category: BloatCategory.ads,
      description: 'Screen saver with sponsored content',
    ),
    BloatwareEntry(
      packageName: 'com.sec.android.app.sbrowser',
      displayName: 'Samsung Browser',
      category: BloatCategory.bloatware,
      description: 'Built-in web browser',
    ),
    BloatwareEntry(
      packageName: 'com.samsung.android.bbc.bbcagent',
      displayName: 'BBC Agent',
      category: BloatCategory.bloatware,
      description: 'Pre-installed BBC service',
    ),
    BloatwareEntry(
      packageName: 'com.samsung.android.game.gamehome',
      displayName: 'Game Home',
      category: BloatCategory.bloatware,
      description: 'Gaming hub',
    ),
    BloatwareEntry(
      packageName: 'com.sec.android.app.billing',
      displayName: 'Samsung Billing',
      category: BloatCategory.bloatware,
      description: 'In-app purchase framework',
      riskLevel: RiskLevel.moderate,
    ),
    BloatwareEntry(
      packageName: 'com.samsung.android.tvplus',
      displayName: 'Samsung TV Plus',
      category: BloatCategory.ads,
      description: 'Ad-supported live TV channels',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.samsung.android.rubin.app',
      displayName: 'Samsung AI',
      category: BloatCategory.telemetry,
      description: 'AI usage data collection',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.samsung.android.app.tips',
      displayName: 'Samsung Tips',
      category: BloatCategory.bloatware,
      description: 'Tip notifications with promotions',
    ),
    BloatwareEntry(
      packageName: 'com.samsung.android.samsungpass',
      displayName: 'Samsung Pass',
      category: BloatCategory.bloatware,
      description: 'Biometric password manager',
      riskLevel: RiskLevel.moderate,
    ),
  ];

  static const _philips = <BloatwareEntry>[
    BloatwareEntry(
      packageName: 'com.philips.recommender',
      displayName: 'Philips Recommender',
      category: BloatCategory.ads,
      description: 'Content recommendation engine with ads',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.philips.datasharing',
      displayName: 'Data Sharing',
      category: BloatCategory.telemetry,
      description: 'Usage telemetry service',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.philips.survey',
      displayName: 'Philips Survey',
      category: BloatCategory.telemetry,
      description: 'User survey pop-ups',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'org.nicetv.oversea',
      displayName: 'NiceTV (Overseas)',
      category: BloatCategory.bloatware,
      description: 'Pre-installed streaming app',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.nicetv.nicetv',
      displayName: 'NiceTV',
      category: BloatCategory.bloatware,
      description: 'Built-in TV content app',
    ),
    BloatwareEntry(
      packageName: 'com.philips.saphi.launcher',
      displayName: 'Saphi Launcher',
      category: BloatCategory.ads,
      description: 'Smart TV launcher with sponsored tiles',
      riskLevel: RiskLevel.moderate,
    ),
    BloatwareEntry(
      packageName: 'com.philips.cloudtv',
      displayName: 'Cloud TV',
      category: BloatCategory.bloatware,
      description: 'Cloud-based TV services',
    ),
    BloatwareEntry(
      packageName: 'com.philips.tvguide',
      displayName: 'TV Guide',
      category: BloatCategory.bloatware,
      description: 'Electronic program guide',
    ),
    BloatwareEntry(
      packageName: 'com.philips.tpvision.tvapp',
      displayName: 'Philips TV App',
      category: BloatCategory.bloatware,
      description: 'TPVision framework',
    ),
    BloatwareEntry(
      packageName: 'com.philips.faq',
      displayName: 'FAQ',
      category: BloatCategory.bloatware,
      description: 'Built-in FAQ app',
    ),
  ];

  static const _hisense = <BloatwareEntry>[
    BloatwareEntry(
      packageName: 'com.hisense.hitv.channelshelf',
      displayName: 'Channel Shelf',
      category: BloatCategory.ads,
      description: 'Sponsored channel recommendations on home screen',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.hisense.smarttv.push',
      displayName: 'Push Notifications',
      category: BloatCategory.ads,
      description: 'Push notification ads',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.vidaa.recommendations',
      displayName: 'VIDAA Recommendations',
      category: BloatCategory.ads,
      description: 'Content recommendations with ads',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.hisense.hitv.homepage',
      displayName: 'Homepage Ads',
      category: BloatCategory.ads,
      description: 'Ad widgets on the home screen',
    ),
    BloatwareEntry(
      packageName: 'com.hisense.hitv.market',
      displayName: 'Hisense App Market',
      category: BloatCategory.bloatware,
      description: 'Built-in app store',
      riskLevel: RiskLevel.moderate,
    ),
    BloatwareEntry(
      packageName: 'com.hisense.hitv.user',
      displayName: 'User Center',
      category: BloatCategory.telemetry,
      description: 'Account and telemetry service',
    ),
    BloatwareEntry(
      packageName: 'com.hisense.hitv.weather',
      displayName: 'Weather',
      category: BloatCategory.bloatware,
      description: 'Weather widget',
    ),
    BloatwareEntry(
      packageName: 'com.hisense.hitv.music',
      displayName: 'Hisense Music',
      category: BloatCategory.bloatware,
      description: 'Built-in music player',
    ),
    BloatwareEntry(
      packageName: 'com.vidaa.voice',
      displayName: 'VIDAA Voice',
      category: BloatCategory.bloatware,
      description: 'Voice assistant',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.hisense.hitv.dataservice',
      displayName: 'Data Service',
      category: BloatCategory.telemetry,
      description: 'Background data collection',
      isRecommended: true,
    ),
  ];

  static const _tcl = <BloatwareEntry>[
    BloatwareEntry(
      packageName: 'com.tcl.contentcenter',
      displayName: 'Content Center',
      category: BloatCategory.ads,
      description: 'Sponsored content hub',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.tcl.usercenter',
      displayName: 'User Center',
      category: BloatCategory.telemetry,
      description: 'Usage tracking service',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.tcl.tv.launcher',
      displayName: 'TCL Launcher',
      category: BloatCategory.ads,
      description: 'Launcher with ad tiles',
      riskLevel: RiskLevel.moderate,
    ),
    BloatwareEntry(
      packageName: 'com.tcl.appmarket',
      displayName: 'TCL App Market',
      category: BloatCategory.bloatware,
      description: 'Built-in app store',
    ),
    BloatwareEntry(
      packageName: 'com.tcl.notereminder',
      displayName: 'Note Reminder',
      category: BloatCategory.bloatware,
      description: 'Built-in notes app',
    ),
    BloatwareEntry(
      packageName: 'com.tcl.bi',
      displayName: 'TCL Analytics',
      category: BloatCategory.telemetry,
      description: 'Business intelligence telemetry',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.tcl.weather',
      displayName: 'Weather',
      category: BloatCategory.bloatware,
      description: 'Weather widget',
    ),
    BloatwareEntry(
      packageName: 'com.tcl.gallery',
      displayName: 'Gallery',
      category: BloatCategory.bloatware,
      description: 'Photo gallery app',
    ),
  ];

  static const _sony = <BloatwareEntry>[
    BloatwareEntry(
      packageName: 'com.sony.dtv.tvmonitoring',
      displayName: 'TV Monitoring',
      category: BloatCategory.telemetry,
      description: 'Usage monitoring and reporting',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.sony.dtv.recommendation',
      displayName: 'Recommendations',
      category: BloatCategory.ads,
      description: 'Content recommendation ads',
    ),
    BloatwareEntry(
      packageName: 'com.sony.dtv.tvx',
      displayName: 'TV Experience',
      category: BloatCategory.ads,
      description: 'Sony TV experience framework with promotions',
    ),
    BloatwareEntry(
      packageName: 'com.sony.dtv.osat',
      displayName: 'Sony Analytics',
      category: BloatCategory.telemetry,
      description: 'Analytics and telemetry',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.sony.dtv.sonyselect',
      displayName: 'Sony Select',
      category: BloatCategory.bloatware,
      description: 'Curated app recommendations',
    ),
    BloatwareEntry(
      packageName: 'com.sony.dtv.fotaagent',
      displayName: 'FOTA Agent',
      category: BloatCategory.systemApp,
      description: 'Firmware-over-the-air update agent',
      riskLevel: RiskLevel.risky,
    ),
  ];

  static const _generic = <BloatwareEntry>[
    BloatwareEntry(
      packageName: 'com.google.android.tvrecommendations',
      displayName: 'TV Recommendations',
      category: BloatCategory.ads,
      description: 'Sponsored recommendations row on home',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.google.android.leanbacklauncher.recommendations',
      displayName: 'Leanback Recommendations',
      category: BloatCategory.ads,
      description: 'Legacy recommendation row',
      isRecommended: true,
    ),
    BloatwareEntry(
      packageName: 'com.google.android.katniss',
      displayName: 'Google Assistant TV',
      category: BloatCategory.bloatware,
      description: 'Voice assistant (can be re-enabled anytime)',
    ),
    BloatwareEntry(
      packageName: 'com.google.android.apps.tv.launcherx',
      displayName: 'Google TV Home',
      category: BloatCategory.ads,
      description: 'Google TV launcher with sponsored content',
      riskLevel: RiskLevel.moderate,
    ),
    BloatwareEntry(
      packageName: 'com.google.android.youtube.tvunplugged',
      displayName: 'YouTube TV',
      category: BloatCategory.bloatware,
      description: 'Pre-installed YouTube TV subscription promo',
    ),
    BloatwareEntry(
      packageName: 'com.google.android.backdrop',
      displayName: 'Backdrop',
      category: BloatCategory.bloatware,
      description: 'Screensaver/ambient display with suggested content',
    ),
    BloatwareEntry(
      packageName: 'com.google.android.tungsten.setupwraith',
      displayName: 'Setup Wizard',
      category: BloatCategory.systemApp,
      description: 'First-time setup — only safe to disable after setup',
      riskLevel: RiskLevel.risky,
    ),
    BloatwareEntry(
      packageName: 'com.google.android.marvin.talkback',
      displayName: 'TalkBack',
      category: BloatCategory.bloatware,
      description: 'Accessibility screen reader (keep if needed)',
      riskLevel: RiskLevel.moderate,
    ),
  ];
}
