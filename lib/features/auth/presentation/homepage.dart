import 'package:flutter/material.dart';
import '../domain/portfolio_item_model.dart';
import '../domain/watchlist_item_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'watchlist_screen.dart';
import 'portfolio.dart';
import 'dart:math' as math;
import 'stock_search_screen.dart';
import 'trade_screen.dart';
import 'profile_screen.dart';
import '../data/auth_service.dart';
import 'edu_path_entry_screen.dart';

class StockGainsModel {
  final double value;
  final List<double> chartData;
  final List<dynamic> rawSnapshots;

  StockGainsModel({required this.value, required this.chartData, required this.rawSnapshots});

  factory StockGainsModel.fromSnapshotJson(List<dynamic> jsonList) {
    if (jsonList.isEmpty) {
      return StockGainsModel(value: 0.0, chartData: [], rawSnapshots: []);
    }
    final chartData = <double>[];
    final rawSnapshots = <dynamic>[];
    for (final item in jsonList) {
      if (item is Map<String, dynamic> && item.containsKey('totalValue')) {
        chartData.add((item['totalValue'] as num?)?.toDouble() ?? 0.0);
        rawSnapshots.add(item);
      } else if (item is Map && item.containsKey('totalValue')) {
        chartData.add((item['totalValue'] as num?)?.toDouble() ?? 0.0);
        rawSnapshots.add(item);
      } else if (item is Map && item.containsKey('value')) {
        chartData.add((item['value'] as num?)?.toDouble() ?? 0.0);
        rawSnapshots.add(item);
      }
    }
    final value = chartData.isNotEmpty ? chartData.last : 0.0;
    return StockGainsModel(value: value, chartData: chartData, rawSnapshots: rawSnapshots);
  }
}

class HomeService {
  static const _baseUrl = 'http://10.0.2.2:8080';
  static const _watchlistEndpoint = '/api/watchlist';
  static const _portfolioSnapshotsEndpoint = '/api/portfolio/snapshots';
  static const _userInfoEndpoint = '/api/user/info';
  static const _portfolioEndpoint = '/api/portfolio/my-holdings';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<WatchlistItemModel>> fetchWatchlist() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('$_baseUrl$_watchlistEndpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WatchlistItemModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load watchlist');
    }
  }

  Future<StockGainsModel> fetchStockGains() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_portfolioSnapshotsEndpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return StockGainsModel.fromSnapshotJson(data);
        }
      }
      // API'den beklenmeyen cevap gelirse boş veri döndür
      return StockGainsModel(value: 0.0, chartData: [], rawSnapshots: []);
    } catch (e) {
      return StockGainsModel(value: 0.0, chartData: [], rawSnapshots: []);
    }
  }

  Future<String> fetchUserName() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['fullName'] ?? 'John Doe';
      } else {
        return 'John Doe';
      }
    } catch (e) {
      return 'John Doe';
    }
  }

  Future<List<PortfolioItemModel>> fetchPortfolio() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    try {
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
        // API henüz hazır değilse örnek veri döndür
        return [
          PortfolioItemModel(
            symbol: 'AAPL',
            companyName: 'Apple Inc.',
            quantity: 10,
            currentPrice: 198.24,
            totalValue: 1982.40,
            purchasePrice: 180.50,
          ),
          PortfolioItemModel(
            symbol: 'MSFT',
            companyName: 'Microsoft Corp.',
            quantity: 5,
            currentPrice: 337.22,
            totalValue: 1686.10,
            purchasePrice: 320.75,
          ),
        ];
      }
    } catch (e) {
      // API henüz hazır değilse örnek veri döndür
      return [
        PortfolioItemModel(
          symbol: 'AAPL',
          companyName: 'Apple Inc.',
          quantity: 10,
          currentPrice: 198.24,
          totalValue: 1982.40,
          purchasePrice: 180.50,
        ),
        PortfolioItemModel(
          symbol: 'MSFT',
          companyName: 'Microsoft Corp.',
          quantity: 5,
          currentPrice: 337.22,
          totalValue: 1686.10,
          purchasePrice: 320.75,
        ),
      ];
    }
  }

  Future<List<double>> fetchSparkline(String symbol) async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('$_baseUrl/api/intraday/$symbol'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    try {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.take(20).map((e) => (e['close'] as num).toDouble()).toList().reversed.toList();
      } else {
        // Eğer string mesaj dönerse (ör: 'No intraday data found...')
        return [];
      }
    } catch (e) {
      // JSON parse hatası veya başka bir hata olursa boş dön
      return [];
    }
  }

  Future<List<WatchlistItemModel>> fetchWatchlistWithSparklines() async {
    final watchlist = await fetchWatchlist();
    for (final item in watchlist) {
      final sparkline = await fetchSparkline(item.symbol);
      item.sparkline.clear();
      item.sparkline.addAll(sparkline);
      if (sparkline.length >= 2) {
        final currentPrice = sparkline[0];
        final previousPrice = sparkline[1];
        item.currentPrice = currentPrice;
        item.priceChange = currentPrice - previousPrice;
        item.priceChangePercentage = previousPrice != 0 ? ((currentPrice - previousPrice) / previousPrice) * 100 : 0.0;
      } else if (sparkline.isNotEmpty) {
        item.currentPrice = sparkline[0];
        item.priceChange = 0.0;
        item.priceChangePercentage = 0.0;
      } else {
        item.currentPrice = 0.0;
        item.priceChange = 0.0;
        item.priceChangePercentage = 0.0;
      }
    }
    return watchlist;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<WatchlistItemModel>> _watchlistFuture;
  late Future<StockGainsModel> _stockGainsFuture;
  late Future<String> _userNameFuture;
  late Future<List<PortfolioItemModel>> _portfolioFuture;
  int _selectedIndex = 0;
  String _selectedTimeframe = 'This week';
  static const List<String> _timeframes = ['This week', 'This month', 'All'];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _watchlistFuture = HomeService().fetchWatchlistWithSparklines();
      _stockGainsFuture = HomeService().fetchStockGains();
      _userNameFuture = HomeService().fetchUserName();
      _portfolioFuture = HomeService().fetchPortfolio();
    });
  }

  List<double> _filterChartData(List<double> chartData, List<dynamic> rawSnapshots) {
    if (_selectedTimeframe == 'All' || chartData.isEmpty) return chartData;
    final now = DateTime.now();
    List<DateTime> dates = [];
    for (final item in rawSnapshots) {
      if (item is Map && item['snapshotDate'] != null) {
        try {
          dates.add(DateTime.parse(item['snapshotDate'].toString()));
        } catch (_) {
          dates.add(now);
        }
      } else {
        dates.add(now);
      }
    }
    if (_selectedTimeframe == 'This week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return [for (int i = 0; i < chartData.length; i++) if (dates[i].isAfter(weekAgo)) chartData[i]];
    } else if (_selectedTimeframe == 'This month') {
      final monthAgo = DateTime(now.year, now.month - 1, now.day);
      return [for (int i = 0; i < chartData.length; i++) if (dates[i].isAfter(monthAgo)) chartData[i]];
    }
    return chartData;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });
    
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PortfolioScreen()),
      );
    } else if (index == 2) {
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
      // Profil sayfasına yönlendirme
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
    final Color cardGradientStart = const Color(0xFFEDF0FF);
    final Color cardGradientEnd = const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: secondaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı karşılama
                FutureBuilder<String>(
                  future: _userNameFuture,
                  builder: (context, snapshot) {
                    final userName = snapshot.data ?? 'John Doe';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi $userName',
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Welcome to TradePath',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, size: 28),
                              onPressed: () {},
                            ),
                            Positioned(
                              right: 12,
                              top: 8,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                ),
                
                const SizedBox(height: 24),
                
                // Stock Gains Card
                FutureBuilder<StockGainsModel>(
                  future: _stockGainsFuture,
                  builder: (context, snapshot) {
                    final stockGains = snapshot.data;
                    final rawSnapshots = snapshot.hasData && snapshot.data != null && snapshot.data!.chartData.isNotEmpty && snapshot.data is dynamic && snapshot.data is StockGainsModel && snapshot.data is! List<double> && snapshot.data is! List<int>
                        ? (snapshot.data as dynamic).rawSnapshots ?? []
                        : [];
                    final filteredChartData = (snapshot.hasData && rawSnapshots.isNotEmpty)
                        ? _filterChartData(stockGains!.chartData, rawSnapshots)
                        : stockGains?.chartData ?? [];
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stock Gains',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${stockGains?.value.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Color(0xFF2A3FFF), width: 1.2),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                constraints: const BoxConstraints(minHeight: 28),
                                child: DropdownButton<String>(
                                  value: _selectedTimeframe,
                                  items: _timeframes.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedTimeframe = newValue;
                                      });
                                    }
                                  },
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14),
                                  dropdownColor: Color(0xFF2A3FFF),
                                  borderRadius: BorderRadius.circular(20),
                                  selectedItemBuilder: (BuildContext context) {
                                    return _timeframes.map((String value) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          value,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 150,
                            child: stockGains != null
                                ? CustomPaint(
                                    size: const Size(double.infinity, 150),
                                    painter: ChartPainter(
                                      data: filteredChartData,
                                      lineColor: primaryColor,
                                      fillColor: primaryColor.withOpacity(0.2),
                                    ),
                                  )
                                : const Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Portfolio Section
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.dashboard, color: primaryColor, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Portfolio',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PortfolioScreen()),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'View all',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Portfolio items...
                      FutureBuilder<List<PortfolioItemModel>>(
                        future: _portfolioFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 150,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else if (snapshot.hasError) {
                            return const SizedBox(
                              height: 100,
                              child: Center(
                                child: Text(
                                  'Failed to load portfolio',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox(
                              height: 100,
                              child: Center(
                                child: Text(
                                  'No stocks in your portfolio',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            );
                          }

                          final items = snapshot.data!;
                          
                          return SizedBox(
                            height: 180, // Kartların yüksekliği için sabit bir değer
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final double currentPrice = item.currentPrice;
                                final double purchasePrice = item.purchasePrice;
                                final bool isPositive = currentPrice > purchasePrice;
                                final double changePercentage = purchasePrice > 0
                                    ? ((currentPrice - purchasePrice) / purchasePrice) * 100
                                    : 0.0;
                                return Container(
                                  width: MediaQuery.of(context).size.width * 0.43, // Ekranın yaklaşık yarısı kadar genişlik
                                  margin: EdgeInsets.only(
                                    right: index < items.length - 1 ? 12.0 : 0.0,
                                  ),
                                  child: _buildStockCard(
                                    symbol: item.symbol,
                                    name: item.companyName,
                                    price: currentPrice,
                                    change: changePercentage,
                                    isPositive: isPositive,
                                    logo: 'assets/${item.symbol.toLowerCase()}_logo.png',
                                    color: _getColorForSymbol(item.symbol),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Watchlist Section
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star_border_rounded, color: primaryColor, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Watchlist',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const WatchlistScreen()),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'View all',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Watchlist items...
                      FutureBuilder<List<WatchlistItemModel>>(
                        future: _watchlistFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Failed to load watchlist',
                                style: TextStyle(color: Colors.red[400]),
                              ),
                            );
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Icon(Icons.star_border_rounded, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No stocks in your watchlist yet',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const StockSearchScreen()),
                                      ).then((_) {
                                        _refreshData();
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Add Stocks'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final items = snapshot.data!;
                          // Sadece ilk 2 öğeyi göster
                          final displayItems = items.take(2).toList();
                          
                          return Column(
                            children: displayItems.map((item) => _buildWatchlistItem(
                              symbol: item.symbol,
                              name: item.companyName,
                              price: item.currentPrice,
                              change: item.priceChangePercentage,
                              isPositive: item.priceChange > 0,
                              logo: 'assets/${item.symbol.toLowerCase()}_logo.png',
                              color: _getColorForSymbol(item.symbol),
                              sparkline: item.sparkline,
                            )).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildStockCard({
    required String symbol,
    required String name,
    required double price,
    required double change,
    required bool isPositive,
    required String logo,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFFF0F8F0) : const Color(0xFFF8F0F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.1),
                child: Text(
                  symbol[0],
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistItem({
    required String symbol,
    required String name,
    required double price,
    required double change,
    required bool isPositive,
    required String logo,
    required Color color,
    required List<double> sparkline,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Text(
              symbol[0],
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: CustomPaint(
              painter: MiniChartPainter(
                data: sparkline,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForSymbol(String symbol) {
    // Sembol bazında renk ata
    switch (symbol.toUpperCase()) {
      case 'AAPL':
        return Colors.black;
      case 'MSFT':
        return Colors.blue;
      case 'GOOGL':
        return Colors.red;
      case 'AMZN':
        return Colors.orange;
      case 'META':
        return Colors.blue;
      case 'TSLA':
        return Colors.red;
      case 'NVDA':
        return Colors.green;
      case 'NFLX':
        return Colors.red;
      case 'LYFT':
        return Colors.pink;
      default:
        return Colors.purple;
    }
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  ChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    if (data.isEmpty) return;

    final double xStep = size.width / (data.length - 1);
    final double maxValue = data.reduce((curr, next) => curr > next ? curr : next);
    final double minValue = data.reduce((curr, next) => curr < next ? curr : next);
    final double range = maxValue - minValue;

    final path = Path();
    final fillPath = Path();

    // Başlangıç noktası
    path.moveTo(0, size.height - ((data[0] - minValue) / range) * size.height);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height - ((data[0] - minValue) / range) * size.height);

    // Diğer noktalar
    for (int i = 1; i < data.length; i++) {
      final double x = i * xStep;
      final double y = size.height - ((data[i] - minValue) / range) * size.height;
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    // Dolgu için son noktalar
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Çizim
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Noktalar için
    final dotPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotFillPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    // Vurgu noktası (son noktadan bir önceki)
    final highlightIndex = data.length - 5;
    if (highlightIndex >= 0) {
      final x = highlightIndex * xStep;
      final y = size.height - ((data[highlightIndex] - minValue) / range) * size.height;
      
      canvas.drawCircle(Offset(x, y), 6, dotFillPaint);
      canvas.drawCircle(Offset(x, y), 6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  MiniChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double xStep = size.width / (data.length - 1);
    final double maxValue = data.reduce((a, b) => a > b ? a : b);
    final double minValue = data.reduce((a, b) => a < b ? a : b);
    final double range = maxValue - minValue == 0 ? 1 : maxValue - minValue;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
