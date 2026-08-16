import 'package:flutter/material.dart';

import '../main.dart';
import '../models/background_presets.dart';
import '../models/settings.dart';
import '../widgets/lock_screen_preview.dart';
import '../widgets/section.dart';

/// Appearance of the card and its backdrop, with a live preview pinned to the
/// top so every control shows its effect immediately.
class StyleScreen extends StatelessWidget {
  const StyleScreen({super.key});

  /// Text colours offered for the card. Deliberately a small set — arbitrary
  /// colours mostly produce unreadable cards over a photo.
  static const List<Color> _textColors = [
    Colors.white,
    Color(0xFFFFE9B0),
    Color(0xFFF4B2CA),
    Color(0xFFB9E4FF),
    Color(0xFFCDF5D8),
    Color(0xFF15181F),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    final settings = controller.settings;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _Title()),
          const SliverToBoxAdapter(child: WallpaperInactiveBanner()),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
                child: LockScreenPreview(
                  kanji: controller.currentKanji,
                  settings: settings,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Section(
                  title: 'Backdrop',
                  footnote:
                      'GIFs and animated WebP work too. The file is copied into '
                      'the app so it keeps working if you move the original.',
                  children: [
                    _BackgroundKindRow(
                      selected: settings.backgroundKind,
                      onSelected: (kind) async {
                        if (kind == BackgroundKind.image &&
                            settings.wallpaperPath == null) {
                          await ShibuScope.read(context).pickBackground();
                          return;
                        }
                        await controller.edit(
                          (s) => s.copyWith(backgroundKind: kind),
                        );
                      },
                    ),
                    if (settings.backgroundKind == BackgroundKind.preset)
                      _PresetRow(
                        selected: settings.backgroundPreset,
                        onSelected: (id) => controller.edit(
                          (s) => s.copyWith(backgroundPreset: id),
                        ),
                      )
                    else ...[
                      SettingRow(
                        label: settings.wallpaperPath == null
                            ? 'Choose an image or GIF'
                            : 'Change image',
                        description: settings.wallpaperPath == null
                            ? null
                            : settings.backgroundIsAnimated
                            ? 'Animated file selected'
                            : 'Still image selected',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _pickBackground(context),
                      ),
                      if (settings.backgroundIsAnimated)
                        SettingRow(
                          label: 'Animate',
                          description:
                              'A moving wallpaper redraws whenever your screen '
                              'is on, which uses more battery',
                          trailing: Switch(
                            value: settings.backgroundAnimate,
                            onChanged: (v) => controller.edit(
                              (s) => s.copyWith(backgroundAnimate: v),
                            ),
                          ),
                        ),
                      if (settings.wallpaperPath != null)
                        SettingRow(
                          label: 'Remove image',
                          trailing: const Icon(Icons.close),
                          onTap: controller.clearBackground,
                        ),
                    ],
                    _SliderRow(
                      label: 'Darken',
                      value: settings.wallpaperDim,
                      min: 0,
                      max: 0.8,
                      display: '${(settings.wallpaperDim * 100).round()}%',
                      onChanged: (v) =>
                          controller.edit((s) => s.copyWith(wallpaperDim: v)),
                    ),
                  ],
                ),
                Section(
                  title: 'Card',
                  children: [
                    _ColorRow(
                      label: 'Text colour',
                      colors: _textColors,
                      selected: settings.textColor,
                      onSelected: (c) =>
                          controller.edit((s) => s.copyWith(textColor: c)),
                    ),
                    _SliderRow(
                      label: 'Text size',
                      value: settings.fontScale,
                      min: 0.7,
                      max: 1.6,
                      display: '${(settings.fontScale * 100).round()}%',
                      onChanged: (v) =>
                          controller.edit((s) => s.copyWith(fontScale: v)),
                    ),
                    _AlignRow(
                      selected: settings.align,
                      onSelected: (a) =>
                          controller.edit((s) => s.copyWith(align: a)),
                    ),
                    SettingRow(
                      label: 'Drop shadow',
                      description:
                          'Keeps light text readable over a busy photo',
                      trailing: Switch(
                        value: settings.shadow,
                        onChanged: (v) =>
                            controller.edit((s) => s.copyWith(shadow: v)),
                      ),
                    ),
                  ],
                ),
                Section(
                  title: 'Position',
                  footnote:
                      'Nudge the card so it sits clear of your clock and any '
                      'notifications.',
                  children: [
                    _SliderRow(
                      label: 'Vertical',
                      value: settings.offsetY,
                      min: 0.08,
                      max: 0.92,
                      display: '${(settings.offsetY * 100).round()}%',
                      onChanged: (v) =>
                          controller.edit((s) => s.copyWith(offsetY: v)),
                    ),
                    _SliderRow(
                      label: 'Side margin',
                      value: settings.offsetX,
                      min: 0,
                      max: 0.3,
                      display: '${(settings.offsetX * 100).round()}%',
                      onChanged: (v) =>
                          controller.edit((s) => s.copyWith(offsetX: v)),
                    ),
                  ],
                ),
                Section(
                  title: 'What to show',
                  children: [
                    SettingRow(
                      label: 'Reading',
                      description: 'eki・えき',
                      trailing: Switch(
                        value: settings.showReading,
                        onChanged: (v) =>
                            controller.edit((s) => s.copyWith(showReading: v)),
                      ),
                    ),
                    SettingRow(
                      label: 'Meaning',
                      description: 'station',
                      trailing: Switch(
                        value: settings.showMeaning,
                        onChanged: (v) =>
                            controller.edit((s) => s.copyWith(showMeaning: v)),
                      ),
                    ),
                    SettingRow(
                      label: 'Example word',
                      description: '駅前・in front of station',
                      trailing: Switch(
                        value: settings.showExample,
                        onChanged: (v) =>
                            controller.edit((s) => s.copyWith(showExample: v)),
                      ),
                    ),
                  ],
                ),
                Section(
                  title: 'Home screen widget',
                  children: [
                    _WidgetBackgroundRow(
                      selected: settings.widgetBackground,
                      onSelected: (b) => controller.edit(
                        (s) => s.copyWith(widgetBackground: b),
                      ),
                    ),
                    _ColorRow(
                      label: 'Widget text',
                      colors: _textColors,
                      selected: settings.widgetTextColor,
                      onSelected: (c) => controller.edit(
                        (s) => s.copyWith(widgetTextColor: c),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBackground(BuildContext context) async {
    final controller = ShibuScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.pickBackground();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open that image: $e')),
      );
    }
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(22, 14, 22, 18),
    child: Text(
      'Style',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    ),
  );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              display,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            for (final color in colors)
              GestureDetector(
                onTap: () => onSelected(color),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.toARGB32() == selected.toARGB32()
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withValues(alpha: 0.18),
                      width: color.toARGB32() == selected.toARGB32() ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _AlignRow extends StatelessWidget {
  const _AlignRow({required this.selected, required this.onSelected});

  final CardAlign selected;
  final ValueChanged<CardAlign> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Alignment',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
          ),
        ),
        SegmentedButton<CardAlign>(
          segments: [
            for (final align in CardAlign.values)
              ButtonSegment(value: align, icon: Icon(align.icon)),
          ],
          selected: {selected},
          onSelectionChanged: (s) => onSelected(s.first),
          showSelectedIcon: false,
        ),
      ],
    ),
  );
}

class _WidgetBackgroundRow extends StatelessWidget {
  const _WidgetBackgroundRow({
    required this.selected,
    required this.onSelected,
  });

  final WidgetBackground selected;
  final ValueChanged<WidgetBackground> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background',
          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SegmentedButton<WidgetBackground>(
          segments: [
            for (final background in WidgetBackground.values)
              ButtonSegment(value: background, label: Text(background.label)),
          ],
          selected: {selected},
          onSelectionChanged: (s) => onSelected(s.first),
          showSelectedIcon: false,
        ),
      ],
    ),
  );
}

/// Picks between a built-in gradient and the user's own file.
class _BackgroundKindRow extends StatelessWidget {
  const _BackgroundKindRow({required this.selected, required this.onSelected});

  final BackgroundKind selected;
  final ValueChanged<BackgroundKind> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background',
          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SegmentedButton<BackgroundKind>(
          segments: [
            for (final kind in BackgroundKind.values)
              ButtonSegment(value: kind, label: Text(kind.label)),
          ],
          selected: {selected},
          onSelectionChanged: (s) => onSelected(s.first),
          showSelectedIcon: false,
        ),
      ],
    ),
  );
}

/// The built-in gradients, shown as swatches rather than names.
class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          BackgroundPresets.byId(selected).label,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final preset in BackgroundPresets.all)
              GestureDetector(
                onTap: () => onSelected(preset.id),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: preset.gradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: preset.id == selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withValues(alpha: 0.14),
                      width: preset.id == selected ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

/// Explains why nothing on the lock screen is changing.
///
/// Every control on this screen styles the Shibu wallpaper. If some other app
/// owns the wallpaper slot, the settings save correctly and simply have nothing
/// to draw onto, which reads as the app being broken. Naming the culprit is the
/// difference between a two-second fix and a bug report.
class WallpaperInactiveBanner extends StatelessWidget {
  const WallpaperInactiveBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);
    if (controller.wallpaperActive) return const SizedBox.shrink();

    final other = controller.otherWallpaperName;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    other == null
                        ? 'Shibu is not your wallpaper yet'
                        : '$other is your wallpaper',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              other == null
                  ? 'These settings style the Shibu wallpaper. Until you set it, '
                        'your lock screen will not change.'
                  : 'These settings style the Shibu wallpaper, so nothing will '
                        'change on your lock screen while $other holds the '
                        'wallpaper slot.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.openWallpaperPicker,
                icon: const Icon(Icons.wallpaper_outlined, size: 18),
                label: const Text('Set Shibu as wallpaper'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
