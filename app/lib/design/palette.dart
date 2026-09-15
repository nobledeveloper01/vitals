// The roles DESIGN.md names, as colour. Light and dark authored together;
// every text colour is asserted in CI against every glass fill composited
// on every wash. Colour is never the sole carrier of meaning.
import 'package:flutter/material.dart';

enum Brightness2 { light, dark }

final class Palette {
  const Palette._({
    required this.base,
    required this.washA,
    required this.washB,
    required this.washC,
    required this.glassLow,
    required this.glassMid,
    required this.glassHigh,
    required this.solidLow,
    required this.solidMid,
    required this.solidHigh,
    required this.glassBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnAccent,
    required this.accent,
    required this.accentEnd,
    required this.attention,
    required this.danger,
    required this.fine,
    required this.hairline,
    required this.code,
  });

  final Color base, washA, washB, washC;
  final Color glassLow, glassMid, glassHigh;
  final Color solidLow, solidMid, solidHigh;
  final Color glassBorder;
  final Color textPrimary, textSecondary, textOnAccent;
  final Color accent, accentEnd, attention, danger, fine, hairline;

  /// A QR code's modules: pure black in both palettes, because a camera
  /// reads it, not a person.
  final Color code;

  /// The brand gradient: the mark, the splash, the primary action, a transfer.
  LinearGradient get brand => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent, accentEnd],
      );

  static const light = Palette._(
    base: Color(0xFFF4F7FA),
    washA: Color(0xFFD7EFF2),
    washB: Color(0xFFE6E0F7),
    washC: Color(0xFFF9EBE3),
    glassLow: Color(0x8CFFFFFF),
    glassMid: Color(0xB3FFFFFF),
    glassHigh: Color(0xD9FFFFFF),
    solidLow: Color(0xFFFFFFFF),
    solidMid: Color(0xFFF8FAFC),
    solidHigh: Color(0xFFFFFFFF),
    glassBorder: Color(0x99FFFFFF),
    textPrimary: Color(0xFF0B1220),
    textSecondary: Color(0xFF4A5568),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFF0F6E7A),
    accentEnd: Color(0xFF5B3FA8),
    attention: Color(0xFF9A5B00),
    danger: Color(0xFFB3261E),
    fine: Color(0xFF1C7A3C),
    hairline: Color(0xFFC8D2DE),
    code: Color(0xFF000000),
  );

  static const dark = Palette._(
    base: Color(0xFF0A0F16),
    washA: Color(0xFF0F3A44),
    washB: Color(0xFF2B1E5A),
    washC: Color(0xFF3A1F2E),
    glassLow: Color(0x0FFFFFFF),
    glassMid: Color(0x1AFFFFFF),
    glassHigh: Color(0x29FFFFFF),
    solidLow: Color(0xFF131A24),
    solidMid: Color(0xFF1B2431),
    solidHigh: Color(0xFF24303F),
    glassBorder: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFF2F6FA),
    textSecondary: Color(0xFFB4BFCC),
    textOnAccent: Color(0xFF07111A),
    accent: Color(0xFF5FD3DF),
    accentEnd: Color(0xFFB39CFF),
    attention: Color(0xFFF5B54A),
    danger: Color(0xFFFF8A80),
    fine: Color(0xFF7BE0A0),
    hairline: Color(0xFF2E3A48),
    code: Color(0xFF000000),
  );

  static Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
