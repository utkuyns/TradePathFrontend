import 'dart:ui';
import 'package:flutter/material.dart';
import '../domain/user_model.dart';
import '../presentation/profile_screen.dart';
import '../data/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String mapRoleType(String? role) {
  switch (role) {
    case 'ADMIN':
      return 'Admin';
    case 'USER':
      return 'User (Free Plan)';
    case 'PREMIUMUSER':
      return 'Premium User';
    default:
      return '-';
  }
}

String getTranslatedBadgeTitle(String code) {
  switch (code) {
    case 'FIRST_TRADE':
      return "First Trade";
    case 'NETWORTH_1K':
      return "Net Worth Milestone";
    case 'PORTFOLIO_3_STOCKS':
      return "Portfolio Builder";
    case 'EDUCATION_MASTER':
      return "Education Master";
    case 'FIRST_PATH_DONE':
      return "Path Explorer";
    default:
      return code;
  }
}

String getTranslatedBadgeDescription(String code) {
  switch (code) {
    case 'FIRST_TRADE':
      return "Completed your first trade successfully";
    case 'NETWORTH_1K':
      return "Reached a net worth of \$1,000";
    case 'PORTFOLIO_3_STOCKS':
      return "Added 3 different stocks to your portfolio";
    case 'EDUCATION_MASTER':
      return "Completed all educational modules";
    case 'FIRST_PATH_DONE':
      return "You have completed your first learning path! Keep going to unlock more achievements.";
    default:
      return "";
  }
}

class ProfileDetailsPage extends StatefulWidget {
  final UserModel user;
  const ProfileDetailsPage({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  final _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showEditProfileDialog() async {
    final fullNameController = TextEditingController(text: widget.user.fullName);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showPasswordFields = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            constraints: const BoxConstraints(minWidth: 320, maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2A3FFF)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    filled: true,
                    fillColor: Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Color(0xFF2A3FFF), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Color(0xFF2A3FFF), width: 2),
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 18),
                if (showPasswordFields) ...[
                  TextField(
                    controller: currentPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      filled: true,
                      fillColor: Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Color(0xFF2A3FFF), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Color(0xFF2A3FFF), width: 2),
                      ),
                    ),
                    obscureText: true,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      filled: true,
                      fillColor: Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Color(0xFF2A3FFF), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Color(0xFF2A3FFF), width: 2),
                      ),
                    ),
                    obscureText: true,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      filled: true,
                      fillColor: Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Color(0xFF2A3FFF), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Color(0xFF2A3FFF), width: 2),
                      ),
                    ),
                    obscureText: true,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => showPasswordFields = true),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF2A3FFF),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: const Text('Change Password'),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF2A3FFF),
                          side: const BorderSide(color: Color(0xFF2A3FFF), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (showPasswordFields) {
                            if (newPasswordController.text != confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('New passwords do not match')),
                              );
                              return;
                            }
                            if (newPasswordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('New password cannot be empty')),
                              );
                              return;
                            }
                          }
                          Navigator.pop(context, {
                            'fullName': fullNameController.text,
                            'currentPassword': currentPasswordController.text,
                            'newPassword': newPasswordController.text,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2A3FFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          elevation: 2,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((result) async {
      if (result != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _successMessage = null;
        });

        try {
          if (result['newPassword']?.isNotEmpty == true) {
            // Verify current password first
            final isVerified = await _authService.verifyCurrentPassword(result['currentPassword']);
            if (!isVerified) {
              setState(() {
                _errorMessage = 'Current password is incorrect';
                _isLoading = false;
              });
              return;
            }
          }

          final success = await _authService.updateCurrentUser(
            fullName: result['fullName'],
            password: result['newPassword'],
          );

          if (success) {
            setState(() {
              _successMessage = 'Profile updated successfully';
              _isLoading = false;
            });
            // Refresh user data
            final updatedUser = await _authService.getCurrentUser();
            if (updatedUser != null) {
              Navigator.pop(context, updatedUser);
            }
          } else {
            setState(() {
              _errorMessage = 'Failed to update profile';
              _isLoading = false;
            });
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'An error occurred: $e';
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2A3FFF);
    final secondaryColor = const Color(0xFFF5F6FA);
    final textColor = const Color(0xFF181A20);
    final initials = (widget.user.fullName.isNotEmpty)
        ? widget.user.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '';

    return Scaffold(
      backgroundColor: secondaryColor,
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor.withOpacity(0.12), Colors.white],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Avatar with animation
                      Center(
                        child: Hero(
                          tag: 'profile-avatar',
                          child: Material(
                            color: Colors.transparent,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutBack,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.18),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 54,
                                  backgroundColor: primaryColor.withOpacity(0.12),
                                  child: initials.isNotEmpty
                                      ? Text(
                                          initials,
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        )
                                      : Icon(Icons.person, size: 48, color: primaryColor),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Name & Email
                      Text(
                        widget.user.fullName,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.user.email,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      // Animated Card: Account Info
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.07),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.alternate_email, color: primaryColor, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  widget.user.username,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(Icons.verified, color: primaryColor, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  mapRoleType(widget.user.role),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet, color: primaryColor, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Virtual Balance:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\$ ${widget.user.virtualBalance?.toStringAsFixed(2) ?? '-'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Achievements
                      if (widget.user.badges != null && widget.user.badges!.isNotEmpty) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.07),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.emoji_events, color: primaryColor, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Achievements',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: widget.user.badges!.map((badge) {
                                  final title = getTranslatedBadgeTitle(badge);
                                  final description = getTranslatedBadgeDescription(badge);
                                  return Tooltip(
                                    message: description,
                                    child: Chip(
                                      label: Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Action Buttons
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _showEditProfileDialog,
                              icon: const Icon(Icons.edit, size: 20),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await _authService.logout();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: Icon(Icons.logout, color: primaryColor, size: 20),
                              label: Text('Logout', style: TextStyle(color: primaryColor)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: primaryColor, width: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: CircularProgressIndicator(),
                        ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (_successMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Back button (floating)
          Positioned(
            top: 48,
            left: 8,
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 600),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 