// Settings: the two floor toggles and large type, each read at act time.
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../design/glass.dart';
import '../design/motion.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/patient_strings.dart';
import '../speech/strings.dart';
import '../store/audit.dart';
import '../store/backup.dart';
import '../store/preferences.dart';
import '../store/records.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.records});
  final Records records;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _note;

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
                      const SizedBox(height: Gap.m),
                      // The patient face's language (ADR-0006 #27); a draft
                      // says it is one.
                      Glass(
                        depth: Depth.low,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(PatientStrings.t('language'),
                                style:
                                    Type.title.copyWith(color: p.textPrimary)),
                            const SizedBox(height: Gap.s),
                            Wrap(
                              spacing: Gap.s,
                              runSpacing: Gap.s,
                              children: [
                                for (final l in Lang.values)
                                  ChoiceChip(
                                    key: Key('lang-${l.name}'),
                                    label: Text(l.own),
                                    selected: Preferences.shared.lang == l,
                                    selectedColor: p.accent,
                                    labelStyle: Type.small.copyWith(
                                        color: Preferences.shared.lang == l
                                            ? p.textOnAccent
                                            : p.textPrimary),
                                    onSelected: (_) => setState(
                                        () => Preferences.shared.lang = l),
                                  ),
                              ],
                            ),
                            if (!Preferences.shared.lang.reviewed) ...[
                              const SizedBox(height: Gap.s),
                              Text(
                                  '${Preferences.shared.lang.own}: ${PatientStrings.t('draftLanguage')}',
                                  style: Type.small
                                      .copyWith(color: p.textSecondary),
                                  key: const Key('draftNote')),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: Gap.m),
                      // Backup (ADR-0006 #29): every fact into one file under a
                      // passphrase, and every fact checked on the way back.
                      Glass(
                        depth: Depth.low,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(Strings.backup,
                                style:
                                    Type.title.copyWith(color: p.textPrimary)),
                            const SizedBox(height: Gap.xs),
                            Text(Strings.backupHint,
                                style: Type.secondary
                                    .copyWith(color: p.textSecondary)),
                            const SizedBox(height: Gap.m),
                            SecondaryButton(
                                label:
                                    '${Strings.backUp} (${widget.records.facts})',
                                onPressed:
                                    widget.records.facts == 0 ? null : _backUp),
                            const SizedBox(height: Gap.s),
                            SecondaryButton(
                                label: Strings.restore, onPressed: _restore),
                            if (_note != null) ...[
                              const SizedBox(height: Gap.m),
                              Text(_note!,
                                  style: Type.secondary
                                      .copyWith(color: p.textSecondary),
                                  key: const Key('backupNote')),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: Gap.m),
                      SecondaryButton(
                          label: Strings.changeFace,
                          onPressed: () {
                            Preferences.shared.face = Face.unchosen;
                            Navigator.of(context).pop();
                          }),
                      if (Preferences.shared.face == Face.clinic) ...[
                        const SizedBox(height: Gap.m),
                        // The signed audit export (ADR-0006 #30).
                        Glass(
                          depth: Depth.low,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(Strings.auditExport,
                                  style: Type.title
                                      .copyWith(color: p.textPrimary)),
                              const SizedBox(height: Gap.xs),
                              Text(Strings.auditExportHint,
                                  style: Type.secondary
                                      .copyWith(color: p.textSecondary)),
                              const SizedBox(height: Gap.m),
                              SecondaryButton(
                                  label: Strings.exportTheAudit,
                                  onPressed: widget.records.facts == 0
                                      ? null
                                      : _exportAudit),
                              if (_publicKey != null) ...[
                                const SizedBox(height: Gap.s),
                                SelectableText(
                                    '${Strings.tabletKey} $_publicKey',
                                    style: Type.small
                                        .copyWith(color: p.textSecondary)),
                              ],
                            ],
                          ),
                        ),
                      ],
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

  Future<String?> _passphrase(String title) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
            controller: c,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: Strings.passphrase)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(Strings.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, c.text),
              child: const Text(Strings.done)),
        ],
      ),
    );
  }

  String? _publicKey;

  Future<void> _exportAudit() async {
    final keys = AuditKeys();
    final file = File(
        '${(await getTemporaryDirectory()).path}/vitals-audit-${DateTime.now().toIso8601String().substring(0, 10)}.csv');
    await file.writeAsBytes(await AuditExport.signed(widget.records, keys));
    final pk = await keys.publicKeyHex();
    if (mounted) setState(() => _publicKey = pk);
    await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: Strings.auditShareText));
  }

  Future<void> _backUp() async {
    final pass = await _passphrase(Strings.backUp);
    if (pass == null || pass.isEmpty) return;
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/vitals-${DateTime.now().toIso8601String().substring(0, 10)}.vitalsbackup');
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    await Backup.write(widget.records, file, passphrase: pass, salt: salt);
    await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: Strings.backupShareText));
  }

  Future<void> _restore() async {
    final picked = await FilePicker.pickFiles();
    final path = picked.isEmpty ? null : picked.single.path;
    if (path == null) return;
    final pass = await _passphrase(Strings.restore);
    if (pass == null || pass.isEmpty) return;
    final r =
        await Backup.restore(widget.records, File(path), passphrase: pass);
    setState(() => _note =
        '${Strings.restored} ${r.kept} · ${Strings.refused} ${r.refused}');
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
