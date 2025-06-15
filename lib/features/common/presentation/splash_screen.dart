import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tradepath/features/common/presentation/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _iconController;
  late Animation<double> _iconFadeAnimation;

  // Icon-specific animations
  late Animation<Offset> _iconSlideAnimationChart;
  late Animation<Offset> _iconSlideAnimationSchool;
  late Animation<Offset> _iconSlideAnimationTrendingUp;
  late Animation<Offset> _iconSlideAnimationInsights;
  late Animation<Offset> _iconSlideAnimationMoney;
  late Animation<Offset> _iconSlideAnimationStar;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _iconController = AnimationController(
      vsync: this,
      // Slightly longer duration for more perceived movement
      duration: const Duration(milliseconds: 1800), 
    );
    _iconFadeAnimation = CurvedAnimation(parent: _iconController, curve: Curves.easeIn);

    // Slide animation for chart icon (from top left)
    _iconSlideAnimationChart = Tween<Offset>(
      begin: const Offset(-1.5, -1.5), // Start further off-screen
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeInOutBack));

    // Slide animation for school icon (from top right)
    _iconSlideAnimationSchool = Tween<Offset>(
      begin: const Offset(1.5, -1.5), // Start further off-screen
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeInOutBack));
    
    // Slide animation for trending_up icon (from bottom left)
    _iconSlideAnimationTrendingUp = Tween<Offset>(
      begin: const Offset(-1.5, 1.5), // Start further off-screen bottom-left
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.elasticOut, // Different curve
    ));

    // Slide animation for insights icon (from bottom right)
    _iconSlideAnimationInsights = Tween<Offset>(
      begin: const Offset(1.5, 1.5), // Start further off-screen bottom-right
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.elasticOut, // Different curve
    ));

    // Slide animation for money icon (from left, slightly lower)
     _iconSlideAnimationMoney = Tween<Offset>(
      begin: const Offset(-2.0, 0.5), 
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeInOutSine));

    // Slide animation for star icon (from right, slightly lower)
    _iconSlideAnimationStar = Tween<Offset>(
      begin: const Offset(2.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeInOutSine));


    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () { // Slightly earlier start for icons
      if (mounted) {
        _iconController.forward();
      }
    });

    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 4)); 
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  Widget _buildAnimatedIcon({
    required Animation<Offset> slideAnimation,
    required IconData icon,
    required double top,
    required double left,
    double? right, // Optional right for easier positioning from right
    double? bottom, // Optional bottom
    required Color color,
    required double size,
  }) {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Positioned(
          top: top,
          left: left,
          right: right,
          bottom: bottom,
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        color: const Color(0xFF2A3FFF), // Updated background color to profile blue
        child: Stack( 
          children: [
            // Animated Icons
            _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationChart,
              icon: Icons.show_chart_rounded,
              top: screenSize.height * 0.12,
              left: screenSize.width * 0.08,
              color: Colors.white70,
              size: 40,
            ),
            _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationSchool,
              icon: Icons.school_rounded,
              top: screenSize.height * 0.15,
              left: screenSize.width * 0.82, // Positioned from left
              color: Colors.white70,
              size: 38,
            ),
             _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationTrendingUp,
              icon: Icons.trending_up_rounded,
              top: screenSize.height * 0.75, // Lower part of the screen
              left: screenSize.width * 0.1,
              color: Colors.white54,
              size: 42,
            ),
            _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationInsights,
              icon: Icons.insights_rounded,
              top: screenSize.height * 0.72, // Lower part of the screen
              left: screenSize.width * 0.8, // Positioned from left
              color: Colors.white54,
              size: 38,
            ),
             _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationMoney,
              icon: Icons.attach_money_rounded,
              top: screenSize.height * 0.45, 
              left: screenSize.width * 0.05,
              color: Colors.white60,
              size: 36,
            ),
            _buildAnimatedIcon(
              slideAnimation: _iconSlideAnimationStar,
              icon: Icons.star_outline_rounded,
              top: screenSize.height * 0.50,
              left: screenSize.width * 0.85, // Positioned from left
              color: Colors.white60,
              size: 36,
            ),

            // Main content fading in
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/profile_icons/logo.png', // Updated image path
                      width: 200, // Increased width
                      height: 200, // Increased height
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if the new logo also fails to load
                        return const Text( 
                          'Logo Yüklenemedi', 
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        );
                      },
                    ),
                    const SizedBox(height: 20), 
                    const Text(
                      'TradePath',
                      style: TextStyle(
                        fontSize: 42, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white, 
                        letterSpacing: 1.5, 
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your Path to Trading Success',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18, 
                        color: Colors.white.withOpacity(0.9),
                        fontStyle: FontStyle.italic, 
                      ),
                    ),
                    const SizedBox(height: 50), 
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3, 
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 