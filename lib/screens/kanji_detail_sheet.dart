import 'package:flutter/material.dart';

import '../main.dart';
import '../models/kanji.dart';

/// Opens the full entry for [kanji] as a bottom sheet.
Future<void> showKanjiDetail(BuildContext context, Kanji kanji) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _KanjiDetailSheet(kanji: kanji),
  );
}

class _KanjiDetailSheet extends StatelessWidget {
  const _KanjiDetailSheet({required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kanji.character,
                  style: const TextStyle(fontSize: 88, height: 1.0),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        kanji.meaning,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kanji.readingLine,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.62),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'JLPT N${kanji.level}'
                        '${kanji.strokes > 0 ? ' · ${kanji.strokes} strokes' : ''}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (kanji.onyomi.isNotEmpty)
              _DetailRow(label: "On'yomi", value: kanji.onyomi),
            if (kanji.kunyomi.isNotEmpty)
              _DetailRow(label: "Kun'yomi", value: kanji.kunyomi),
            _DetailRow(
              label: 'Example',
              value:
                  '${kanji.example}  ${kanji.exampleKana}\n'
                  '${kanji.exampleRomaji} — ${kanji.exampleMeaning}',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.toggleFavorite(kanji),
                    icon: Icon(
                      controller.isFavorite(kanji)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                    ),
                    label: Text(
                      controller.isFavorite(kanji) ? 'Favourited' : 'Favourite',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await controller.showNow(kanji);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.push_pin_outlined, size: 20),
                    label: const Text('Show now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 15, height: 1.4)),
        ),
      ],
    ),
  );
}
