import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:tradepath/features/auth/presentation/login_screen.dart';
import 'package:tradepath/features/auth/presentation/register_screen.dart';
import 'package:tradepath/features/auth/presentation/homepage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  
  late final AnimationController _rotationController;
  late final List<AnimationController> _scaleControllers;
  final int _totalIcons = 8;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _scaleControllers = List.generate(
      _totalIcons,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500 + (index * 100)),
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  Future<void> _checkAuthentication() async {
    final token = await _storage.read(key: 'jwt');
    if (token != null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRotatingIcon(int index, double radius) {
    final double angle = (index / _totalIcons) * 2 * math.pi;
    final List<IconData> icons = [
      Icons.candlestick_chart,
      Icons.school,
      Icons.quiz,
      Icons.trending_up,
      Icons.psychology_rounded,  // Yuvarlatılmış beyin ikonu - AI için
      Icons.analytics,
      Icons.account_balance,
      Icons.currency_exchange,
    ];

    final List<String> labels = [
      'Trade Stocks',
      'Learn Trading',
      'Take Quizzes',
      'Track Markets',
      'AI Support',
      'Analysis',
      'Portfolio',
      'Exchange',
    ];

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..translate(
              radius * math.cos(angle + _rotationController.value * 2 * math.pi),
              radius * math.sin(angle + _rotationController.value * 2 * math.pi),
            ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(_scaleControllers[index]),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2A3FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A3FFF).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[index],
                    size: 36,
                    color: const Color(0xFF2A3FFF),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2A3FFF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final screenSize = MediaQuery.of(context).size;
    final radius = screenSize.width * 0.3;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Invest In\nStock',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A3FFF),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(
                    _totalIcons,
                    (index) => _buildRotatingIcon(index, radius),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A3FFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2A3FFF), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Sign up', style: TextStyle(fontSize: 18, color: Color(0xFF2A3FFF))),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 