import 'package:flutter/material.dart';

import '../main.dart';
import '../models/kanji.dart';
import '../widgets/lock_screen_preview.dart';
import 'kanji_detail_sheet.dart';

/// The home screen of the app: what is on the lock screen right now, and the
/// controls for changing it.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    final kanji = controller.currentKanji;
    final settings = controller.settings;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.refreshStatus,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: LockScreenPreview(kanji: kanji, settings: settings),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 6,
                    child: kanji == null
                        ? const _EmptyDeck()
                        : _CardDetails(kanji: kanji),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _NavigationRow(),
            const _StatusStrip(),
            const _UpNext(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    final deckSize = controller.deckSize;
    final learned = controller.settings.learned.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'On your lock screen',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '$deckSize in your deck · $learned marked learned',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDetails extends StatelessWidget {
  const _CardDetails({required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kanji.character,
          style: const TextStyle(fontSize: 68, height: 1.05),
        ),
        const SizedBox(height: 6),
        Text(
          kanji.readingLine,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          kanji.meaning,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          kanji.exampleLine,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.35,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(label: 'N${kanji.level}', tone: theme.colorScheme.secondary),
            if (kanji.strokes > 0) _Pill(label: '${kanji.strokes} strokes'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: () => controller.toggleFavorite(kanji),
              icon: Icon(
                controller.isFavorite(kanji)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              tooltip: 'Favourite',
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => controller.toggleLearned(kanji),
              icon: Icon(
                controller.isLearned(kanji)
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
              ),
              tooltip: 'Mark learned',
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => showKanjiDetail(context, kanji),
              icon: const Icon(Icons.more_horiz),
              tooltip: 'Details',
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.tone});

  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? Colors.white.withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'No kanji selected',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(
        'Choose at least one JLPT level in Settings.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
    ],
  );
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow();

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.previousKanji,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: controller.nextKanji,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next kanji'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tells the user whether the two surfaces are actually live.
class _StatusStrip extends StatelessWidget {
  const _StatusStrip();

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatusChip(
              icon: Icons.lock_outline,
              label: 'Lock screen',
              active: controller.wallpaperActive,
              detail: controller.wallpaperActive ? 'Live' : 'Not set up',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatusChip(
              icon: Icons.widgets_outlined,
              label: 'Home widget',
              active: controller.widgetCount > 0,
              detail: controller.widgetCount > 0
                  ? '${controller.widgetCount} placed'
                  : 'Not added',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.detail,
    required this.active,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Colors.white.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(detail, style: TextStyle(fontSize: 11.5, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpNext extends StatelessWidget {
  const _UpNext();

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    final upcoming = controller.upcoming();
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 28, 22, 12),
          child: Text(
            'Coming up',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: upcoming.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final kanji = upcoming[i];
              return GestureDetector(
                onTap: () => showKanjiDetail(context, kanji),
                child: Container(
                  width: 78,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        kanji.character,
                        style: const TextStyle(fontSize: 30),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kanji.meaning,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
