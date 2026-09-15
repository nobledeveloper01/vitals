// DESIGN.md's type scale. Inter for the interface; clinical values in a
// monospaced face so a 9 and a 0 never blur at arm's length. Every style
// scales with the platform's text size.
import 'package:flutter/material.dart';

abstract final class Type {
  static const family = 'Inter';

  static const display = TextStyle(
      fontFamily: family,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2);
  static const headline = TextStyle(
      fontFamily: family,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.25);
  static const value = TextStyle(
      fontFamily: 'monospace',
      fontSize: 24,
      fontWeight: FontWeight.w500,
      height: 1.2,
      fontFeatures: [FontFeature.tabularFigures()]);
  static const title = TextStyle(
      fontFamily: family,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.3);
  static const body = TextStyle(
      fontFamily: family,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5);
  static const secondary = TextStyle(
      fontFamily: family,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45);
  static const small = TextStyle(
      fontFamily: family,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.4);
}

abstract final class Target {
  static const double standard = 48;
  static const double nurse = 56;
  static const double primary = 64;
}

abstract final class Radius2 {
  static const double card = 20;
  static const double sheet = 28;
  static const double chip = 14;
  static const double input = 12;
}

abstract final class Gap {
  static const double xs = 4, s = 8, sm = 12, m = 16, l = 24, xl = 32, xxl = 48;
}
