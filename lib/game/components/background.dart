import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ziggy_game.dart';

// ─── Scrolling grid lines ─────────────────────────────────────────────────────

class _GridLine {
  double y;
  _GridLine(this.y);
}

// ─── Floating depth particles ─────────────────────────────────────────────────

class _FloatParticle {
  double x, y;
  double speed;  // upward drift speed (px/s)
  double radius;
  double opacity;
  Color color;
  double twinklePhase; // individual phase offset for twinkle

  _FloatParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.opacity,
    required this.color,
    required this.twinklePhase,
  });
}

// ─── Main background component ────────────────────────────────────────────────

class NeonBackground extends PositionComponent with HasGameRef<ZiggyGame> {
  final List<_GridLine> _hLines = [];
  final List<double> _vLines = [];
  final List<_FloatParticle> _floatParticles = [];
  final Random _rng = Random(42); // seeded so layout is deterministic

  double _time = 0;

  static const int _numHLines = 10;
  static const int _numVLines = 8;
  static const int _numParticles = 32;

  // Particle colour palette (muted neons)
  static const List<Color> _particleColors = [
    Color(0xFF00FFFF), // cyan
    Color(0xFFBB00FF), // purple
    Color(0xFF00FF88), // green
    Color(0xFFFFFFFF), // white
  ];

  NeonBackground()
      : super(
          position: Vector2.zero(),
          size: Vector2(ZiggyGame.gameWidth, ZiggyGame.gameHeight),
        );

  @override
  Future<void> onLoad() async {
    // Horizontal scrolling grid lines
    final hSpacing = ZiggyGame.gameHeight / _numHLines;
    for (int i = 0; i < _numHLines; i++) {
      _hLines.add(_GridLine(i * hSpacing));
    }

    // Vertical static grid lines
    for (int i = 0; i <= _numVLines; i++) {
      _vLines.add(i * ZiggyGame.gameWidth / _numVLines);
    }

    // Floating depth particles — small, slow, subtle
    for (int i = 0; i < _numParticles; i++) {
      _floatParticles.add(_FloatParticle(
        x: _rng.nextDouble() * ZiggyGame.gameWidth,
        y: _rng.nextDouble() * ZiggyGame.gameHeight,
        speed: 6.0 + _rng.nextDouble() * 18.0,
        radius: 1.0 + _rng.nextDouble() * 2.2,
        opacity: 0.15 + _rng.nextDouble() * 0.30,
        color: _particleColors[_rng.nextInt(_particleColors.length)],
        twinklePhase: _rng.nextDouble() * pi * 2,
      ));
    }
  }

  @override
  void update(double dt) {
    _time += dt;

    // Scroll horizontal grid lines downward (parallax feel)
    final gridSpeed = 55.0 * (game.isPlaying ? game.gameSpeed : 1.0);
    for (final line in _hLines) {
      line.y += gridSpeed * dt;
      if (line.y > ZiggyGame.gameHeight) line.y -= ZiggyGame.gameHeight;
    }

    // Float particles drift upward slowly
    final particleSpeed = game.isPlaying ? game.gameSpeed : 1.0;
    for (final p in _floatParticles) {
      p.y -= p.speed * particleSpeed * dt;
      if (p.y < -6) p.y = ZiggyGame.gameHeight + 6;
    }
  }

  @override
  void render(Canvas canvas) {
    final fullRect =
        Rect.fromLTWH(0, 0, ZiggyGame.gameWidth, ZiggyGame.gameHeight);

    // ── 1. Deep space gradient background ──
    canvas.drawRect(
      fullRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060818), Color(0xFF030410)],
        ).createShader(fullRect),
    );

    // ── 2. Subtle centre radial accent ──
    canvas.drawRect(
      fullRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            ZiggyGame.neonCyan.withOpacity(0.035),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(ZiggyGame.gameWidth / 2, ZiggyGame.gameHeight * 0.4),
          radius: ZiggyGame.gameWidth * 0.8,
        )),
    );

    // ── 3. Scrolling grid lines ──
    final gridPaint = Paint()
      ..color = const Color(0xFF14143A)
      ..strokeWidth = 1.0;

    for (final line in _hLines) {
      canvas.drawLine(
        Offset(0, line.y),
        Offset(ZiggyGame.gameWidth, line.y),
        gridPaint,
      );
    }
    for (final x in _vLines) {
      canvas.drawLine(Offset(x, 0), Offset(x, ZiggyGame.gameHeight), gridPaint);
    }

    // ── 4. Floating depth particles ──
    for (final p in _floatParticles) {
      // Each particle twinkles at its own pace
      final twinkle = sin(_time * 1.8 + p.twinklePhase) * 0.35 + 0.65;
      final effectiveOpacity = p.opacity * twinkle;

      // Soft glow halo
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius * 3.0,
        Paint()
          ..color = p.color.withOpacity(effectiveOpacity * 0.30)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2.5),
      );

      // Bright core dot
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius,
        Paint()
          ..color = p.color.withOpacity(effectiveOpacity),
      );
    }

    // ── 5. Bottom horizon purple glow ──
    final bottomRect = Rect.fromLTWH(
        0, ZiggyGame.gameHeight - 70, ZiggyGame.gameWidth, 70);
    canvas.drawRect(
      bottomRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            ZiggyGame.neonPurple.withOpacity(0.14),
            Colors.transparent,
          ],
        ).createShader(bottomRect),
    );
  }
}
