// The page mesh and the three glass depths, each with its solid twin. Glass
// is a blur over the mesh and a translucent fill with a hairline border;
// when Motion.glass is off the same widget draws the solid colour and no
// blur, and the app is complete either way (ADR-0005).
import 'dart:ui';

import 'package:flutter/material.dart';

import 'motion.dart';
import 'palette.dart';
import 'type.dart';

enum Depth { low, mid, high }

/// The page: a fixed gradient mesh — three radial washes over the base —
/// painted once and cached. Nothing about it moves.
class Mesh extends StatelessWidget {
  const Mesh({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: p.base),
          CustomPaint(painter: _MeshPainter(p), willChange: false),
          child,
        ],
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter(this.p);
  final Palette p;

  @override
  void paint(Canvas canvas, Size size) {
    void wash(Color c, Offset centre, double radius) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [c, c.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: centre, radius: radius));
      canvas.drawRect(Offset.zero & size, paint);
    }

    wash(p.washA, Offset(size.width * 0.15, size.height * 0.1),
        size.width * 0.9);
    wash(p.washB, Offset(size.width * 0.95, size.height * 0.45),
        size.width * 0.8);
    wash(p.washC, Offset(size.width * 0.5, size.height * 1.05),
        size.width * 0.7);
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.p != p;
}

/// A glass panel at one of the three depths, or its solid twin.
class Glass extends StatelessWidget {
  const Glass(
      {super.key,
      required this.depth,
      required this.child,
      this.radius = Radius2.card,
      this.padding = const EdgeInsets.all(Gap.m)});
  final Depth depth;
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: Motion.shared,
      builder: (context, _) {
        final glass = Motion.shared.glass;
        final fill = switch (depth) {
          Depth.low => glass ? p.glassLow : p.solidLow,
          Depth.mid => glass ? p.glassMid : p.solidMid,
          Depth.high => glass ? p.glassHigh : p.solidHigh,
        };
        final blur = switch (depth) {
          Depth.low => 18.0,
          Depth.mid => 24.0,
          Depth.high => 30.0
        };
        final box = DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border:
                Border.all(color: glass ? p.glassBorder : p.hairline, width: 1),
          ),
          child: Padding(padding: padding, child: child),
        );
        if (!glass) return box;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: box),
        );
      },
    );
  }
}

/// The one primary action per screen: 64 dp, the brand gradient, pinned.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
                gradient: p.brand,
                borderRadius: BorderRadius.circular(Radius2.card)),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(Radius2.card),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    minHeight: Target.primary, minWidth: double.infinity),
                child: Center(
                    child: Text(label,
                        style: Type.title.copyWith(color: p.textOnAccent),
                        textAlign: TextAlign.center)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The quieter second action: a glass row.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
      {super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Glass(
      depth: Depth.mid,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(Radius2.card),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                minHeight: Target.nurse, minWidth: double.infinity),
            child: Center(
                child: Text(label,
                    style: Type.body.copyWith(color: p.textPrimary),
                    textAlign: TextAlign.center)),
          ),
        ),
      ),
    );
  }
}
