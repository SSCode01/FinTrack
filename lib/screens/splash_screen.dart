import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _particleController;

  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _logoScale;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // Continuous rotation for rings
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Pulse for the center icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Particle float
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Fade in everything
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Slide up text
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut));
    _taglineFade = CurvedAnimation(
        parent: _slideController, curve: Curves.easeIn);

    // Start animations with stagger
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF1A3A1A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // FLOATING PARTICLES
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticlePainter(_particleController.value),
                  size: size,
                );
              },
            ),

            // MAIN CONTENT
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ANIMATED LOGO AREA
                  FadeTransition(
                    opacity: _fadeIn,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // OUTER ROTATING RING
                            AnimatedBuilder(
                              animation: _rotateController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle:
                                      _rotateController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    painter: _RingPainter(
                                      color: const Color(0xFFFFD700)
                                          .withOpacity(0.3),
                                      strokeWidth: 2,
                                      dashed: true,
                                    ),
                                    size: const Size(170, 170),
                                  ),
                                );
                              },
                            ),

                            // MIDDLE RING (counter rotate)
                            AnimatedBuilder(
                              animation: _rotateController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle:
                                      -_rotateController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    painter: _RingPainter(
                                      color: Colors.white.withOpacity(0.15),
                                      strokeWidth: 1.5,
                                      dashed: false,
                                    ),
                                    size: const Size(130, 130),
                                  ),
                                );
                              },
                            ),

                            // PULSING GLOW CIRCLE
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 90 + (_pulseController.value * 10),
                                  height: 90 + (_pulseController.value * 10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFD700)
                                        .withOpacity(0.08 +
                                            _pulseController.value * 0.06),
                                  ),
                                );
                              },
                            ),

                            // CENTER ICON CIRCLE
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1B5E20),
                                border: Border.all(
                                  color: const Color(0xFFFFD700),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700)
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFFFFD700),
                                size: 36,
                              ),
                            ),

                            // ORBITING DOT
                            AnimatedBuilder(
                              animation: _rotateController,
                              builder: (context, child) {
                                final angle =
                                    _rotateController.value * 2 * math.pi;
                                return Transform.translate(
                                  offset: Offset(
                                    75 * math.cos(angle),
                                    75 * math.sin(angle),
                                  ),
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFFFD700),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // SECOND ORBITING DOT (offset)
                            AnimatedBuilder(
                              animation: _rotateController,
                              builder: (context, child) {
                                final angle =
                                    _rotateController.value * 2 * math.pi +
                                        math.pi;
                                return Transform.translate(
                                  offset: Offset(
                                    75 * math.cos(angle),
                                    75 * math.sin(angle),
                                  ),
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // APP NAME
                  AnimatedBuilder(
                    animation: _slideController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideUp.value),
                        child: FadeTransition(
                          opacity: _taglineFade,
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      'FinTrack',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // TAGLINE
                  AnimatedBuilder(
                    animation: _slideController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideUp.value * 1.5),
                        child: FadeTransition(
                          opacity: _taglineFade,
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      'Track money. Stay in control.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // LOADING DOTS
                  FadeTransition(
                    opacity: _fadeIn,
                    child: _LoadingDots(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ANIMATED LOADING DOTS
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _animations = _controllers
        .map((c) =>
            Tween<double>(begin: 0, end: -10).animate(
                CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD700).withOpacity(0.6 + i * 0.2),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// RING PAINTER
class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool dashed;

  _RingPainter(
      {required this.color,
      required this.strokeWidth,
      required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (dashed) {
      const dashCount = 16;
      const dashAngle = math.pi / dashCount;
      for (int i = 0; i < dashCount; i++) {
        final startAngle = i * 2 * dashAngle;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          dashAngle * 0.6,
          false,
          paint,
        );
      }
    } else {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// FLOATING PARTICLES PAINTER
class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ParticlePainter(this.progress)
      : particles = List.generate(
            18,
            (i) => _Particle(
                  x: (i * 137.5) % 100,
                  y: (i * 73.3) % 100,
                  size: 2.0 + (i % 3) * 1.5,
                  speed: 0.3 + (i % 4) * 0.2,
                  opacity: 0.1 + (i % 5) * 0.06,
                ));

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = const Color(0xFFFFD700)
            .withOpacity(p.opacity * (0.5 + 0.5 * math.sin(progress * 2 * math.pi + p.x)))
        ..style = PaintingStyle.fill;

      final yOffset = (progress * p.speed * size.height) % size.height;
      final x = p.x / 100 * size.width;
      final y = (p.y / 100 * size.height - yOffset + size.height) % size.height;

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, opacity;
  _Particle(
      {required this.x,
      required this.y,
      required this.size,
      required this.speed,
      required this.opacity});
}
