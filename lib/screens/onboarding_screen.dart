import 'package:flutter/material.dart';

import '../main.dart';
import '../models/settings.dart';
import '../widgets/lock_screen_preview.dart';

/// First-run setup: pick a level, pick a rhythm, turn the surfaces on.
///
/// The wallpaper and widget steps are deliberately skippable — both hand off to
/// system UI that some launchers do not provide, and neither is required for
/// the app itself to work.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  static const int _stepCount = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _index = index);
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Row(
                children: [
                  for (var i = 0; i < _stepCount; i++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(
                          right: i == _stepCount - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: i <= _index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [_LevelStep(), _RhythmStep(), _ActivateStep()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: Row(
                children: [
                  if (_index > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _goTo(_index - 1),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_index > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        if (_index < _stepCount - 1) {
                          _goTo(_index + 1);
                        } else {
                          controller.completeOnboarding();
                        }
                      },
                      child: Text(
                        _index < _stepCount - 1 ? 'Continue' : 'Start learning',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 36, 22, 20),
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        subtitle,
        style: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      const SizedBox(height: 28),
      child,
    ],
  );
}

class _LevelStep extends StatelessWidget {
  const _LevelStep();

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    final settings = controller.settings;
    final repository = controller.repository;

    return _StepScaffold(
      title: 'Where are you\nstarting from?',
      subtitle:
          'Pick the JLPT levels you want to see. You can change this any time, '
          'and add more as you go.',
      child: Column(
        children: [
          for (final level in repository.availableLevels)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LevelTile(
                level: level,
                count: repository.countForLevel(level),
                selected: settings.levels.contains(level),
                onTap: () {
                  final next = Set<int>.of(settings.levels);
                  if (!next.remove(level)) next.add(level);
                  if (next.isNotEmpty) {
                    controller.edit((s) => s.copyWith(levels: next));
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int level;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  static const Map<int, String> _blurb = {
    5: 'Numbers, days, everyday nouns',
    4: 'Verbs, school and work vocabulary',
    3: 'Abstract and news vocabulary',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary.withValues(alpha: 0.14) : scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JLPT N$level',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_blurb[level] ?? 'Kanji'} · $count kanji',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? scheme.primary
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RhythmStep extends StatelessWidget {
  const _RhythmStep();

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    final settings = controller.settings;

    return _StepScaffold(
      title: 'How often should\nit change?',
      subtitle:
          'A new kanji every time you wake your phone is the fastest way to pick '
          'them up. A timer is calmer.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final mode in RotationMode.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChoiceTile(
                title: mode.label,
                subtitle: mode == RotationMode.unlock
                    ? 'Needs the Shibu wallpaper, set up on the next step'
                    : 'Pick an interval below',
                selected: settings.rotationMode == mode,
                onTap: () =>
                    controller.edit((s) => s.copyWith(rotationMode: mode)),
              ),
            ),
          if (settings.rotationMode == RotationMode.interval) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (minutes, label) in kIntervalChoices)
                  ChoiceChip(
                    label: Text(label),
                    selected: settings.intervalMinutes == minutes,
                    showCheckmark: false,
                    onSelected: (_) => controller.edit(
                      (s) => s.copyWith(intervalMinutes: minutes),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary.withValues(alpha: 0.14) : scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivateStep extends StatelessWidget {
  const _ActivateStep();

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);

    return _StepScaffold(
      title: 'Put it where\nyou will see it',
      subtitle:
          'Android phones have no lock screen widget API, so Shibu draws onto '
          'your wallpaper instead — which covers the lock screen and the home '
          'screen at once.',
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: LockScreenPreview(
                kanji: controller.currentKanji,
                settings: controller.settings,
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: controller.openWallpaperPicker,
            icon: Icon(
              controller.wallpaperActive
                  ? Icons.check
                  : Icons.wallpaper_outlined,
            ),
            label: Text(
              controller.wallpaperActive
                  ? 'Wallpaper is active'
                  : 'Set Shibu as wallpaper',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final pinned = await controller.requestPinWidget();
              if (!pinned) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Long-press your home screen, choose Widgets, then pick Shibu.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.widgets_outlined),
            label: const Text('Add the home screen widget'),
          ),
          const SizedBox(height: 16),
          Text(
            'Both are optional, and you can do either later from Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.42),
            ),
          ),
        ],
      ),
    );
  }
}
