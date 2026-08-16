import 'package:flutter/material.dart';

import '../main.dart';
import '../models/settings.dart';
import '../widgets/section.dart';

/// Deck, rotation, and the two setup actions that reach outside the app.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    final settings = controller.settings;
    final repository = controller.repository;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),

          Section(
            title: 'Set up',
            footnote:
                'Android has no public lock screen widget API on phones, so Shibu '
                'reaches the lock screen as a live wallpaper. The same wallpaper '
                'covers your home screen too.',
            children: [
              SettingRow(
                label: 'Lock screen wallpaper',
                description: controller.wallpaperActive
                    ? 'Shibu is your active wallpaper'
                    : 'Set Shibu as your live wallpaper',
                leading: Icon(
                  controller.wallpaperActive
                      ? Icons.check_circle
                      : Icons.lock_outline,
                  color: controller.wallpaperActive
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: controller.openWallpaperPicker,
              ),
              SettingRow(
                label: 'Home screen widget',
                description: controller.widgetCount > 0
                    ? '${controller.widgetCount} on your home screen'
                    : 'Add the Shibu widget',
                leading: Icon(
                  controller.widgetCount > 0
                      ? Icons.check_circle
                      : Icons.widgets_outlined,
                  color: controller.widgetCount > 0
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                trailing: const Icon(Icons.add, size: 20),
                onTap: () => _addWidget(context),
              ),
            ],
          ),

          Section(
            title: 'Deck',
            footnote: '${controller.deckSize} kanji in the current deck.',
            children: [
              SettingRow(
                label: 'Draw from',
                trailing: DropdownButton<DeckMode>(
                  value: settings.deck,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final mode in DeckMode.values)
                      DropdownMenuItem(value: mode, child: Text(mode.label)),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      controller.edit((s) => s.copyWith(deck: mode));
                    }
                  },
                ),
              ),
              if (settings.deck == DeckMode.levels)
                _LevelPicker(
                  available: repository.availableLevels,
                  selected: settings.levels,
                  countFor: repository.countForLevel,
                  onChanged: (levels) =>
                      controller.edit((s) => s.copyWith(levels: levels)),
                ),
              SettingRow(
                label: 'Shuffle',
                description: settings.shuffle
                    ? 'Random but repeatable order'
                    : 'Straight through, easiest first',
                trailing: Switch(
                  value: settings.shuffle,
                  onChanged: (v) =>
                      controller.edit((s) => s.copyWith(shuffle: v)),
                ),
              ),
            ],
          ),

          Section(
            title: 'Rotation',
            footnote: settings.rotationMode == RotationMode.unlock
                ? 'Needs the Shibu wallpaper to be active — that is what tells the '
                      'app your screen woke up. The widget follows along.'
                : 'Android will not wake an app more often than every 15 minutes, so '
                      'a new kanji can arrive up to 15 minutes late.',
            children: [
              _RotationModePicker(
                selected: settings.rotationMode,
                onSelected: (m) =>
                    controller.edit((s) => s.copyWith(rotationMode: m)),
              ),
              if (settings.rotationMode == RotationMode.interval)
                SettingRow(
                  label: 'How often',
                  trailing: DropdownButton<int>(
                    value: _nearestInterval(settings.intervalMinutes),
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final (minutes, label) in kIntervalChoices)
                        DropdownMenuItem(value: minutes, child: Text(label)),
                    ],
                    onChanged: (minutes) {
                      if (minutes != null) {
                        controller.edit(
                          (s) => s.copyWith(intervalMinutes: minutes),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),

          Section(
            title: 'Progress',
            children: [
              SettingRow(
                label: 'Favourites',
                trailing: Text('${settings.favorites.length}'),
              ),
              SettingRow(
                label: 'Marked learned',
                trailing: Text('${settings.learned.length}'),
              ),
              SettingRow(
                label: 'Reset progress',
                description: 'Clears favourites and learned marks',
                trailing: const Icon(Icons.restart_alt),
                onTap: () => _confirmReset(context),
              ),
            ],
          ),

          const _About(),
        ],
      ),
    );
  }

  /// Guards against a stored interval that is no longer one of the choices.
  static int _nearestInterval(int minutes) {
    for (final (value, _) in kIntervalChoices) {
      if (value == minutes) return value;
    }
    return 60;
  }

  Future<void> _addWidget(BuildContext context) async {
    final controller = ShibuScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final pinned = await controller.requestPinWidget();
    if (pinned) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Your launcher does not support adding widgets from an app. '
          'Long-press your home screen, choose Widgets, then pick Shibu.',
        ),
        duration: Duration(seconds: 6),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final controller = ShibuScope.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This clears your favourites and everything marked learned. '
          'Your style settings are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await controller.edit(
        (s) => s.copyWith(favorites: <int>{}, learned: <int>{}),
      );
    }
  }
}

class _RotationModePicker extends StatelessWidget {
  const _RotationModePicker({required this.selected, required this.onSelected});

  final RotationMode selected;
  final ValueChanged<RotationMode> onSelected;

  @override
  Widget build(BuildContext context) => RadioGroup<RotationMode>(
    groupValue: selected,
    onChanged: (mode) {
      if (mode != null) onSelected(mode);
    },
    child: Column(
      children: [
        for (final mode in RotationMode.values)
          RadioListTile<RotationMode>(
            value: mode,
            title: Text(
              mode.label,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
      ],
    ),
  );
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({
    required this.available,
    required this.selected,
    required this.countFor,
    required this.onChanged,
  });

  final List<int> available;
  final Set<int> selected;
  final int Function(int level) countFor;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'JLPT levels',
          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final level in available)
              FilterChip(
                label: Text('N$level  ·  ${countFor(level)}'),
                selected: selected.contains(level),
                showCheckmark: false,
                onSelected: (on) {
                  final next = Set<int>.of(selected);
                  if (on) {
                    next.add(level);
                  } else {
                    next.remove(level);
                  }
                  // Deselecting everything would leave the widget with nothing
                  // to show, so keep at least one level on.
                  if (next.isNotEmpty) onChanged(next);
                },
              ),
          ],
        ),
      ],
    ),
  );
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 34, 22, 0),
    child: Column(
      children: [
        Text(
          'Shibu',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kanji on your lock screen. Everything stays on your device — '
          'Shibu has no network permission at all.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    ),
  );
}
