import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game/ziggy_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ZiggyApp());
}

class ZiggyApp extends StatelessWidget {
  const ZiggyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ziggy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ZiggyGame _game;

  @override
  void initState() {
    super.initState();
    _game = ZiggyGame();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: _game,
      overlayBuilderMap: {
        'menu': (context, game) => MenuOverlay(game: game as ZiggyGame),
        'gameOver': (context, game) => GameOverOverlay(game: game as ZiggyGame),
      },
      initialActiveOverlays: const ['menu'],
    );
  }
}

// ─── Shared neon button ───────────────────────────────────────────────────────

class _NeonButton extends StatelessWidget {
  final String label;
  final Color glowColor;
  final VoidCallback onTap;

  const _NeonButton({
    required this.label,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 20),
        decoration: BoxDecoration(
          // Solid enough background so text is always readable
          color: glowColor.withOpacity(0.22),
          border: Border.all(color: glowColor, width: 2.5),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
                color: glowColor.withOpacity(0.75),
                blurRadius: 18,
                spreadRadius: 1),
            BoxShadow(
                color: glowColor.withOpacity(0.45),
                blurRadius: 36,
                spreadRadius: 3),
            BoxShadow(
                color: glowColor.withOpacity(0.20),
                blurRadius: 64,
                spreadRadius: 6),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 4,
            shadows: [
              Shadow(color: glowColor, blurRadius: 10),
              const Shadow(color: Colors.white, blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menu / Start screen ──────────────────────────────────────────────────────

class MenuOverlay extends StatefulWidget {
  final ZiggyGame game;
  const MenuOverlay({super.key, required this.game});

  @override
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Semi-opaque overlay so the game world is visible behind it
      color: Colors.black.withOpacity(0.68),
      child: Center(
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, _) {
            final g = _glow.value;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated ZIGGY title ──
                Text(
                  'ZIGGY',
                  style: GoogleFonts.orbitron(
                    fontSize: 84,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 14,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF00FFFF).withOpacity(g),
                        blurRadius: 16 + 28 * g,
                      ),
                      Shadow(
                        color: const Color(0xFF00FFFF).withOpacity(0.65 * g),
                        blurRadius: 55 * g,
                      ),
                      Shadow(
                        color: const Color(0xFF0077FF).withOpacity(0.45 * g),
                        blurRadius: 80 * g,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── Subtitle ──
                Text(
                  'HOW FAR CAN YOU GO?',
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF88CCFF),
                    letterSpacing: 3.5,
                    shadows: const [
                      Shadow(
                          color: Color(0xFF00FFFF), blurRadius: 10),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // ── CTA button ──
                _NeonButton(
                  label: 'TAP TO START',
                  glowColor: const Color(0xFF00FFFF),
                  onTap: widget.game.startGame,
                ),

                const SizedBox(height: 36),

                Text(
                  'TAP SCREEN TO FLIP DIRECTION',
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    color: const Color(0xFF3D6080),
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Game-Over screen ─────────────────────────────────────────────────────────

class GameOverOverlay extends StatelessWidget {
  final ZiggyGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.78),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── GAME OVER heading ──
            Text(
              'GAME OVER',
              style: GoogleFonts.orbitron(
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFF0066),
                letterSpacing: 6,
                shadows: const [
                  Shadow(color: Color(0xFFFF0066), blurRadius: 22),
                  Shadow(color: Color(0xFFFF0066), blurRadius: 52),
                  Shadow(color: Color(0xFFFF6688), blurRadius: 10),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // ── Score card ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 44, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                border: Border.all(
                  color: const Color(0xFF00FFFF).withOpacity(0.35),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFFF).withOpacity(0.12),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Score label
                  Text(
                    'SCORE',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      color: const Color(0xFF88AACC),
                      letterSpacing: 5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Score value — big & bright yellow
                  Text(
                    '${game.score}',
                    style: GoogleFonts.orbitron(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFFF00),
                      letterSpacing: 4,
                      shadows: const [
                        Shadow(color: Color(0xFFFFFF00), blurRadius: 22),
                        Shadow(color: Color(0xFFFFAA00), blurRadius: 36),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Divider(
                      color: const Color(0xFF00FFFF).withOpacity(0.2),
                      thickness: 1),
                  const SizedBox(height: 18),

                  // Best label
                  Text(
                    'BEST',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      color: const Color(0xFF88AACC),
                      letterSpacing: 5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Best value — green, clearly readable
                  Text(
                    '${game.bestScore}',
                    style: GoogleFonts.orbitron(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00FFAA),
                      letterSpacing: 4,
                      shadows: const [
                        Shadow(color: Color(0xFF00FFAA), blurRadius: 18),
                        Shadow(color: Color(0xFF00FFAA), blurRadius: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 56),

            _NeonButton(
              label: 'PLAY AGAIN',
              glowColor: const Color(0xFFFF0066),
              onTap: game.restartGame,
            ),
          ],
        ),
      ),
    );
  }
}
