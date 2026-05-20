import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ziggy_game.dart';

class WallPair extends PositionComponent with HasGameRef<ZiggyGame> {
  final double gapCenter;
  final double gapWidth;
  final double speed;

  bool _scored = false;

  static const List<Color> _wallColors = [
    ZiggyGame.neonPink,
    ZiggyGame.neonPurple,
    ZiggyGame.neonGreen,
    ZiggyGame.neonYellow,
  ];
  static int _colorIndex = 0;
  late Color _wallColor;

  // Thicker walls for more visual weight
  static const double wallHeight = 28.0;

  WallPair({
    required this.gapCenter,
    required this.gapWidth,
    required this.speed,
  }) : super(
          position: Vector2(0, -wallHeight),
          size: Vector2(ZiggyGame.gameWidth, wallHeight),
        ) {
    _wallColor = _wallColors[_colorIndex % _wallColors.length];
    _colorIndex++;
  }

  @override
  Future<void> onLoad() async {
    final leftWidth = gapCenter - gapWidth / 2;
    final rightStart = gapCenter + gapWidth / 2;
    final rightWidth = ZiggyGame.gameWidth - rightStart;

    if (leftWidth > 0) {
      add(_WallSegment(
        localPosition: Vector2(0, 0),
        size: Vector2(leftWidth, wallHeight),
        color: _wallColor,
      ));
    }

    if (rightWidth > 0) {
      add(_WallSegment(
        localPosition: Vector2(rightStart, 0),
        size: Vector2(rightWidth, wallHeight),
        color: _wallColor,
      ));
    }
  }

  @override
  void update(double dt) {
    position.y += speed * dt;

    if (!_scored && position.y > ZiggyGame.gameHeight * 0.75) {
      _scored = true;
      game.onBallPassedWall();
    }

    if (position.y > ZiggyGame.gameHeight + wallHeight) {
      removeFromParent();
    }
  }
}

class _WallSegment extends PositionComponent
    with HasGameRef<ZiggyGame>, CollisionCallbacks {
  final Color color;
  double _glowPulse = 0;

  _WallSegment({
    required Vector2 localPosition,
    required Vector2 size,
    required this.color,
  }) : super(position: localPosition, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    _glowPulse += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    final pulse = sin(_glowPulse) * 0.2 + 0.8;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // ── Wide outer atmospheric glow ──
    canvas.drawRect(
      rect.inflate(22),
      Paint()
        ..color = color.withOpacity(0.18 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // ── Tighter bright glow halo ──
    canvas.drawRect(
      rect.inflate(10),
      Paint()
        ..color = color.withOpacity(0.38 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── Main wall body with gradient ──
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.98),
            color.withOpacity(0.72),
          ],
        ).createShader(rect),
    );

    // ── Bright top edge highlight ──
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 3.0),
      Paint()..color = Colors.white.withOpacity(0.92 * pulse),
    );

    // ── Secondary top glow line ──
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 6.0),
      Paint()
        ..color = Colors.white.withOpacity(0.35 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── Bottom edge highlight ──
    canvas.drawRect(
      Rect.fromLTWH(0, size.y - 2.5, size.x, 2.5),
      Paint()..color = Colors.white.withOpacity(0.55 * pulse),
    );

    // ── Bottom glow strip ──
    canvas.drawRect(
      Rect.fromLTWH(0, size.y - 5, size.x, 5),
      Paint()
        ..color = color.withOpacity(0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }
}
