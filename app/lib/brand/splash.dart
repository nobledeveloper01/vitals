// The splash: the mark on the mesh, the brand gradient sweeping through it
// once, then the app. Under reduced motion it cuts. Painted the same colour
// as the launch screen, so there is no flash on handover.
import 'package:flutter/material.dart';

import '../design/glass.dart';
import '../design/motion.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';

class Splash extends StatefulWidget {
  const Splash({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: Motion.shared.of(Motion.sweep));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Mesh(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) => ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment(-1 + 2 * _c.value * 2 - 2, 0),
                  end: Alignment(-1 + 2 * _c.value * 2, 0),
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.35),
                    Colors.transparent
                  ],
                ).createShader(rect),
                child: child,
              ),
              child: Semantics(
                label: Strings.appName,
                image: true,
                child: Image.asset('assets/mark/mark.png',
                    width: 112, height: 112, excludeFromSemantics: true),
              ),
            ),
            const SizedBox(height: Gap.l),
            Text(Strings.appName,
                style: Type.display.copyWith(color: p.textPrimary)),
            const SizedBox(height: Gap.s),
            Text(Strings.tagline,
                style: Type.secondary.copyWith(color: p.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
