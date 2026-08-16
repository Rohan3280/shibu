import 'package:flutter/foundation.dart';

import '../models/kanji.dart';
import '../models/settings.dart';
import 'kanji_repository.dart';
import 'shibu_bridge.dart';

/// Single source of truth for the UI.
///
/// Holds the deck and the current settings, pushes every change to the native
/// side, and exposes which kanji is on screen right now. The native side is
/// authoritative about the current card — [currentKanji] is resolved from the
/// id it reports rather than recomputed here — so the preview can never
/// disagree with the lock screen.
class SettingsController extends ChangeNotifier {
  SettingsController({KanjiRepository? repository, ShibuBridge? bridge})
    : _repository = repository ?? KanjiRepository(),
      _bridge = bridge ?? ShibuBridge();

  final KanjiRepository _repository;
  final ShibuBridge _bridge;

  ShibuSettings _settings = ShibuSettings.defaults;
  int? _currentKanjiId;
  bool _wallpaperActive = false;
  int _widgetCount = 0;
  bool _loading = true;
  Object? _error;

  KanjiRepository get repository => _repository;
  ShibuSettings get settings => _settings;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// True when Shibu is the device's active live wallpaper.
  bool get wallpaperActive => _wallpaperActive;

  /// How many Shibu widgets are on the home screen.
  int get widgetCount => _widgetCount;

  List<Kanji> get allKanji => _repository.all;

  /// The card currently shown on the lock screen and widget.
  Kanji? get currentKanji {
    final id = _currentKanjiId;
    if (id != null && id >= 0) {
      final resolved = _repository.byId(id);
      if (resolved != null) return resolved;
    }
    // Only reached before the first channel round-trip, or on a platform
    // without the native side attached (tests, desktop).
    return _repository.current(_settings);
  }

  /// The next few cards, for the "coming up" strip.
  List<Kanji> upcoming({int count = 8}) {
    final ordered = _repository.orderedDeck(_settings);
    if (ordered.isEmpty) return const [];

    final current = currentKanji;
    final start = current == null
        ? 0
        : ordered.indexWhere((k) => k.id == current.id) + 1;
    return List.generate(
      count.clamp(0, ordered.length),
      (i) => ordered[(start + i) % ordered.length],
    );
  }

  int get deckSize => _repository.deck(_settings).length;

  bool isFavorite(Kanji kanji) => _settings.favorites.contains(kanji.id);

  bool isLearned(Kanji kanji) => _settings.learned.contains(kanji.id);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.load();
      _settings = await _bridge.readSettings();
      await _syncStatus();
    } catch (e, stack) {
      _error = e;
      debugPrint('Shibu: failed to load: $e\n$stack');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Re-reads the things the user can change outside the app.
  Future<void> refreshStatus() async {
    await _syncStatus();
    notifyListeners();
  }

  Future<void> _syncStatus() async {
    _currentKanjiId = await _bridge.currentKanjiId();
    _wallpaperActive = await _bridge.isWallpaperActive();
    _widgetCount = await _bridge.widgetCount();
  }

  /// Applies a settings change optimistically, then reconciles with native.
  Future<void> update(ShibuSettings next) async {
    _settings = next;
    notifyListeners();

    _settings = await _bridge.applySettings(next);
    _currentKanjiId = await _bridge.currentKanjiId();
    notifyListeners();
  }

  Future<void> edit(ShibuSettings Function(ShibuSettings) change) =>
      update(change(_settings));

  // Card navigation -------------------------------------------------------

  Future<void> nextKanji() async {
    _currentKanjiId = await _bridge.nextKanji();
    notifyListeners();
  }

  Future<void> previousKanji() async {
    _currentKanjiId = await _bridge.previousKanji();
    notifyListeners();
  }

  /// Pins [kanji] to every surface right now.
  Future<void> showNow(Kanji kanji) async {
    final ok = await _bridge.showKanji(kanji.id);
    if (ok) {
      _currentKanjiId = kanji.id;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Kanji kanji) async {
    final favorites = Set<int>.of(_settings.favorites);
    if (!favorites.remove(kanji.id)) favorites.add(kanji.id);
    await update(_settings.copyWith(favorites: favorites));
  }

  Future<void> toggleLearned(Kanji kanji) async {
    final learned = Set<int>.of(_settings.learned);
    if (!learned.remove(kanji.id)) learned.add(kanji.id);
    await update(_settings.copyWith(learned: learned));
  }

  // System integration ----------------------------------------------------

  Future<bool> openWallpaperPicker() async {
    final opened = await _bridge.openWallpaperPicker();
    return opened;
  }

  /// Returns false when the launcher will not place widgets programmatically,
  /// in which case the caller should explain the manual route.
  Future<bool> requestPinWidget() async {
    final pinned = await _bridge.requestPinWidget();
    if (pinned) await refreshStatus();
    return pinned;
  }

  Future<void> setBackgroundImage(String path) async {
    final stored = await _bridge.setBackgroundImage(path);
    if (stored != null) {
      _settings = _settings.copyWith(wallpaperPath: stored);
      notifyListeners();
    }
  }

  Future<void> clearBackgroundImage() async {
    await _bridge.clearBackgroundImage();
    _settings = _settings.copyWith(clearWallpaperPath: true);
    notifyListeners();
  }

  Future<void> completeOnboarding() =>
      update(_settings.copyWith(onboarded: true));
}
