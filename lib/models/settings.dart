import 'package:flutter/material.dart';

/// Which pool of kanji the rotation draws from.
enum DeckMode {
  levels('levels', 'JLPT levels'),
  favorites('favorites', 'Favourites only');

  const DeckMode(this.wireName, this.label);

  final String wireName;
  final String label;

  static DeckMode fromWire(String? value) => DeckMode.values.firstWhere(
    (m) => m.wireName == value,
    orElse: () => DeckMode.levels,
  );
}

/// What causes the card to advance.
enum RotationMode {
  unlock('unlock', 'Every time I wake my phone'),
  interval('interval', 'On a timer');

  const RotationMode(this.wireName, this.label);

  final String wireName;
  final String label;

  static RotationMode fromWire(String? value) => RotationMode.values.firstWhere(
    (m) => m.wireName == value,
    orElse: () => RotationMode.interval,
  );
}

/// Horizontal placement of the card on the wallpaper.
enum CardAlign {
  left('left', 'Left', Icons.format_align_left),
  center('center', 'Centre', Icons.format_align_center),
  right('right', 'Right', Icons.format_align_right);

  const CardAlign(this.wireName, this.label, this.icon);

  final String wireName;
  final String label;
  final IconData icon;

  static CardAlign fromWire(String? value) => CardAlign.values.firstWhere(
    (a) => a.wireName == value,
    orElse: () => CardAlign.left,
  );
}

/// Where the wallpaper backdrop comes from.
enum BackgroundKind {
  preset('preset', 'Built-in'),
  image('image', 'My photo or GIF');

  const BackgroundKind(this.wireName, this.label);

  final String wireName;
  final String label;

  static BackgroundKind fromWire(String? value) =>
      BackgroundKind.values.firstWhere(
        (k) => k.wireName == value,
        orElse: () => BackgroundKind.preset,
      );
}

/// How the home screen widget paints behind the card.
enum WidgetBackground {
  transparent('transparent', 'None'),
  scrim('scrim', 'Soft scrim'),
  solid('solid', 'Solid');

  const WidgetBackground(this.wireName, this.label);

  final String wireName;
  final String label;

  static WidgetBackground fromWire(String? value) =>
      WidgetBackground.values.firstWhere(
        (b) => b.wireName == value,
        orElse: () => WidgetBackground.scrim,
      );
}

/// The rotation intervals offered in the UI.
///
/// Anything below 15 minutes is not offered because Android will not run a
/// background job more often than that, so a shorter interval would be a
/// promise the app cannot keep.
const List<(int minutes, String label)> kIntervalChoices = [
  (15, 'Every 15 minutes'),
  (30, 'Every 30 minutes'),
  (60, 'Every hour'),
  (180, 'Every 3 hours'),
  (360, 'Every 6 hours'),
  (720, 'Every 12 hours'),
  (1440, 'Once a day'),
];

/// A snapshot of everything the native side stores.
///
/// This is a plain immutable value: [copyWith] produces the object that gets
/// sent back over the method channel, so the UI never mutates state in place.
@immutable
class ShibuSettings {
  const ShibuSettings({
    required this.levels,
    required this.deck,
    required this.favorites,
    required this.learned,
    required this.rotationMode,
    required this.intervalMinutes,
    required this.shuffle,
    required this.currentIndex,
    required this.showReading,
    required this.showMeaning,
    required this.showExample,
    required this.textColor,
    required this.fontScale,
    required this.align,
    required this.offsetX,
    required this.offsetY,
    required this.shadow,
    required this.backgroundKind,
    required this.backgroundPreset,
    required this.backgroundAnimate,
    required this.backgroundIsAnimated,
    required this.wallpaperPath,
    required this.wallpaperDim,
    required this.wallpaperColor,
    required this.widgetBackground,
    required this.widgetTextColor,
    required this.onboarded,
  });

  final Set<int> levels;
  final DeckMode deck;
  final Set<int> favorites;
  final Set<int> learned;

  final RotationMode rotationMode;
  final int intervalMinutes;
  final bool shuffle;
  final int currentIndex;

  final bool showReading;
  final bool showMeaning;
  final bool showExample;

  final Color textColor;
  final double fontScale;
  final CardAlign align;
  final double offsetX;
  final double offsetY;
  final bool shadow;

  final BackgroundKind backgroundKind;

  /// Id of the chosen built-in gradient; see [BackgroundPresets].
  final String backgroundPreset;

  /// Whether an animated backdrop is allowed to move. Off shows frame one.
  final bool backgroundAnimate;

  /// Whether the stored file actually has more than one frame. Reported by the
  /// native side, which sniffs the header; the UI hides the animate toggle
  /// when there is nothing to animate.
  final bool backgroundIsAnimated;

  final String? wallpaperPath;
  final double wallpaperDim;
  final Color wallpaperColor;

  final WidgetBackground widgetBackground;
  final Color widgetTextColor;

  final bool onboarded;

  static const ShibuSettings defaults = ShibuSettings(
    levels: {5},
    deck: DeckMode.levels,
    favorites: {},
    learned: {},
    rotationMode: RotationMode.interval,
    intervalMinutes: 60,
    shuffle: true,
    currentIndex: 0,
    showReading: true,
    showMeaning: true,
    showExample: true,
    textColor: Colors.white,
    fontScale: 1.0,
    align: CardAlign.left,
    offsetX: 0.06,
    offsetY: 0.32,
    shadow: true,
    backgroundKind: BackgroundKind.preset,
    backgroundPreset: 'midnight',
    backgroundAnimate: true,
    backgroundIsAnimated: false,
    wallpaperPath: null,
    wallpaperDim: 0.15,
    wallpaperColor: Color(0xFF16202C),
    widgetBackground: WidgetBackground.scrim,
    widgetTextColor: Colors.white,
    onboarded: false,
  );

  factory ShibuSettings.fromMap(Map<dynamic, dynamic> map) {
    Set<int> ints(String key) =>
        (map[key] as List?)?.map((e) => (e as num).toInt()).toSet() ?? <int>{};

    double dbl(String key, double fallback) =>
        (map[key] as num?)?.toDouble() ?? fallback;

    return ShibuSettings(
      levels: ints('levels').isEmpty ? {5} : ints('levels'),
      deck: DeckMode.fromWire(map['deck'] as String?),
      favorites: ints('favorites'),
      learned: ints('learned'),
      rotationMode: RotationMode.fromWire(map['rotationMode'] as String?),
      intervalMinutes: (map['intervalMinutes'] as num?)?.toInt() ?? 60,
      shuffle: map['shuffle'] as bool? ?? true,
      currentIndex: (map['currentIndex'] as num?)?.toInt() ?? 0,
      showReading: map['showReading'] as bool? ?? true,
      showMeaning: map['showMeaning'] as bool? ?? true,
      showExample: map['showExample'] as bool? ?? true,
      textColor: Color((map['textColor'] as num?)?.toInt() ?? 0xFFFFFFFF),
      fontScale: dbl('fontScale', 1.0),
      align: CardAlign.fromWire(map['align'] as String?),
      offsetX: dbl('offsetX', 0.06),
      offsetY: dbl('offsetY', 0.32),
      shadow: map['shadow'] as bool? ?? true,
      backgroundKind: BackgroundKind.fromWire(map['backgroundKind'] as String?),
      backgroundPreset: map['backgroundPreset'] as String? ?? 'midnight',
      backgroundAnimate: map['backgroundAnimate'] as bool? ?? true,
      backgroundIsAnimated: map['backgroundIsAnimated'] as bool? ?? false,
      wallpaperPath: map['wallpaperPath'] as String?,
      wallpaperDim: dbl('wallpaperDim', 0.15),
      wallpaperColor: Color(
        (map['wallpaperColor'] as num?)?.toInt() ?? 0xFF16202C,
      ),
      widgetBackground: WidgetBackground.fromWire(
        map['widgetBackground'] as String?,
      ),
      widgetTextColor: Color(
        (map['widgetTextColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      ),
      onboarded: map['onboarded'] as bool? ?? false,
    );
  }

  /// The payload sent to `applySettings`. Only fields the native side accepts.
  Map<String, dynamic> toMap() => {
    'levels': levels.toList()..sort(),
    'deck': deck.wireName,
    'favorites': favorites.toList()..sort(),
    'learned': learned.toList()..sort(),
    'rotationMode': rotationMode.wireName,
    'intervalMinutes': intervalMinutes,
    'shuffle': shuffle,
    'showReading': showReading,
    'showMeaning': showMeaning,
    'showExample': showExample,
    // Colours must be sent as *signed* 32-bit. toARGB32() returns values above
    // 2^31 for any opaque colour, which the standard codec promotes to Int64,
    // and the Kotlin side reads these as Int. See the round-trip test.
    'textColor': textColor.toARGB32().toSigned(32),
    'fontScale': fontScale,
    'align': align.wireName,
    'offsetX': offsetX,
    'offsetY': offsetY,
    'shadow': shadow,
    'backgroundKind': backgroundKind.wireName,
    'backgroundPreset': backgroundPreset,
    'backgroundAnimate': backgroundAnimate,
    'wallpaperDim': wallpaperDim,
    'wallpaperColor': wallpaperColor.toARGB32().toSigned(32),
    'widgetBackground': widgetBackground.wireName,
    'widgetTextColor': widgetTextColor.toARGB32().toSigned(32),
    'onboarded': onboarded,
  };

  ShibuSettings copyWith({
    Set<int>? levels,
    DeckMode? deck,
    Set<int>? favorites,
    Set<int>? learned,
    RotationMode? rotationMode,
    int? intervalMinutes,
    bool? shuffle,
    int? currentIndex,
    bool? showReading,
    bool? showMeaning,
    bool? showExample,
    Color? textColor,
    double? fontScale,
    CardAlign? align,
    double? offsetX,
    double? offsetY,
    bool? shadow,
    BackgroundKind? backgroundKind,
    String? backgroundPreset,
    bool? backgroundAnimate,
    bool? backgroundIsAnimated,
    String? wallpaperPath,
    bool clearWallpaperPath = false,
    double? wallpaperDim,
    Color? wallpaperColor,
    WidgetBackground? widgetBackground,
    Color? widgetTextColor,
    bool? onboarded,
  }) => ShibuSettings(
    levels: levels ?? this.levels,
    deck: deck ?? this.deck,
    favorites: favorites ?? this.favorites,
    learned: learned ?? this.learned,
    rotationMode: rotationMode ?? this.rotationMode,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    shuffle: shuffle ?? this.shuffle,
    currentIndex: currentIndex ?? this.currentIndex,
    showReading: showReading ?? this.showReading,
    showMeaning: showMeaning ?? this.showMeaning,
    showExample: showExample ?? this.showExample,
    textColor: textColor ?? this.textColor,
    fontScale: fontScale ?? this.fontScale,
    align: align ?? this.align,
    offsetX: offsetX ?? this.offsetX,
    offsetY: offsetY ?? this.offsetY,
    shadow: shadow ?? this.shadow,
    backgroundKind: backgroundKind ?? this.backgroundKind,
    backgroundPreset: backgroundPreset ?? this.backgroundPreset,
    backgroundAnimate: backgroundAnimate ?? this.backgroundAnimate,
    backgroundIsAnimated: backgroundIsAnimated ?? this.backgroundIsAnimated,
    wallpaperPath: clearWallpaperPath
        ? null
        : (wallpaperPath ?? this.wallpaperPath),
    wallpaperDim: wallpaperDim ?? this.wallpaperDim,
    wallpaperColor: wallpaperColor ?? this.wallpaperColor,
    widgetBackground: widgetBackground ?? this.widgetBackground,
    widgetTextColor: widgetTextColor ?? this.widgetTextColor,
    onboarded: onboarded ?? this.onboarded,
  );
}
