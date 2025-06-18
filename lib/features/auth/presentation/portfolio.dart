import 'package:flutter/material.dart';
import '../domain/portfolio_item_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/auth_service.dart';
import 'trade_screen.dart';
import 'profile_screen.dart';
import 'homepage.dart';
import 'package:lottie/lottie.dart';
import 'edu_path_entry_screen.dart';

class NetWorthModel {
  final double virtualBalance;
  final double portfolioValue;
  final double netWorth;

  NetWorthModel({required this.virtualBalance, required this.portfolioValue, required this.netWorth});

  factory NetWorthModel.fromJson(Map<String, dynamic> json) {
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    return NetWorthModel(
      virtualBalance: safeDouble(json['virtualBalance']),
      portfolioValue: safeDouble(json['portfolioValue']),
      netWorth: safeDouble(json['netWorth']),
    );
  }
}

class PortfolioService {
  static const _baseUrl = 'http://10.0.2.2:8080';
  static const _portfolioEndpoint = '/api/portfolio/my-holdings';
  static const _netWorthEndpoint = '/api/portfolio/my-net-worth';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<PortfolioItemModel>> fetchPortfolio() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('$_baseUrl$_portfolioEndpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PortfolioItemModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load portfolio');
    }
  }

  Future<NetWorthModel> fetchNetWorth() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('$_baseUrl$_netWorthEndpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return NetWorthModel.fromJson(data);
    } else {
      throw Exception('Failed to load net worth');
    }
  }

  Future<double> fetchLastBuyPrice(String symbol) async {
    final token = await _storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('$_baseUrl/api/trades/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> trades = jsonDecode(response.body);
      // Sadece ilgili sembol ve alış işlemleri (quantity > 0)
      final buys = trades.where((t) => t['symbol'] == symbol && (t['quantity'] ?? 0) > 0).toList();
      if (buys.isNotEmpty) {
        // En son alış işlemi (tradeDate'e göre sıralı geliyorsa ilk, yoksa en yenisini bul)
        buys.sort((a, b) => DateTime.parse(b['tradeDate']).compareTo(DateTime.parse(a['tradeDate'])));
        return (buys.first['pricePerShare'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return 0.0;
  }
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late Future<List<PortfolioItemModel>> _portfolioFuture;
  late Future<NetWorthModel> _netWorthFuture;
  int _selectedIndex = 1;
  Map<String, double> _buyPrices = {};
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _portfolioFuture = PortfolioService().fetchPortfolio();
    _netWorthFuture = PortfolioService().fetchNetWorth();
  }

  Future<void> _fetchBuyPrices(List<PortfolioItemModel> items) async {
    final service = PortfolioService();
    for (final item in items) {
      if (!_buyPrices.containsKey(item.symbol)) {
        final price = await service.fetchLastBuyPrice(item.symbol);
        setState(() {
          _buyPrices[item.symbol] = price;
        });
      }
    }
  }

  double _getTotalValue(List<PortfolioItemModel> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalValue);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    if (index == 0) {
      // Navigate to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 2) {
      // Navigate to Trade Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TradeScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EduPathEntryScreen()),
      );
    } else if (index == 4) {
      // Navigate to Profile
      final authService = AuthService();
      authService.getCurrentUser().then((user) {
        if (user != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2A3FFF);
    final Color secondaryColor = const Color(0xFFF5F6FA);
    final Color textColor = const Color(0xFF181A20);
    final Color boxColor = const Color(0xFFE9EAF3);
    final Color cardGradientStart = const Color(0xFFEDF0FF);
    final Color cardGradientEnd = const Color(0xFFFFFFFF);
    final Color cardBg = const Color(0xFFF7F8FA); // Soft arka plan rengi
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Lottie.asset(
                'assets/animations/piechart.json',
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Portfolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        backgroundColor: secondaryColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: FutureBuilder<NetWorthModel>(
        future: _netWorthFuture,
        builder: (context, netWorthSnapshot) {
          return FutureBuilder<List<PortfolioItemModel>>(
            future: _portfolioFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || netWorthSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || netWorthSnapshot.hasError) {
                return Center(child: Text('Failed to load portfolio', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No stocks in your portfolio.', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600)));
              }
              final items = snapshot.data!;
              _fetchBuyPrices(items);
              final netWorth = netWorthSnapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Modern ve şık 3 değerli özet kutusu
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigo[800]!.withOpacity(0.38),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Portfolio', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    netWorth.portfolioValue.toStringAsFixed(2),
                                    style: TextStyle(fontSize: 20, color: Colors.indigo[700], fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Stock Value', style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green[800]!.withOpacity(0.38),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Cash', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    netWorth.virtualBalance.toStringAsFixed(2),
                                    style: TextStyle(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Available Balance', style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue[800]!.withOpacity(0.38),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Total', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    netWorth.netWorth.toStringAsFixed(2),
                                    style: TextStyle(fontSize: 20, color: Colors.blue[800], fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Total Assets', style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Tablo başlığı
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: boxColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 4, child: Text('Symbol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center)),
                          Expanded(flex: 3, child: Text('Avg. Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center)),
                          Expanded(flex: 3, child: Text('Current', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Liste
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final buyPrice = _buyPrices[item.symbol] ?? 0.0;
                          final double currentPrice = item.currentPrice;
                          final double changePercent = buyPrice > 0 ? ((currentPrice - buyPrice) / buyPrice) * 100 : 0.0;
                          Color percentColor;
                          if (changePercent > 0) {
                            percentColor = Colors.green;
                          } else if (changePercent < 0) {
                            percentColor = Colors.red;
                          } else {
                            percentColor = Colors.amber[700]!;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Symbol + şirket adı
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: primaryColor.withOpacity(0.16),
                                        child: Text(
                                          item.symbol.isNotEmpty ? item.symbol[0] : '?',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        radius: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.symbol,
                                              style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            Text(
                                              item.companyName,
                                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${item.quantity}',
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    buyPrice == 0.0 ? '-' : '\$${buyPrice.toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '\$${item.currentPrice.toStringAsFixed(2)}',
                                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: percentColor.withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                                      style: TextStyle(color: percentColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
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

  Widget _symmetricValueCard({required String label, required double value, required Color color, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

