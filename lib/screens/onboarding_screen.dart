import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      painter: _TrackPainter(),
      title: 'Track Every Rupee',
      subtitle:
          'Keep a clear record of who owes you and who you owe. Never forget a debt again.',
      accentColor: Color(0xFF2E7D32),
    ),
    _OnboardingPage(
      painter: _SplitPainter(),
      title: 'Split Bills Easily',
      subtitle:
          'Divide expenses among friends instantly — equal splits or custom amounts, your choice.',
      accentColor: Color(0xFF1565C0),
    ),
    _OnboardingPage(
      painter: _InsightPainter(),
      title: 'Insights at a Glance',
      subtitle:
          'Dashboard, calendar view, and category breakdowns so you always know where you stand.',
      accentColor: Color(0xFF6A1B9A),
    ),
  ];

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137), Color(0xFF0A1F1A)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentPage = i);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _PageContent(page: _pages[i]),
                ),
              ),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFFFD700)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Next / Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          SizedBox(
            width: 220,
            height: 200,
            child: CustomPaint(painter: page.painter),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.2),
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white54, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final CustomPainter painter;
  final String title;
  final String subtitle;
  final Color accentColor;
  const _OnboardingPage({
    required this.painter,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}

// ── ILLUSTRATION 1: Track — phone with transaction list ────────────────────
class _TrackPainter extends CustomPainter {
  const _TrackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Phone body
    final phonePaint = Paint()..color = const Color(0xFF0D1F2D);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.2, h * 0.05, w * 0.6, h * 0.85),
            const Radius.circular(20)),
        phonePaint);

    // Phone border
    final borderPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.2, h * 0.05, w * 0.6, h * 0.85),
            const Radius.circular(20)),
        borderPaint);

    // Screen area
    final screenPaint = Paint()..color = const Color(0xFF0A1628);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.24, h * 0.12, w * 0.52, h * 0.7),
            const Radius.circular(12)),
        screenPaint);

    // Transaction rows
    final rows = [
      (Colors.greenAccent, 0.18, '+ ₹500'),
      (Colors.redAccent, 0.30, '- ₹200'),
      (Colors.greenAccent, 0.42, '+ ₹1,200'),
      (Colors.redAccent, 0.54, '- ₹350'),
    ];

    for (final row in rows) {
      final color = row.$1 as Color;
      final yRatio = row.$2 as double;
      final label = row.$3 as String;

      // Avatar circle
      canvas.drawCircle(
          Offset(w * 0.31, h * yRatio + 8),
          8,
          Paint()..color = color.withOpacity(0.25));
      canvas.drawCircle(
          Offset(w * 0.31, h * yRatio + 8),
          4,
          Paint()..color = color);

      // Name bar
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.37, h * yRatio + 2, w * 0.18, 6),
              const Radius.circular(3)),
          Paint()..color = Colors.white24);

      // Amount text
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(w * 0.58, h * yRatio + 1));

      // Divider
      canvas.drawLine(
          Offset(w * 0.27, h * yRatio + 20),
          Offset(w * 0.73, h * yRatio + 20),
          Paint()
            ..color = Colors.white10
            ..strokeWidth = 0.5);
    }

    // Home button
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.92),
        6,
        Paint()
          ..color = Colors.white12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Gold glow
    canvas.drawCircle(
        Offset(w * 0.75, h * 0.08),
        18,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.12));
    canvas.drawCircle(
        Offset(w * 0.75, h * 0.08),
        8,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── ILLUSTRATION 2: Split — pie divided among people ──────────────────────
class _SplitPainter extends CustomPainter {
  const _SplitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.45);
    final radius = w * 0.28;

    // Pie slices
    final slices = [
      (const Color(0xFF2E7D32), 0.0, 1.2),
      (const Color(0xFF1565C0), 1.2, 2.4),
      (const Color(0xFFFFD700), 2.4, 4.2),
      (Colors.purpleAccent, 4.2, 6.28),
    ];

    for (final s in slices) {
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          s.$2 as double,
          (s.$3 as double) - (s.$2 as double),
          true,
          Paint()..color = s.$1 as Color);
      // Gap between slices
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          s.$2 as double,
          (s.$3 as double) - (s.$2 as double),
          true,
          Paint()
            ..color = const Color(0xFF0A1628)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }

    // Center circle (donut hole)
    canvas.drawCircle(
        center, radius * 0.45, Paint()..color = const Color(0xFF0A1628));

    // Rupee in center
    final tp = TextPainter(
      text: const TextSpan(
          text: '₹',
          style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 22,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));

    // Person avatars around pie
    final avatarPositions = [
      Offset(w * 0.12, h * 0.18),
      Offset(w * 0.82, h * 0.22),
      Offset(w * 0.18, h * 0.72),
      Offset(w * 0.8, h * 0.7),
    ];
    final avatarColors = [
      const Color(0xFF2E7D32),
      const Color(0xFF1565C0),
      const Color(0xFFFFD700),
      Colors.purpleAccent,
    ];
    final avatarLabels = ['A', 'B', 'C', 'D'];

    for (int i = 0; i < avatarPositions.length; i++) {
      // Connector line
      canvas.drawLine(
          avatarPositions[i],
          center,
          Paint()
            ..color = avatarColors[i].withOpacity(0.2)
            ..strokeWidth = 1);

      // Avatar
      canvas.drawCircle(
          avatarPositions[i], 16, Paint()..color = avatarColors[i].withOpacity(0.2));
      canvas.drawCircle(
          avatarPositions[i],
          16,
          Paint()
            ..color = avatarColors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);

      final ltp = TextPainter(
        text: TextSpan(
            text: avatarLabels[i],
            style: TextStyle(
                color: avatarColors[i],
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      ltp.layout();
      ltp.paint(canvas,
          Offset(avatarPositions[i].dx - ltp.width / 2, avatarPositions[i].dy - ltp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── ILLUSTRATION 3: Insights — bar chart + calendar dots ──────────────────
class _InsightPainter extends CustomPainter {
  const _InsightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Card background
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.9, h * 0.88),
            const Radius.circular(20)),
        Paint()..color = const Color(0xFF0D1F2D));

    // Bar chart
    final bars = [0.4, 0.7, 0.5, 0.9, 0.6, 0.75];
    final barColors = [
      Colors.greenAccent,
      const Color(0xFFFFD700),
      Colors.greenAccent,
      const Color(0xFFFFD700),
      Colors.greenAccent,
      const Color(0xFFFFD700),
    ];
    final barW = w * 0.08;
    final chartBottom = h * 0.62;
    final chartTop = h * 0.18;
    final chartH = chartBottom - chartTop;

    for (int i = 0; i < bars.length; i++) {
      final x = w * 0.12 + i * (barW + w * 0.04);
      final barH = chartH * bars[i];
      final rect = Rect.fromLTWH(x, chartBottom - barH, barW, barH);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = barColors[i].withOpacity(0.7));
    }

    // Baseline
    canvas.drawLine(
        Offset(w * 0.1, chartBottom),
        Offset(w * 0.9, chartBottom),
        Paint()
          ..color = Colors.white12
          ..strokeWidth = 1);

    // Calendar mini grid below
    final calTop = h * 0.68;
    final dotColors = [
      Colors.greenAccent,
      Colors.transparent,
      Colors.redAccent,
      Colors.transparent,
      Colors.greenAccent,
      Colors.greenAccent,
      Colors.transparent,
    ];

    for (int col = 0; col < 7; col++) {
      for (int row = 0; row < 3; row++) {
        final cx = w * 0.14 + col * w * 0.115;
        final cy = calTop + row * h * 0.07;
        canvas.drawCircle(
            Offset(cx, cy),
            4,
            Paint()..color = Colors.white10);
        if (dotColors[(col + row) % dotColors.length] != Colors.transparent) {
          canvas.drawCircle(
              Offset(cx, cy),
              3,
              Paint()..color = dotColors[(col + row) % dotColors.length]);
        }
      }
    }

    // Gold glow top right
    canvas.drawCircle(
        Offset(w * 0.85, h * 0.1),
        14,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.15));
    canvas.drawCircle(
        Offset(w * 0.85, h * 0.1),
        6,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
