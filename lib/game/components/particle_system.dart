import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class _Particle {
  Vector2 position;
  Vector2 velocity;
  double life;
  double maxLife;
  double radius;
  Color color;
  double rotation;
  double rotationSpeed;

  _Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.radius,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  }) : maxLife = life;
}

class NeonParticleSystem extends Component {
  final List<_Particle> _particles = [];
  final Random _random = Random();

  void burst(Vector2 origin, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 80 + _random.nextDouble() * 320;
      final size = 3.0 + _random.nextDouble() * 6.0;

      _particles.add(_Particle(
        position: origin.clone(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        life: 0.4 + _random.nextDouble() * 0.6,
        radius: size,
        color: color,
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
      ));
    }
  }

  void spawnSpark(Vector2 origin, Color color) {
    final angle = _random.nextDouble() * pi * 2;
    final speed = 40 + _random.nextDouble() * 80;
    _particles.add(_Particle(
      position: origin.clone(),
      velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
      life: 0.2 + _random.nextDouble() * 0.2,
      radius: 2.0 + _random.nextDouble() * 3.0,
      color: color,
      rotation: 0,
      rotationSpeed: 0,
    ));
  }

  @override
  void update(double dt) {
    for (final p in _particles) {
      p.position += p.velocity * dt;
      p.velocity *= 1.0 - (dt * 3.5);
      p.life -= dt;
      p.rotation += p.rotationSpeed * dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      final opacity = t * t;
      final currentRadius = p.radius * (0.4 + 0.6 * t);

      canvas.save();
      canvas.translate(p.position.x, p.position.y);
      canvas.rotate(p.rotation);

      // Glow
      canvas.drawCircle(
        Offset.zero,
        currentRadius * 2,
        Paint()
          ..color = p.color.withOpacity(opacity * 0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentRadius),
      );

      // Core spark (diamond shape)
      final path = Path()
        ..moveTo(0, -currentRadius)
        ..lineTo(currentRadius * 0.5, 0)
        ..lineTo(0, currentRadius)
        ..lineTo(-currentRadius * 0.5, 0)
        ..close();

      canvas.drawPath(
        path,
        Paint()..color = p.color.withOpacity(opacity),
      );

      canvas.restore();
    }
  }
}
