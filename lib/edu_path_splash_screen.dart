import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';

class EduPathSplashScreen extends StatefulWidget {
  const EduPathSplashScreen({Key? key}) : super(key: key);

  @override
  State<EduPathSplashScreen> createState() => _EduPathSplashScreenState();
}

class _EduPathSplashScreenState extends State<EduPathSplashScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  double _progress = 0.0;
  late AnimationController _iconController;
  late AnimationController _cloudController1;
  late AnimationController _cloudController2;
  late AnimationController _cloudController3;
  late Animation<double> _iconFadeAnimation;

  // Icon-specific animations (splash_screen.dart ile birebir)
  late Animation<Offset> _iconSlideAnimationBook;
  late Animation<Offset> _iconSlideAnimationPerson;
  late Animation<Offset> _iconSlideAnimationMap;
  late Animation<Offset> _iconSlideAnimationSchool;
  late Animation<Offset> _iconSlideAnimationStar;
  late Animation<Offset> _iconSlideAnimationPsychology;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addListener(() {
        setState(() {
          _progress = _progressController.value;
        });
      });
    _progressController.forward();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _iconFadeAnimation = CurvedAnimation(parent: _iconController, curve: Curves.easeIn);

    // Cloud animasyonları (farklı hızlarda ve sürekli)
    _cloudController1 = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _cloudController2 = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _cloudController3 = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();

    // Animasyonlar splash_screen.dart ile aynı mantıkta (farklı ikonlar)
    _iconSlideAnimationBook = Tween<Offset>(
      begin: const Offset(-1.5, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeInOutBack));
    _iconSlideAnimationPerson = Tween<Offset>(
      begin: const Offset(1.5, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeInOutBack));
    _iconSlideAnimationMap = Tween<Offset>(
      begin: const Offset(-1.5, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.elasticOut));
    _iconSlideAnimationSchool = Tween<Offset>(
      begin: const Offset(1.5, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.elasticOut));
    _iconSlideAnimationStar = Tween<Offset>(
      begin: const Offset(-2.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeInOutSine));
    _iconSlideAnimationPsychology = Tween<Offset>(
      begin: const Offset(2.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeInOutSine));

    // Splash sonrası yönlendirme (örnek)
    Future.delayed(const Duration(milliseconds: 2800), () {
      // Navigator.pushReplacement...
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _iconController.dispose();
    _cloudController1.dispose();
    _cloudController2.dispose();
    _cloudController3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Path ve ikonlarını 120 pixel aşağı kaydır
    final pathTop = screenSize.height * 0.62 - 300 + 120;
    final pathPoints = [
      Offset(screenSize.width * 0.15, pathTop + screenSize.height * 0.22),
      Offset(screenSize.width * 0.25, pathTop + screenSize.height * 0.07),
      Offset(screenSize.width * 0.5, pathTop + screenSize.height * 0.13),
      Offset(screenSize.width * 0.75, pathTop - screenSize.height * 0.03),
      Offset(screenSize.width * 0.85, pathTop - screenSize.height * 0.15),
    ];

    return Scaffold(
      body: Container(
        color: const Color(0xFF2A3FFF),
        child: Stack(
          children: [
            // Animated Icons (splash_screen.dart ile aynı konum ve hareket)
            _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationBook,
              icon: Icons.menu_book,
              top: screenSize.height * 0.12,
              left: screenSize.width * 0.08,
              color: Colors.amber,
              size: 36,
            ),
            _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationPerson,
              icon: Icons.person,
              top: screenSize.height * 0.15,
              left: screenSize.width * 0.82,
              color: Colors.white,
              size: 34,
            ),
            _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationMap,
              icon: Icons.map,
              top: screenSize.height * 0.75,
              left: screenSize.width * 0.1,
              color: Colors.lightBlueAccent,
              size: 38,
            ),
            _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationSchool,
              icon: Icons.school,
              top: screenSize.height * 0.72,
              left: screenSize.width * 0.8,
              color: Colors.pinkAccent,
              size: 34,
            ),
            _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationStar,
              icon: Icons.star,
              top: screenSize.height * 0.45,
              left: screenSize.width * 0.05,
              color: Colors.greenAccent,
              size: 32,
            ),
            _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationPsychology,
              icon: Icons.psychology,
              top: screenSize.height * 0.50,
              left: screenSize.width * 0.85,
              color: Colors.amber,
              size: 32,
            ),
            // Kıvrımlı patika (Bezier curve)
            CustomPaint(
              size: Size(screenSize.width, screenSize.height),
              painter: PathPainter(pathPoints),
            ),
            // Checkpoint noktaları
            ..._buildCheckpoints(pathPoints),
            // Başlık
            Positioned(
              top: screenSize.height * 0.07 + 60,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Adventure Awaits!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
            // Alt başlık
            Positioned(
              top: screenSize.height * 0.18,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Preparing your learning quest...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            // Yükleniyor barı ve yazısı
            Positioned(
              left: screenSize.width * 0.15,
              right: screenSize.width * 0.15,
              bottom: screenSize.height * 0.10,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white12,
                    color: Colors.white,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Loading...",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon({
    required Animation<Offset> slideAnimation,
    required IconData icon,
    required double top,
    required double left,
    required Color color,
    required double size,
  }) {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Positioned(
          top: top,
          left: left,
          child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: _iconFadeAnimation,
              child: Icon(
                icon,
                size: size,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }

  // Bezier curve üzerinde t parametresiyle nokta hesaplama
  Offset _calculateBezierPoint(double t, List<Offset> points) {
    while (points.length > 1) {
      List<Offset> next = [];
      for (int i = 0; i < points.length - 1; i++) {
        next.add(Offset(
          points[i].dx + (points[i + 1].dx - points[i].dx) * t,
          points[i].dy + (points[i + 1].dy - points[i].dy) * t,
        ));
      }
      points = next;
    }
    return points.first;
  }

  // Checkpoint noktaları (farklı ikon ve renklerle)
  List<Widget> _buildCheckpoints(List<Offset> points) {
    final icons = [
      Icons.flag,
      Icons.school,
      Icons.emoji_events,
      Icons.psychology,
      Icons.star,
    ];
    final colors = [
      Colors.pinkAccent,
      Colors.lightBlueAccent,
      Colors.amber,
      Colors.greenAccent,
      Colors.deepPurpleAccent,
    ];
    return List.generate(points.length, (i) {
      return Positioned(
        left: points[i].dx - 16,
        top: points[i].dy - 16,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[i].withOpacity(0.92),
            boxShadow: [
              BoxShadow(
                color: colors[i].withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(icons[i], color: Colors.white, size: 20),
        ),
      );
    });
  }
}

// Kıvrımlı patika için CustomPainter
class PathPainter extends CustomPainter {
  final List<Offset> points;
  PathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFE082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.cubicTo(
          points[i - 1].dx + 40, points[i - 1].dy - 60,
          points[i].dx - 40, points[i].dy + 60,
          points[i].dx, points[i].dy,
        );
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 