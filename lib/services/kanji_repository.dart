import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/kanji.dart';
import '../models/settings.dart';
import 'deck_order.dart';

/// Loads the bundled deck and mirrors the native selection logic.
///
/// The ordering here must match `KanjiStore` on the Kotlin side, otherwise the
/// in-app preview would show a different card from the one on the lock screen.
/// Both walk the filtered deck with the same seed and index.
class KanjiRepository {
  KanjiRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String assetPath = 'assets/data/kanji.json';

  final AssetBundle _bundle;

  List<Kanji>? _all;

  List<Kanji> get all => _all ?? const [];

  bool get isLoaded => _all != null;

  Future<List<Kanji>> load() async {
    if (_all != null) return _all!;
    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final entries = (decoded['kanji'] as List)
        .cast<Map<String, dynamic>>()
        .map(Kanji.fromJson)
        .toList(growable: false);
    _all = entries;
    return entries;
  }

  Kanji? byId(int id) {
    for (final k in all) {
      if (k.id == id) return k;
    }
    return null;
  }

  /// Every level present in the bundled deck, easiest first.
  List<int> get availableLevels {
    final levels = all.map((k) => k.level).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return levels;
  }

  int countForLevel(int level) => all.where((k) => k.level == level).length;

  /// The pool the user's settings select, before ordering.
  List<Kanji> deck(ShibuSettings settings) {
    final selected = switch (settings.deck) {
      DeckMode.favorites =>
        all.where((k) => settings.favorites.contains(k.id)).toList(),
      DeckMode.levels =>
        all.where((k) => settings.levels.contains(k.level)).toList(),
    };
    // An empty favourites list or an unmatched filter must never blank the
    // widget, so fall back to the whole deck.
    return selected.isEmpty ? all : selected;
  }

  /// The pool in the order rotation will walk it.
  List<Kanji> orderedDeck(ShibuSettings settings) {
    final pool = deck(settings);
    if (!settings.shuffle || pool.length < 2) return pool;
    return DeckOrder.shuffled(pool);
  }

  /// The card that should currently be on screen.
  Kanji? current(ShibuSettings settings) {
    final ordered = orderedDeck(settings);
    if (ordered.isEmpty) return null;
    return ordered[settings.currentIndex % ordered.length];
  }

  /// Case-insensitive search over character, readings and meanings.
  List<Kanji> search(String query, {Set<int>? levels}) {
    final needle = query.trim().toLowerCase();
    return all
        .where((k) {
          if (levels != null &&
              levels.isNotEmpty &&
              !levels.contains(k.level)) {
            return false;
          }
          return needle.isEmpty || k.searchIndex.contains(needle);
        })
        .toList(growable: false);
  }
}
