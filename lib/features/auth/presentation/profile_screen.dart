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

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  int _selectedIndex = 3; // Profile tab
  static const double initialValue = 50000.0;
  UserModel? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    WidgetsBinding.instance.addObserver(this);
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
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double currentValue = _user?.virtualBalance ?? 0.0;
    final double change = currentValue - initialValue;
    final double percentChange = initialValue == 0 ? 0 : (change / initialValue) * 100;
    Color percentColor;
    if (percentChange > 0) {
      percentColor = const Color(0xFF27AE60); // Yeşil
    } else if (percentChange < 0) {
      percentColor = Colors.red;
    } else {
      percentColor = const Color(0xFFF2C94C); // Sarı
    }
    if (_isLoading || _user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.black,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'welcome',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Row(
                                children: [
                              Text(
                                _user!.fullName,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF181A20),
                                ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileDetailsPage(user: _user!)));
                                    },
                                    child: const Icon(Icons.info_outline, color: Color(0xFF2A3FFF), size: 24),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Initial Value',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      '\$',
                                      style: TextStyle(
                                        color: Color(0xFF2A3FFF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${initialValue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF2A3FFF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 60,
                            color: const Color(0xFF2A3FFF),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Current Value',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      '\$',
                                      style: TextStyle(
                                        color: Color(0xFF2A3FFF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${currentValue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF2A3FFF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: percentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Column(
                        children: [
                          const Center(
                            child: Text(
                              'My Badgets',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF2A3FFF), width: 3),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x332A3FFF),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(''), // Buraya rozetler eklenebilir
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _ProfileMenuItem(
                    title: 'Upgrade Premium',
                    onTap: () {}, // Pasif
                  ),
                  _ProfileMenuItem(
                    title: 'Invite Your Friends',
                    onTap: () {}, // Pasif
                  ),
                  _ProfileMenuItem(
                    title: 'Account Settings',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) {
                          final _fullNameController = TextEditingController(text: _user!.fullName);
                          final _passwordController = TextEditingController();
                          final _passwordRepeatController = TextEditingController();
                          bool _isLoading = false;
                          String? _error;
                          final blueColor = const Color(0xFF2A3FFF);

                          return StatefulBuilder(
                            builder: (context, setStateSheet) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 24,
                                  right: 24,
                                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                                  top: 24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        margin: const EdgeInsets.only(bottom: 24),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'Account Settings',
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Center(
                                      child: Text(
                                        'You can change your name and password.',
                                        style: TextStyle(fontSize: 13, color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _fullNameController,
                                      decoration: InputDecoration(
                                        labelText: 'Full Name',
                                        labelStyle: TextStyle(color: blueColor),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: blueColor, width: 2),
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: 'New Password',
                                        labelStyle: TextStyle(color: blueColor),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: blueColor, width: 2),
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                      obscureText: true,
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _passwordRepeatController,
                                      decoration: InputDecoration(
                                        labelText: 'Repeat New Password',
                                        labelStyle: TextStyle(color: blueColor),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: blueColor, width: 2),
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                      obscureText: true,
                                    ),
                                    if (_error != null) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        _error!,
                                        style: const TextStyle(color: Colors.red, fontSize: 14),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(color: blueColor),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : () async {
                                                  setStateSheet(() => _error = null);
                                                  if (_passwordController.text != _passwordRepeatController.text) {
                                                    setStateSheet(() => _error = 'Passwords do not match.');
                                                    return;
                                                  }
                                                  final confirmed = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text('Confirm Update'),
                                                      content: const Text('Your information will be updated. Do you confirm?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: Text(
                                                            'Cancel',
                                                            style: TextStyle(color: blueColor),
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () => Navigator.pop(context, true),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.black,
                                                            foregroundColor: Colors.white,
                                                          ),
                                                          child: const Text('Confirm'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirmed != true) return;
                                                  setStateSheet(() => _isLoading = true);
                                                  final authService = AuthService();
                                                  final success = await authService.updateCurrentUser(
                                                    fullName: _fullNameController.text.trim(),
                                                    password: _passwordController.text.trim().isEmpty
                                                        ? null
                                                        : _passwordController.text.trim(),
                                                  );
                                                  setStateSheet(() => _isLoading = false);
                                                  if (success) {
                                                    Navigator.pop(context);
                                                    setState(() {}); // Profil ekranını güncelle
                                                  } else {
                                                    setStateSheet(() => _error = 'Update failed!');
                                                  }
                                                },
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Text('Save'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  _ProfileMenuItem(
                    title: 'Logout',
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
          ],
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
            label: '', // Ortadaki büyük ikon
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

class _ProfileMenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _ProfileMenuItem({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 28),
      onTap: onTap,
    );
  }
}
