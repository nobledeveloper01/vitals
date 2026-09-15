// The lock: the record blurred behind glassHigh, the PIN asked. The blur is
// the lock, not a decoration; with glass off the twin is solid and the
// record is simply not drawn. Phase 0 accepts one fixed PIN for the tests;
// Phase 1 attributes it to a staff member from the encrypted store.
import 'package:flutter/material.dart';
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/preferences.dart';
import '../store/records.dart';
import 'emergency.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, this.records});

  /// For the emergency card (ADR-0006 #17): shown on the lock face only
  /// while the patient has opted in, and only what they typed for it.
  final Records? records;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pin = TextEditingController();
  String? _error;

  Emergency? get _emergency {
    final r = widget.records;
    if (r == null || Preferences.shared.face != Face.patient) return null;
    for (final record in r.all.values) {
      final e = Emergency.of(record.current);
      if (e != null && e.shown) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Gap.l),
              child: Glass(
                depth: Depth.high,
                radius: Radius2.sheet,
                padding: const EdgeInsets.all(Gap.l),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_emergency != null) ...[
                      EmergencyCard(card: _emergency!),
                      const SizedBox(height: Gap.m),
                    ],
                    Icon(Icons.lock_outline, color: p.accent, size: 40),
                    const SizedBox(height: Gap.m),
                    Text(Strings.locked,
                        style: Type.headline.copyWith(color: p.textPrimary)),
                    const SizedBox(height: Gap.s),
                    Text(Strings.lockedHint,
                        style: Type.secondary.copyWith(color: p.textSecondary)),
                    const SizedBox(height: Gap.l),
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      style: Type.value.copyWith(color: p.textPrimary),
                      decoration: InputDecoration(
                        labelText: Strings.pin,
                        errorText: _error,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Radius2.input)),
                      ),
                    ),
                    const SizedBox(height: Gap.l),
                    PrimaryButton(label: Strings.unlock, onPressed: _unlock),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _unlock() {
    if (_pin.text == '1234') {
      Preferences.shared.locked = false;
    } else {
      setState(() => _error = Strings.wrongPin);
    }
  }
}
