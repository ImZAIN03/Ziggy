import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ziggy_game.dart';
import 'trail.dart';

class Ball extends PositionComponent
    with HasGameRef<ZiggyGame>, CollisionCallbacks {
  // Larger radius for better presence on screen
  static const double radius = 16.0;
  static const double zigzagSpeed = 180.0;

  int _direction = 1;
  bool _isDead = false;
  double _glowPulse = 0;

  Ball({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: radius - 3, anchor: Anchor.center)
      ..collisionType = CollisionType.active);
    game.world.add(Trail(ballRef: this));
  }

  @override
  void update(double dt) {
    if (_isDead || !game.isPlaying) return;

    _glowPulse += dt * 4;

    final speed = zigzagSpeed * game.gameSpeed;
    position.x += _direction * speed * dt;

    if (position.x <= radius) {
      position.x = radius;
      _direction = 1;
    } else if (position.x >= ZiggyGame.gameWidth - radius) {
      position.x = ZiggyGame.gameWidth - radius;
      _direction = -1;
    }
  }

  @override
  void render(Canvas canvas) {
    final pulse = sin(_glowPulse) * 0.3 + 0.7;

    // ── Speed lines (drawn behind the ball, opposite to movement direction) ──
    _drawSpeedLines(canvas, pulse);

    // ── Intense multi-layer outer glow ──
    for (int i = 7; i >= 1; i--) {
      final glowRadius = radius + i * 5.5 * pulse;
      final opacity = (0.09 * pulse * (8 - i) / 7).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset.zero,
        glowRadius,
        Paint()
          ..color = ZiggyGame.neonCyan.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // ── Concentrated mid-glow ring ──
    canvas.drawCircle(
      Offset.zero,
      radius * 1.6,
      Paint()
        ..color = ZiggyGame.neonCyan.withOpacity(0.40 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── Core ball with rich gradient ──
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            ZiggyGame.neonCyan,
            const Color(0xFF0055DD),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: radius)),
    );

    // ── Bright glowing rim ──
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = ZiggyGame.neonCyan.withOpacity(0.55 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── Primary highlight ──
    canvas.drawCircle(
      const Offset(-4.5, -4.5),
      radius * 0.28,
      Paint()..color = Colors.white.withOpacity(0.92),
    );

    // ── Secondary micro-highlight ──
    canvas.drawCircle(
      const Offset(-2.5, -2.5),
      radius * 0.11,
      Paint()..color = Colors.white,
    );
  }

  void _drawSpeedLines(Canvas canvas, double pulse) {
    if (!game.isPlaying) return;

    // Lines trail opposite to the movement direction (motion-blur feel)
    final lineDirX = -_direction.toDouble();
    const numLines = 6;
    final speedFactor =
        ((game.gameSpeed - 1.0) / 2.5).clamp(0.0, 1.0);
    final baseOpacity = (0.28 + speedFactor * 0.38) * pulse;

    for (int i = 0; i < numLines; i++) {
      // Spread lines vertically around ball centre
      final yOff = (i - (numLines - 1) / 2.0) * 4.8;
      final len = 14.0 + i * 10.0 + speedFactor * 22.0;
      final opacity = (baseOpacity * (1.0 - i * 0.10)).clamp(0.0, 1.0);
      final sw = (2.2 - i * 0.28).clamp(0.4, 2.2);

      final startX = lineDirX * (radius + 3);
      final endX = lineDirX * (radius + 3 + len);

      canvas.drawLine(
        Offset(startX, yOff),
        Offset(endX, yOff),
        Paint()
          ..color = ZiggyGame.neonCyan.withOpacity(opacity)
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  void flipDirection() {
    if (_isDead) return;
    _direction = -_direction;
    game.triggerShake(3.0);
  }

  void reset(Vector2 pos) {
    _isDead = false;
    _direction = 1;
    position = pos;
  }

  void die() {
    if (_isDead) return;
    _isDead = true;
    game.triggerDeath();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    die();
  }
}
