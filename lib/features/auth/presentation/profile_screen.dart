import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/auth_service.dart';
import '../domain/user_model.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tradepath/features/auth/presentation/profile_details_page.dart';
import 'trade_screen.dart';
import 'portfolio.dart';
import 'homepage.dart';
import '../domain/badge_model.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'account_settings_page.dart';
import 'package:lottie/lottie.dart';
import 'edu_path_entry_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

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

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  int _selectedIndex = 3; // Profile tab
  static const double initialValue = 50000.0;
  UserModel? _user;
  bool _isLoading = false;
  List<BadgeModel> _badges = [];
  bool _badgesLoading = false;
  NetWorthModel? _netWorth;

  String _getTranslatedBadgeTitle(String code) {
    switch (code) {
      case 'FIRST_TRADE':
        return "First Trade";
      case 'NETWORTH_1K':
        return "Net Worth Milestone";
      case 'PORTFOLIO_3_STOCKS':
        return "Portfolio Builder";
      case 'EDUCATION_MASTER':
        return "Education Master";
      default:
        return code;
    }
  }

  String _getTranslatedBadgeDescription(String code) {
    switch (code) {
      case 'FIRST_TRADE':
        return "Completed your first trade successfully";
      case 'NETWORTH_1K':
        return "Reached a net worth of \$1,000";
      case 'PORTFOLIO_3_STOCKS':
        return "Added 3 different stocks to your portfolio";
      case 'EDUCATION_MASTER':
        return "Completed all educational modules";
      default:
        return "";
    }
  }

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    WidgetsBinding.instance.addObserver(this);
    _fetchBadges();
    _fetchNetWorth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUser();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa tekrar görünür olduğunda (örn. geri gelince) kullanıcıyı güncelle
    _refreshUser();
  }

  Future<void> _refreshUser() async {
    setState(() => _isLoading = true);
    final authService = AuthService();
    final updatedUser = await authService.getCurrentUser();
    if (updatedUser != null) {
      setState(() {
        _user = updatedUser;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchBadges() async {
    setState(() => _badgesLoading = true);
    final authService = AuthService();
    final badges = await authService.getUserBadgesDetailed();
    setState(() {
      _badges = badges;
      _badgesLoading = false;
    });
  }

  Future<void> _fetchNetWorth() async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'jwt');
    if (token == null) return;
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/portfolio/net-worth'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _netWorth = NetWorthModel.fromJson(data);
      });
    }
  }

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;
    
    if (index == 0) {
      // Home sayfasına yönlendirme
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      return;
    }
    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PortfolioScreen()),
      );
      return;
    }
    if (index == 2) {
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TradeScreen()),
      );
      if (updated == true) {
        await _refreshUser();
      }
      return;
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EduPathEntryScreen()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBadgesSection() {
    if (_badgesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_badges.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0e7ff), Color(0xFFf5f7fa)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Color(0xFF2A3FFF), width: 2),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0x332A3FFF),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.workspace_premium, color: Color(0xFF2A3FFF), size: 48),
            SizedBox(height: 12),
            Text('No achievements yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }
    return AnimationLimiter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0e7ff), Color(0xFFf5f7fa)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Color(0xFF2A3FFF), width: 2),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0x332A3FFF),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: _badges.length,
          itemBuilder: (context, index) {
            final badge = _badges[index];
            IconData iconData;
            Color bgColor;
            Gradient iconGradient;
            switch (badge.code) {
              case 'FIRST_TRADE':
                iconData = Icons.emoji_events;
                bgColor = Color(0xFF4CAF50).withOpacity(0.12);
                iconGradient = LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF81C784)]);
                break;
              case 'NETWORTH_1K':
                iconData = Icons.attach_money;
                bgColor = Color(0xFF2196F3).withOpacity(0.12);
                iconGradient = LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF64B5F6)]);
                break;
              case 'PORTFOLIO_3_STOCKS':
                iconData = Icons.auto_graph;
                bgColor = Color(0xFF2196F3).withOpacity(0.12);
                iconGradient = LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF64B5F6)]);
                break;
              case 'EDUCATION_MASTER':
                iconData = Icons.school;
                bgColor = Color(0xFF4CAF50).withOpacity(0.12);
                iconGradient = LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF81C784)]);
                break;
              default:
                iconData = Icons.star_border_rounded;
                bgColor = Color(0xFFB0BEC5).withOpacity(0.12);
                iconGradient = LinearGradient(colors: [Color(0xFFB0BEC5), Color(0xFFECEFF1)]);
            }
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: 3,
              child: ScaleAnimation(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        IconData iconData;
                        Color iconColor;
                        switch (badge.code) {
                          case 'FIRST_TRADE':
                            iconData = Icons.emoji_events;
                            iconColor = Color(0xFF4CAF50);
                            break;
                          case 'NETWORTH_1K':
                            iconData = Icons.attach_money;
                            iconColor = Color(0xFF2196F3);
                            break;
                          case 'PORTFOLIO_3_STOCKS':
                            iconData = Icons.auto_graph;
                            iconColor = Color(0xFF2196F3);
                            break;
                          case 'EDUCATION_MASTER':
                            iconData = Icons.school;
                            iconColor = Color(0xFF4CAF50);
                            break;
                          default:
                            iconData = Icons.star_border_rounded;
                            iconColor = Color(0xFFB0BEC5);
                        }
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFe0e7ff), Color(0xFFf5f7fa)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 32,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      margin: const EdgeInsets.only(bottom: 18),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [iconColor.withOpacity(0.85), iconColor.withOpacity(0.55)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: iconColor.withOpacity(0.18),
                                            blurRadius: 16,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(iconData, color: Colors.white, size: 36),
                                      ),
                                    ),
                                    Text(
                                      _getTranslatedBadgeTitle(badge.code),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: iconColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _getTranslatedBadgeDescription(badge.code),
                                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(Icons.close, size: 22, color: Colors.black54),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: bgColor.withOpacity(0.18),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: iconGradient,
                          ),
                          child: Center(
                            child: Icon(iconData, color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 90,
                          child: Text(
                            _getTranslatedBadgeTitle(badge.code),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF181A20),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFe0e7ff), Color(0xFFf5f7fa)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 32, backgroundColor: Colors.black),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Row(
                  children: [
                    Text(_user!.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Color(0xFF2A3FFF)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileDetailsPage(user: _user!))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final double currentValue = _netWorth?.netWorth ?? 0.0;
    final double change = currentValue - initialValue;
    final double percentChange = initialValue == 0 ? 0 : (change / initialValue) * 100;
    final bool isPositive = percentChange > 0;
    final bool isNegative = percentChange < 0;

    Color percentColor;
    IconData percentIcon;
    if (isPositive) {
      percentColor = const Color(0xFF27AE60);
      percentIcon = Icons.arrow_upward_rounded;
    } else if (isNegative) {
      percentColor = Colors.red;
      percentIcon = Icons.arrow_downward_rounded;
    } else {
      percentColor = const Color(0xFFF2C94C);
      percentIcon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Color(0xFF2A3FFF),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Net Worth',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF181A20),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2A3FFF), size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$ ${currentValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A3FFF),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(percentIcon, color: percentColor, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: percentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Initial: \$ ${initialValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB0BEC5),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Lottie.asset('assets/animations/networth.json', repeat: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12, top: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuRow(
              title: 'Upgrade Premium',
              icon: Icons.star,
              iconBg: Color(0xFF2A3FFF),
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _MenuRow(
              title: 'Invite Your Friends',
              icon: Icons.group_add,
              iconBg: Color(0xFF4CAF50),
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _MenuRow(
              title: 'Account Settings',
              icon: Icons.settings,
              iconBg: Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountSettingsPage(user: _user!),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _MenuRow(
              title: 'Log Out',
              icon: Icons.logout,
              iconBg: Color(0xFFE53935),
              onTap: () async {
                const storage = FlutterSecureStorage();
                await storage.delete(key: 'jwt');
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      showUnselectedLabels: true,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Portfolio'),
        BottomNavigationBarItem(icon: Icon(Icons.compare_arrows), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'EduPath'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            _buildUserInfo(),
                            const SizedBox(height: 24),
                            _buildBalanceCard(),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.workspace_premium, color: Color(0xFF2A3FFF), size: 26),
                                const SizedBox(width: 8),
                                const Text('My Badges', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildBadgesSection(),
                            const SizedBox(height: 12),
                            _buildMenu(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconBg;
  final VoidCallback onTap;
  const _MenuRow({required this.title, required this.icon, required this.iconBg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: iconBg, size: 22),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}
