// DESIGN.md's promise, measured: every text colour against every glass fill
// composited on every wash, light and dark, glass and solid. 7:1 for
// primary text (clinical values are set in it), 4.5:1 for secondary. The
// audit tools cannot read a gradient; this can.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/design/palette.dart';

double _lum(Color c) {
  double lin(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

double _ratio(Color fg, Color bg) {
  final a = _lum(fg), b = _lum(bg);
  final hi = a > b ? a : b, lo = a > b ? b : a;
  return (hi + 0.05) / (lo + 0.05);
}

/// A translucent fill composited on a wash composited on the base.
Color _over(Color top, Color under) {
  final a = top.a;
  return Color.from(
    alpha: 1,
    red: top.r * a + under.r * (1 - a),
    green: top.g * a + under.g * (1 - a),
    blue: top.b * a + under.b * (1 - a),
  );
}

void main() {
  for (final (name, p) in [('light', Palette.light), ('dark', Palette.dark)]) {
    test('$name: every text colour reads on every fill over every wash', () {
      final washes = {
        'base': p.base,
        'washA': _over(p.washA.withValues(alpha: 0.6), p.base),
        'washB': _over(p.washB.withValues(alpha: 0.6), p.base),
        'washC': _over(p.washC.withValues(alpha: 0.6), p.base)
      };
      final fills = {
        'glassLow': p.glassLow,
        'glassMid': p.glassMid,
        'glassHigh': p.glassHigh,
        'solidLow': p.solidLow,
        'solidMid': p.solidMid,
        'solidHigh': p.solidHigh
      };
      final failures = <String>[];
      for (final w in washes.entries) {
        for (final f in fills.entries) {
          final bg = _over(f.value, w.value);
          for (final (label, fg, floor) in [
            ('textPrimary', p.textPrimary, 7.0),
            ('textSecondary', p.textSecondary, 4.5),
            ('attention', p.attention, 3.0),
            ('danger', p.danger, 3.0),
            ('fine', p.fine, 3.0)
          ]) {
            final r = _ratio(fg, bg);
            if (r < floor) {
              failures.add(
                  '$label on ${f.key} over ${w.key}: ${r.toStringAsFixed(2)} < $floor');
            }
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
      expect(_ratio(p.textOnAccent, p.accent), greaterThanOrEqualTo(4.5),
          reason: 'onAccent on accent');
      expect(_ratio(p.textOnAccent, p.accentEnd), greaterThanOrEqualTo(4.5),
          reason: 'onAccent on accentEnd');
    });
  }

  test('the ratio function is right about black on white', () {
    expect(_ratio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01));
  });
}
