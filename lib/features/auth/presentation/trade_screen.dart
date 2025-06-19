import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _stockFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();

  List<dynamic> _allStocks = [];
  List<dynamic> _filteredStocks = [];
  Map<String, dynamic>? _selectedStock;
  double? _stockPrice;
  double? _totalAmount;
  double? _virtualBalance;
  double? _aiPrediction;
  double? _aiPredictionConfidence;
  bool _isLoading = false;
  bool _notificationSwitch = false;
  bool _emailSwitch = false;
  bool _isAiLoading = false;

  static const String _baseUrl = 'http://10.0.2.2:8080';
  static const String _stocksEndpoint = '/api/stocks';
  static const String _userMeEndpoint = '/api/users/me';
  static const String _buyEndpoint = '/api/trade/buy';
  static const String _sellEndpoint = '/api/trade/sell';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchStocks();
    _fetchUserBalance();
    _quantityController.addListener(_updateTotalAmount);
  }

  Future<void> _fetchStocks() async {
    final token = await _storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('$_baseUrl$_stocksEndpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        _allStocks = jsonDecode(response.body);
        _filteredStocks = _allStocks;
      });
    }
  }

  Future<void> _fetchUserBalance() async {
    final token = await _storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('$_baseUrl$_userMeEndpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _virtualBalance = (data['virtualBalance'] as num?)?.toDouble() ?? 0.0;
      });
    }
  }

  void _updateTotalAmount() {
    if (_selectedStock != null && _quantityController.text.isNotEmpty) {
      final price = (_selectedStock!['price'] as num?)?.toDouble() ?? 0.0;
      final qty = int.tryParse(_quantityController.text) ?? 0;
      setState(() {
        _stockPrice = price;
        _totalAmount = price * qty;
      });
    } else {
      setState(() {
        _totalAmount = null;
      });
    }
  }

  void _onStockSearch(String query) {
    setState(() {
      _filteredStocks = _allStocks
          .where((stock) =>
              stock['symbol'].toString().toLowerCase().contains(query.toLowerCase()) ||
              (stock['companyName']?.toString().toLowerCase() ?? '').contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _fetchAiPrediction(String symbol) async {
    print('🔍 _fetchAiPrediction called for symbol: $symbol');
    setState(() {
      _isAiLoading = true;
      _aiPrediction = null;
      _aiPredictionConfidence = null;
    });
    final token = await _storage.read(key: 'jwt');
    final url = Uri.parse('$_baseUrl/api/predictions/symbol/$symbol');
    print('🌐 Making request to: $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Parsed data: $data');
        if (data is List && data.isNotEmpty) {
          final firstPrediction = data[0];
          print('🎯 First prediction: $firstPrediction');
          setState(() {
            _aiPrediction = (firstPrediction['predictedClosePrice'] as num?)?.toDouble();
            _aiPredictionConfidence = (firstPrediction['confidenceScore'] as num?)?.toDouble();
          });
          print('✅ AI Prediction set: $_aiPrediction, Confidence: $_aiPredictionConfidence');
        } else {
          print('❌ Data is empty or not a list');
          setState(() {
            _aiPrediction = null;
            _aiPredictionConfidence = null;
          });
        }
      } else {
        print('❌ Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception in _fetchAiPrediction: $e');
    }
    setState(() {
      _isAiLoading = false;
    });
  }

  void _onStockSelected(Map<String, dynamic> stock) {
    setState(() {
      _selectedStock = stock;
      _stockController.text = stock['symbol'];
      _stockPrice = (stock['price'] as num?)?.toDouble() ?? 0.0;
      _filteredStocks = [];
    });
    _updateTotalAmount();
    _fetchAiPrediction(stock['symbol']);
    FocusScope.of(context).requestFocus(_quantityFocus);
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleTrade({required bool isBuy}) async {
    if (_selectedStock == null || _quantityController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt');
    final endpoint = isBuy ? _buyEndpoint : _sellEndpoint;
    final body = jsonEncode({
      'symbol': _selectedStock!['symbol'],
      'quantity': int.tryParse(_quantityController.text) ?? 0,
    });
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    setState(() => _isLoading = false);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isBuy ? 'Alım başarılı!' : 'Satış başarılı!')),
      );
      _fetchUserBalance();
      final data = jsonDecode(response.body);
      if (data['newBadge'] != null) {
        final badge = data['newBadge'];
        IconData iconData;
        Color color;
        switch (badge['code']) {
          case 'FIRST_TRADE':
            iconData = Icons.emoji_events;
            color = Color(0xFF4CAF50);
            break;
          case 'NETWORTH_1K':
            iconData = Icons.attach_money;
            color = Color(0xFF2196F3);
            break;
          case 'PORTFOLIO_3_STOCKS':
            iconData = Icons.auto_graph;
            color = Color(0xFF2196F3);
            break;
          case 'EDUCATION_MASTER':
            iconData = Icons.school;
            color = Color(0xFF4CAF50);
            break;
          default:
            iconData = Icons.star_border_rounded;
            color = Color(0xFFB0BEC5);
        }
        showAchievementUnlocked(
          context,
          badge['title'] ?? 'Achievement',
          badge['description'] ?? '',
          iconData,
          color,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: ${response.body}')),
      );
    }
  }

  @override
  void dispose() {
    _stockController.dispose();
    _quantityController.dispose();
    _stockFocus.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2A3FFF);
    final Color secondaryColor = const Color(0xFFF5F6FA);
    final Color textColor = const Color(0xFF181A20);
    final Color boxColor = const Color(0xFFE9EAF3);
    final Color buttonBuy = const Color(0xFF27AE60);
    final Color buttonSell = Colors.red.shade400;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        backgroundColor: secondaryColor,
        appBar: AppBar(
          title: const Text('Stock Buy/Sell', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          backgroundColor: secondaryColor,
          foregroundColor: textColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2A3FFF), size: 28),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double minHeight = MediaQuery.of(context).size.height -
                    Scaffold.of(context).appBarMaxHeight!.toDouble() -
                    MediaQuery.of(context).padding.top - 48;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        minHeight: minHeight > 0 ? minHeight : 0,
                      ),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: boxColor, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.show_chart_rounded, color: primaryColor, size: 28),
                              const SizedBox(width: 8),
                              const Text('Stock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: primaryColor.withOpacity(0.18), width: 2),
                              color: Colors.white,
                            ),
                            child: TextField(
                              controller: _stockController,
                              focusNode: _stockFocus,
                              onChanged: _onStockSearch,
                              onSubmitted: (value) {
                                final found = _allStocks.firstWhere(
                                  (stock) => stock['symbol'].toString().toLowerCase() == value.toLowerCase(),
                                  orElse: () => null,
                                );
                                if (found != null) {
                                  _onStockSelected(found);
                                }
                              },
                              style: TextStyle(fontSize: 18, color: textColor),
                              decoration: InputDecoration(
                                hintText: 'Type stock name or symbol',
                                hintStyle: TextStyle(color: textColor.withOpacity(0.4), fontSize: 16),
                                prefixIcon: Icon(Icons.search, color: primaryColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: (_stockController.text.isNotEmpty && _filteredStocks.isNotEmpty)
                                ? Container(
                                    key: ValueKey(_filteredStocks.length),
                                    constraints: const BoxConstraints(maxHeight: 220),
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(color: primaryColor.withOpacity(0.13), width: 1.5),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: _filteredStocks.length,
                                      separatorBuilder: (_, __) => Divider(height: 1, color: boxColor),
                                      itemBuilder: (context, index) {
                                        final stock = _filteredStocks[index];
                                        final isSelected = _selectedStock != null && _selectedStock!['symbol'] == stock['symbol'];
                                        return Material(
                                          color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
                                          child: ListTile(
                                            leading: Icon(Icons.trending_up, color: isSelected ? primaryColor : textColor.withOpacity(0.5)),
                                            title: Text('${stock['symbol']} - ${stock['companyName'] ?? ''}', style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                            subtitle: Text('Price: ${stock['price']?.toStringAsFixed(2) ?? '-'} USD', style: TextStyle(color: textColor.withOpacity(0.7))),
                                            onTap: () => _onStockSelected(stock),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(Icons.price_change_rounded, color: primaryColor, size: 24),
                              const SizedBox(width: 8),
                              const Text('Price', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: boxColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: primaryColor.withOpacity(0.08)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _stockPrice != null ? '${_stockPrice!.toStringAsFixed(2)} USD' : 'Select',
                                        style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Current', style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: boxColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: primaryColor.withOpacity(0.08)),
                                  ),
                                  child: _isAiLoading
                                      ? Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)))
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _aiPrediction != null ? '${_aiPrediction!.toStringAsFixed(2)} USD' : '-',
                                              style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text('AI Prediction', style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6))),
                                                if (_aiPredictionConfidence != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 4),
                                                    child: Text('(${(_aiPredictionConfidence! * 100).toStringAsFixed(0)}%)', style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w500)),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.confirmation_number, color: primaryColor, size: 22),
                                        const SizedBox(width: 6),
                                        const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _quantityController,
                                      focusNode: _quantityFocus,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      style: TextStyle(fontSize: 18, color: textColor),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: primaryColor.withOpacity(0.18)),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: primaryColor, width: 2),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calculate, color: primaryColor, size: 22),
                                        const SizedBox(width: 6),
                                        const Text('Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                      decoration: BoxDecoration(
                                        color: boxColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: primaryColor.withOpacity(0.08)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _totalAmount != null ? '${_totalAmount!.toStringAsFixed(2)} USD' : '0 USD',
                                          style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, color: primaryColor, size: 22),
                              const SizedBox(width: 8),
                              const Text('Cash:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            decoration: BoxDecoration(
                              color: boxColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: primaryColor.withOpacity(0.08)),
                            ),
                            child: Text(
                              _virtualBalance != null ? '${_virtualBalance!.toStringAsFixed(2)} USD' : '-',
                              style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.13),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _handleTrade(isBuy: true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(54),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Buy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [buttonSell, buttonSell.withOpacity(0.7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: buttonSell.withOpacity(0.13),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _handleTrade(isBuy: false),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(54),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Sell', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

void showAchievementUnlocked(BuildContext context, String title, String description, IconData icon, Color color) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 60,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.95), color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(icon, color: color, size: 28),
                radius: 26,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Achievement Unlocked!', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(description, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(overlayEntry);
  Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
}
