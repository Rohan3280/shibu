import 'package:flutter/material.dart';

import '../theme.dart';

/// A labelled group of settings rows.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.children,
    this.footnote,
  });

  final String title;
  final List<Widget> children;

  /// Optional explanation shown under the group, for behaviour the user cannot
  /// infer from the control alone.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
          child: Text(
            title.toUpperCase(),
            style: ShibuTheme.sectionLabel(context),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: 18, endIndent: 18),
                children[i],
              ],
            ],
          ),
        ),
        if (footnote != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
            child: Text(
              footnote!,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// A row with a label, an optional description, and a trailing control.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    this.description,
    this.trailing,
    this.leading,
    this.onTap,
  });

  final String label;
  final String? description;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: leading,
    title: Text(
      label,
      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
    ),
    subtitle: description == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              description!,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
    trailing: trailing,
  );
}
