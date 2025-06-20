import 'package:flutter/material.dart';
import '../domain/watchlist_item_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'stock_search_screen.dart';
import 'homepage.dart';
import 'portfolio.dart';
import 'trade_screen.dart';
import 'profile_screen.dart';
import '../data/auth_service.dart';
import 'homepage.dart'; // HomeService ve MiniChartPainter için
import 'edu_path_entry_screen.dart';
import 'package:lottie/lottie.dart';
import '../../../core/network/http_interceptor.dart';

class WatchlistService {
  static const _baseUrl = 'http://10.0.2.2:8080';
  static const _watchlistEndpoint = '/api/watchlist';
  static const _recommendationEndpoint = '/api/v1/recommendations/symbol';

  Future<List<WatchlistItemModel>> fetchWatchlist() async {
    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl$_watchlistEndpoint'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WatchlistItemModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load watchlist');
    }
  }

  Future<void> addToWatchlist(String symbol) async {
    final response = await HttpInterceptor.post(
      Uri.parse('$_baseUrl$_watchlistEndpoint/add'),
      body: jsonEncode({'symbol': symbol}),
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add to watchlist');
    }
  }

  Future<void> removeFromWatchlist(String symbol) async {
    final response = await HttpInterceptor.delete(
      Uri.parse('$_baseUrl$_watchlistEndpoint/remove/$symbol'),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to remove from watchlist');
    }
  }

  Future<Map<String, dynamic>?> fetchRecommendation(String symbol) async {
    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl$_recommendationEndpoint/$symbol'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      return null;
    }
  }
}

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({Key? key}) : super(key: key);

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late Future<List<WatchlistItemModel>> _watchlistFuture;
  int _selectedIndex = 0;
  final WatchlistService _watchlistService = WatchlistService();

  @override
  void initState() {
    super.initState();
    _refreshWatchlist();
  }

  void _refreshWatchlist() {
    setState(() {
      _watchlistFuture = HomeService().fetchWatchlistWithSparklines();
    });
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1: // Portfolio
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PortfolioScreen()),
        );
        break;
      case 2: // Trade (middle button with arrows)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TradeScreen()),
        );
        break;
      case 3: // EduPath
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EduPathEntryScreen()),
        );
        break;
      case 4: // Profile
        _navigateToProfile();
        break;
    }
  }

  void _navigateToProfile() async {
    final authService = AuthService();
    final user = await authService.getCurrentUser();
    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
      );
    }
  }

  void _navigateToStockSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StockSearchScreen()),
    ).then((_) => _refreshWatchlist());
  }

  void _showRecommendationDialog(String symbol) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF2A3FFF)));
      },
    );
    
    try {
      final recommendation = await _watchlistService.fetchRecommendation(symbol);
      Navigator.of(context).pop(); // Close loading dialog
      
      if (recommendation != null) {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: '',
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDF0FF), Color(0xFFFFFFFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF2A3FFF).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A3FFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: Lottie.asset(
                                  'assets/animations/ai.json',
                                  repeat: true,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$symbol Recommendation',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF181A20),
                                    ),
                                  ),
                                  Text(
                                    'AI Analysis',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFF181A20).withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Recommendation Content
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: const Color(0xFF2A3FFF),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Recommendation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF181A20),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                recommendation['recommendation']?.toString() ?? 'No recommendation available',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF181A20),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (recommendation['reason'] != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: const Color(0xFF2A3FFF),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Analysis Reason',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF181A20),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  recommendation['reason'].toString(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: const Color(0xFF181A20).withOpacity(0.8),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (recommendation['targetPrice'] != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF27AE60).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Target Price',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '\$${recommendation['targetPrice']}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        );
      } else {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: '',
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDF0FF), Color(0xFFFFFFFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF2A3FFF).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A3FFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: Lottie.asset(
                                  'assets/animations/ai.json',
                                  repeat: true,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$symbol Recommendation',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF181A20),
                                    ),
                                  ),
                                  Text(
                                    'AI Analysis',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFF181A20).withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // No Recommendation Content
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                color: const Color(0xFF181A20).withOpacity(0.4),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Recommendation Available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF181A20).withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Our AI hasn\'t generated a recommendation for $symbol yet. Please check back later.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(0xFF181A20).withOpacity(0.6),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recommendation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2A3FFF);
    final Color secondaryColor = const Color(0xFFF5F6FA);
    final Color textColor = const Color(0xFF181A20);
    final Color cardGradientStart = const Color(0xFFEDF0FF);
    final Color cardGradientEnd = const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.star_border_rounded, color: primaryColor, size: 28),
            const SizedBox(width: 10),
            const Text('Watchlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        backgroundColor: secondaryColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToStockSearch,
          ),
        ],
      ),
      body: FutureBuilder<List<WatchlistItemModel>>(
        future: _watchlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load watchlist', 
                style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)
              )
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border_rounded, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No stocks in your watchlist yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _navigateToStockSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Stocks', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final isPositive = item.priceChange >= 0;
                
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardGradientStart, cardGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Dismissible(
                    key: Key(item.symbol),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _watchlistService.removeFromWatchlist(item.symbol).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.symbol} removed from watchlist')),
                        );
                        _refreshWatchlist();
                      });
                    },
                    child: GestureDetector(
                      onLongPress: () => _showRecommendationDialog(item.symbol),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Logo/Avatar
                            CircleAvatar(
                              backgroundColor: primaryColor.withOpacity(0.15),
                              child: Text(
                                item.symbol.isNotEmpty ? item.symbol[0] : '?',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              radius: 24,
                            ),
                            const SizedBox(width: 16),
                            // Symbol ve şirket adı
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.symbol,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    item.companyName,
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Fiyat grafiği (gerçek sparkline olarak)
                            Container(
                              width: 80,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: CustomPaint(
                                painter: MiniChartPainter(
                                  data: item.sparkline,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Fiyat ve değişim
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${item.currentPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  '${isPositive ? '+' : ''}${item.priceChangePercentage.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: isPositive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'EduPath',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class SimpleChartPainter extends CustomPainter {
  final Color color;
  final bool isUp;

  SimpleChartPainter({required this.color, required this.isUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    if (isUp) {
      path.moveTo(0, size.height * 0.8);
      path.quadraticBezierTo(
        size.width * 0.2, size.height * 0.5,
        size.width * 0.4, size.height * 0.7
      );
      path.quadraticBezierTo(
        size.width * 0.6, size.height * 0.9,
        size.width * 0.8, size.height * 0.2
      );
      path.lineTo(size.width, size.height * 0.4);
    } else {
      path.moveTo(0, size.height * 0.2);
      path.quadraticBezierTo(
        size.width * 0.2, size.height * 0.4,
        size.width * 0.4, size.height * 0.3
      );
      path.quadraticBezierTo(
        size.width * 0.6, size.height * 0.2,
        size.width * 0.8, size.height * 0.8
      );
      path.lineTo(size.width, size.height * 0.6);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 