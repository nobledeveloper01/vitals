// Settings: the two floor toggles and large type, each read at act time.
import 'package:flutter/material.dart';

import '../design/glass.dart';
import '../design/motion.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([Motion.shared, Preferences.shared]),
            builder: (context, _) => Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(Gap.l),
                    children: [
                      Text(Strings.settings,
                          style: Type.display.copyWith(color: p.textPrimary)),
                      const SizedBox(height: Gap.m),
                      Glass(
                        depth: Depth.low,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _Row(
                                title: Strings.plainSurfaces,
                                hint: Strings.plainSurfacesHint,
                                value: !Motion.shared.glass,
                                onChanged: (v) => Motion.shared.glass = !v,
                                key: const Key('plain')),
                            Divider(height: 1, color: p.hairline),
                            _Row(
                                title: Strings.lessMotion,
                                hint: Strings.lessMotionHint,
                                value: Motion.shared.reduced,
                                onChanged: (v) => Motion.shared.reduced = v,
                                key: const Key('reduce')),
                            Divider(height: 1, color: p.hairline),
                            _Row(
                                title: Strings.largeType,
                                hint: Strings.largeTypeHint,
                                value: Preferences.shared.largeType,
                                onChanged: (v) =>
                                    Preferences.shared.largeType = v,
                                key: const Key('largeType')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Gap.l),
                  child: PrimaryButton(
                      label: Strings.done,
                      onPressed: () => Navigator.of(context).pop()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {super.key,
      required this.title,
      required this.hint,
      required this.value,
      required this.onChanged});
  final String title, hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: p.accent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
        title: Text(title, style: Type.title.copyWith(color: p.textPrimary)),
        subtitle:
            Text(hint, style: Type.secondary.copyWith(color: p.textSecondary)),
      ),
    );
  }
}
