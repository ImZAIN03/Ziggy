import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ziggy_game.dart';

class ScoreDisplay extends PositionComponent with HasGameRef<ZiggyGame> {
  int _score = 0;
  double _pulse = 0;
  double _bumpTimer = 0;

  ScoreDisplay()
      : super(
          position: Vector2(ZiggyGame.gameWidth / 2, 52),
          anchor: Anchor.center,
          size: Vector2(240, 90),
        );

  void updateScore(int score) {
    _score = score;
    _bumpTimer = 0.18;
  }

  @override
  void update(double dt) {
    _pulse += dt * 2.2;
    if (_bumpTimer > 0) _bumpTimer -= dt;
  }

  @override
  void render(Canvas canvas) {
    final bump = _bumpTimer > 0 ? 1.0 + (_bumpTimer / 0.18) * 0.30 : 1.0;
    final glowStrength = sin(_pulse) * 0.35 + 0.65;
    final fontSize = 58.0 * bump;

    // ── Wide glow layer ──
    final glowPainter = TextPainter(
      text: TextSpan(
        text: '$_score',
        style: GoogleFonts.orbitron(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..color = ZiggyGame.neonCyan.withOpacity(0.8 * glowStrength)
            ..maskFilter = MaskFilter.blur(
                BlurStyle.normal, 18 * glowStrength),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // ── Secondary glow (wider, softer) ──
    final outerGlowPainter = TextPainter(
      text: TextSpan(
        text: '$_score',
        style: GoogleFonts.orbitron(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..color = ZiggyGame.neonCyan.withOpacity(0.40 * glowStrength)
            ..maskFilter = MaskFilter.blur(
                BlurStyle.normal, 30 * glowStrength),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // ── Solid crisp text on top ──
    final solidPainter = TextPainter(
      text: TextSpan(
        text: '$_score',
        style: GoogleFonts.orbitron(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [
            Shadow(
              color: ZiggyGame.neonCyan.withOpacity(0.9),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = -solidPainter.width / 2;
    const dy = -32.0;

    outerGlowPainter.paint(canvas, Offset(dx, dy));
    glowPainter.paint(canvas, Offset(dx, dy));
    solidPainter.paint(canvas, Offset(dx, dy));
  }
}
