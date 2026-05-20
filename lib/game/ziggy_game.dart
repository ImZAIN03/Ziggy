import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/ball.dart';
import 'components/wall_pair.dart';
import 'components/particle_system.dart';
import 'components/score_display.dart';
import 'components/background.dart';

class ZiggyGame extends FlameGame with TapCallbacks, HasCollisionDetection {
  static const double gameWidth = 400;
  static const double gameHeight = 800;

  late Ball ball;
  late ScoreDisplay scoreDisplay;
  late NeonBackground background;
  late NeonParticleSystem particles;

  final Random _random = Random();

  bool isPlaying = false;
  int score = 0;
  int bestScore = 0;

  double _wallTimer = 0;
  double _wallInterval = 2.2;
  double _gameSpeed = 1.0;
  double _elapsedTime = 0;

  double _shakeTimer = 0;
  double _shakeMaxTimer = 0;
  double _shakeIntensity = 0;

  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonPink = Color(0xFFFF0066);
  static const Color neonYellow = Color(0xFFFFFF00);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonPurple = Color(0xFFBB00FF);
  static const Color darkBg = Color(0xFF080818);

  @override
  Color backgroundColor() => darkBg;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.visibleGameSize = Vector2(gameWidth, gameHeight);
    camera.viewfinder.anchor = Anchor.topLeft;

    background = NeonBackground();
    world.add(background);

    particles = NeonParticleSystem();
    world.add(particles);

    ball = Ball(
      position: Vector2(gameWidth / 2, gameHeight * 0.75),
    );
    world.add(ball);

    scoreDisplay = ScoreDisplay();
    world.add(scoreDisplay);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isPlaying) {
      ball.flipDirection();
    }
  }

  void startGame() {
    overlays.remove('menu');
    _resetState();
    isPlaying = true;
  }

  void restartGame() {
    overlays.remove('gameOver');
    _resetState();
    isPlaying = true;
  }

  void _resetState() {
    score = 0;
    _wallTimer = 0;
    _wallInterval = 2.2;
    _gameSpeed = 1.0;
    _elapsedTime = 0;
    _shakeTimer = 0;
    _shakeMaxTimer = 0;

    world.children.whereType<WallPair>().toList().forEach((w) => w.removeFromParent());

    ball.reset(Vector2(gameWidth / 2, gameHeight * 0.75));
    scoreDisplay.updateScore(0);
  }

  void onBallPassedWall() {
    score++;
    scoreDisplay.updateScore(score);
    if (score > bestScore) bestScore = score;
  }

  void triggerDeath() {
    if (!isPlaying) return;
    isPlaying = false;

    _shakeTimer = 0.5;
    _shakeMaxTimer = 0.5;
    _shakeIntensity = 14.0;

    particles.burst(ball.position, neonPink, 40);
    particles.burst(ball.position, neonYellow, 20);

    Future.delayed(const Duration(milliseconds: 700), () {
      overlays.add('gameOver');
    });
  }

  void triggerShake(double intensity) {
    if (_shakeTimer < 0.1) {
      _shakeTimer = 0.15;
      _shakeMaxTimer = 0.15;
      _shakeIntensity = intensity;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isPlaying) return;

    _elapsedTime += dt;
    _gameSpeed = (1.0 + _elapsedTime * 0.015).clamp(1.0, 3.5);

    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      final s = _shakeIntensity * (_shakeMaxTimer > 0 ? _shakeTimer / _shakeMaxTimer : 0.0).clamp(0.0, 1.0);
      final shakeX = (_random.nextDouble() * 2 - 1) * s;
      final shakeY = (_random.nextDouble() * 2 - 1) * s;
      camera.viewfinder.position = Vector2(shakeX, shakeY);
    } else {
      camera.viewfinder.position = Vector2.zero();
    }

    _wallTimer += dt;
    if (_wallTimer >= _wallInterval / _gameSpeed) {
      _wallTimer = 0;
      _spawnWallPair();
    }
  }

  void _spawnWallPair() {
    final gapCenter = gameWidth * 0.2 + _random.nextDouble() * gameWidth * 0.6;
    final gapWidth = (110.0 - (_gameSpeed - 1.0) * 8.0).clamp(70.0, 110.0);

    world.add(WallPair(
      gapCenter: gapCenter,
      gapWidth: gapWidth,
      speed: 280.0 * _gameSpeed,
    ));
  }

  double get gameSpeed => _gameSpeed;
}
