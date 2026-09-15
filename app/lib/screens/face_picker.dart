// First launch: which face is this device? A clinic tablet or a patient's
// own phone. Two glass cards, one question, remembered.
import 'package:flutter/material.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/preferences.dart';

class FacePicker extends StatelessWidget {
  const FacePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(Gap.l),
            children: [
              const SizedBox(height: Gap.xl),
              Text(Strings.chooseFace,
                  style: Type.display.copyWith(color: p.textPrimary)),
              const SizedBox(height: Gap.l),
              _FaceCard(
                  title: Strings.clinic,
                  hint: Strings.clinicHint,
                  icon: Icons.local_hospital_outlined,
                  onTap: () => Preferences.shared.face = Face.clinic),
              const SizedBox(height: Gap.m),
              _FaceCard(
                  title: Strings.patient,
                  hint: Strings.patientHint,
                  icon: Icons.person_outline,
                  onTap: () => Preferences.shared.face = Face.patient),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceCard extends StatelessWidget {
  const _FaceCard(
      {required this.title,
      required this.hint,
      required this.icon,
      required this.onTap});
  final String title, hint;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
      button: true,
      label: title,
      hint: hint,
      child: GestureDetector(
        onTap: onTap,
        child: Glass(
          depth: Depth.low,
          child: Row(
            children: [
              Container(
                width: Target.nurse,
                height: Target.nurse,
                decoration: BoxDecoration(
                    gradient: p.brand,
                    borderRadius: BorderRadius.circular(Radius2.chip)),
                child: Icon(icon, color: p.textOnAccent, size: 28),
              ),
              const SizedBox(width: Gap.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Type.title.copyWith(color: p.textPrimary)),
                    const SizedBox(height: Gap.xs),
                    Text(hint,
                        style: Type.secondary.copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
