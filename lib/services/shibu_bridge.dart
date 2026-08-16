import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/settings.dart';

/// Thin wrapper over the platform method channel.
///
/// Settings are owned by the native side rather than by Dart, because the live
/// wallpaper and the home screen widget run without a Flutter engine attached
/// and must be able to read them directly.
class ShibuBridge {
  ShibuBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.shibu.app/bridge');

  final MethodChannel _channel;

  Future<ShibuSettings> readSettings() async {
    final map = await _invoke<Map<dynamic, dynamic>>('readSettings');
    return map == null ? ShibuSettings.defaults : ShibuSettings.fromMap(map);
  }

  /// Writes [settings] and returns the state the native side settled on.
  Future<ShibuSettings> applySettings(ShibuSettings settings) async {
    final map = await _invoke<Map<dynamic, dynamic>>(
      'applySettings',
      settings.toMap(),
    );
    return map == null ? settings : ShibuSettings.fromMap(map);
  }

  Future<int?> currentKanjiId() => _invoke<int>('currentKanjiId');

  Future<int?> nextKanji() => _invoke<int>('nextKanji');

  Future<int?> previousKanji() => _invoke<int>('previousKanji');

  /// Pins a specific kanji to every surface immediately.
  Future<bool> showKanji(int id) async =>
      await _invoke<bool>('showKanji', {'id': id}) ?? false;

  Future<void> refreshSurfaces() => _invoke<bool>('refreshSurfaces');

  /// Copies the chosen photo into app storage; returns its new path.
  Future<String?> setBackgroundImage(String path) =>
      _invoke<String>('setBackgroundImage', {'path': path});

  Future<void> clearBackgroundImage() => _invoke<bool>('clearBackgroundImage');

  /// Opens the system live wallpaper picker on Shibu.
  Future<bool> openWallpaperPicker() async =>
      await _invoke<bool>('openWallpaperPicker') ?? false;

  Future<bool> isWallpaperActive() async =>
      await _invoke<bool>('isWallpaperActive') ?? false;

  /// Asks the launcher to place the widget. Not every launcher supports this.
  Future<bool> requestPinWidget() async =>
      await _invoke<bool>('requestPinWidget') ?? false;

  Future<int> widgetCount() async => await _invoke<int>('widgetCount') ?? 0;

  /// Swallows platform failures so a missing capability degrades to a no-op
  /// rather than taking down the screen that called it.
  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      debugPrint('Shibu: method "$method" is not available on this platform');
      return null;
    } on PlatformException catch (e) {
      debugPrint('Shibu: method "$method" failed: ${e.message}');
      return null;
    }
  }
}
