import 'package:flutter/material.dart';

import '../main.dart';
import '../models/kanji.dart';
import 'kanji_detail_sheet.dart';

/// Searchable list of the whole bundled deck.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController _search = TextEditingController();
  int? _levelFilter;
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    final repository = controller.repository;

    var results = repository.search(
      _search.text,
      levels: _levelFilter == null ? null : {_levelFilter!},
    );
    if (_favoritesOnly) {
      results = results
          .where((k) => controller.settings.favorites.contains(k.id))
          .toList();
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Browse',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${results.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search kanji, reading or meaning',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_search.clear),
                      ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              children: [
                _Chip(
                  label: 'All',
                  selected: _levelFilter == null && !_favoritesOnly,
                  onTap: () => setState(() {
                    _levelFilter = null;
                    _favoritesOnly = false;
                  }),
                ),
                for (final level in repository.availableLevels)
                  _Chip(
                    label: 'N$level',
                    selected: _levelFilter == level,
                    onTap: () => setState(() {
                      _levelFilter = _levelFilter == level ? null : level;
                      _favoritesOnly = false;
                    }),
                  ),
                _Chip(
                  label: 'Favourites',
                  selected: _favoritesOnly,
                  onTap: () => setState(() {
                    _favoritesOnly = !_favoritesOnly;
                    _levelFilter = null;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: results.isEmpty
                ? _NoResults(favoritesOnly: _favoritesOnly)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                    itemCount: results.length,
                    itemBuilder: (context, i) => _KanjiRow(kanji: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KanjiRow extends StatelessWidget {
  const _KanjiRow({required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    final isCurrent = controller.currentKanji?.id == kanji.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showKanjiDetail(context, kanji),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    kanji.character,
                    style: const TextStyle(fontSize: 34, height: 1.0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kanji.meaning,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kanji.readingLine,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                if (controller.isFavorite(kanji))
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.favorite,
                      size: 15,
                      color: Color(0xFFE87BA4),
                    ),
                  ),
                Text(
                  'N${kanji.level}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    ),
  );
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.favoritesOnly});

  final bool favoritesOnly;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        favoritesOnly
            ? 'No favourites yet. Tap the heart on a kanji to add one.'
            : 'Nothing matches that search.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      ),
    ),
  );
}
