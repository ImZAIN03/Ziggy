import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ziggy_game.dart';
import 'ball.dart';

class _TrailPoint {
  final Vector2 position;
  double age;

  _TrailPoint(Vector2 pos) : position = pos.clone(), age = 0;
}

class Trail extends Component with HasGameRef<ZiggyGame> {
  final Ball ballRef;
  final List<_TrailPoint> _points = [];

  // Slightly longer trail for the bigger ball
  static const double _maxAge = 0.40;
  static const double _spacing = 2.5;
  static const double _teleportThreshold = 80.0;

  double _distAccum = 0;
  Vector2? _lastPos;

  Trail({required this.ballRef});

  @override
  void update(double dt) {
    if (!game.isPlaying) {
      _points.clear();
      _lastPos = null;
      _distAccum = 0;
      return;
    }

    final currentPos = ballRef.position.clone();

    // Detect teleport (ball reset) and clear trail
    if (_lastPos != null &&
        currentPos.distanceTo(_lastPos!) > _teleportThreshold) {
      _points.clear();
      _distAccum = 0;
    }

    if (_lastPos != null) {
      _distAccum += currentPos.distanceTo(_lastPos!);
      if (_distAccum >= _spacing) {
        _distAccum = 0;
        _points.add(_TrailPoint(currentPos));
      }
    } else {
      _points.add(_TrailPoint(currentPos));
    }
    _lastPos = currentPos;

    for (final p in _points) {
      p.age += dt;
    }
    _points.removeWhere((p) => p.age >= _maxAge);
  }

  @override
  void render(Canvas canvas) {
    for (final p in _points) {
      final t = 1.0 - (p.age / _maxAge);
      final r = Ball.radius * 0.65 * t;

      // Outer soft glow
      canvas.drawCircle(
        Offset(p.position.x, p.position.y),
        r * 1.8,
        Paint()
          ..color = ZiggyGame.neonCyan.withOpacity(0.20 * t)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.2),
      );

      // Core trail dot
      canvas.drawCircle(
        Offset(p.position.x, p.position.y),
        r,
        Paint()
          ..color = ZiggyGame.neonCyan.withOpacity(0.55 * t)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
      );
    }
  }
}
