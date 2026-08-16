import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
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
                      'The photo is only used by the Shibu wallpaper. It is copied '
                      'into the app so it keeps working if you move the original.',
                  children: [
                    SettingRow(
                      label: 'Background photo',
                      description: settings.wallpaperPath == null
                          ? 'Using the built-in gradient'
                          : 'Custom photo selected',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickPhoto(context),
                    ),
                    if (settings.wallpaperPath != null)
                      SettingRow(
                        label: 'Remove photo',
                        trailing: const Icon(Icons.close),
                        onTap: controller.clearBackgroundImage,
                      ),
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

  Future<void> _pickPhoto(BuildContext context) async {
    final controller = ShibuScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Big enough for any phone screen without storing a 12 MP original.
        maxWidth: 2160,
        maxHeight: 3840,
        imageQuality: 92,
      );
      if (picked == null) return;
      await controller.setBackgroundImage(picked.path);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open that photo: $e')),
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
