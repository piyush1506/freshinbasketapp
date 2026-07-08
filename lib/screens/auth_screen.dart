import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';

enum AuthStep { phone, otp, name }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthStep _step = AuthStep.phone;
  final _formKey = GlobalKey<FormState>();
  
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_phoneCtrl.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number.')),
      );
      return;
    }
    
    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(_phoneCtrl.text);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully!')),
      );
      setState(() {
        _step = AuthStep.otp;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_otpCtrl.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP.')),
      );
      return;
    }
    
    final auth = context.read<AuthProvider>();
    final data = await auth.verifyOtp(_phoneCtrl.text, _otpCtrl.text);
    
    if (data != null && mounted) {
      context.read<CartProvider>().setLoggedIn(true);
      context.read<CartProvider>().syncAfterLogin();
      context.read<WishlistProvider>().fetchWishlist();
      
      final bool isNewUser = data['is_new_user'] == true;
      final user = auth.user;
      
      if (isNewUser || user?.username == null || user!.username.isEmpty) {
        setState(() {
          _step = AuthStep.name;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful! Welcome back.')),
        );
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  Future<void> _handleUpdateName() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nameCtrl.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    try {
      await auth.updateProfile({'username': _nameCtrl.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, ${_nameCtrl.text}! Your account is ready.')),
        );
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F8F5),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Top Gradient Logo Header
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F3224), Color(0xFF1D523C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -50,
                        right: -50,
                        child: CircleAvatar(
                          radius: 100,
                          backgroundColor: Colors.white.withOpacity(0.025),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white.withOpacity(0.025),
                        ),
                      ),
                      // Brand Identity
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            const Text(
                              'FreshInBasket',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'FARM FRESH DIRECT TO YOUR DOOR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.6),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form Section in Overlapping Card
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _step == AuthStep.phone
                                ? 'Welcome Back'
                                : _step == AuthStep.otp
                                    ? 'Verify OTP'
                                    : 'Complete Profile',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF222222),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _step == AuthStep.phone
                                ? 'Enter your mobile number to log in or register instantly.'
                                : _step == AuthStep.otp
                                    ? 'We have sent a 6-digit verification code to +91 ${_phoneCtrl.text}'
                                    : 'Just one last step to complete your profile!',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF777777),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          
                          if (_step == AuthStep.phone) ...[
                            _buildLabel('Mobile Number'),
                            TextFormField(
                              key: const ValueKey('phone_field'),
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: '9876543210',
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  child: Text('+91 ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF555555))),
                                ),
                                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                                filled: true,
                                fillColor: const Color(0xFFF7F8F6),
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF164431), width: 1.5),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                                if (v.trim().length != 10) return 'Must be exactly 10 digits';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildButton(
                              text: 'Get OTP',
                              icon: Icons.arrow_forward_rounded,
                              loading: auth.loading,
                              onPressed: _handleSendOtp,
                            ),
                          ] else if (_step == AuthStep.otp) ...[
                            _buildLabel('6-Digit Verification Code'),
                            TextFormField(
                              key: const ValueKey('otp_field'),
                              controller: _otpCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8.0, color: Color(0xFF164431)),
                              decoration: InputDecoration(
                                hintText: '000000',
                                counterText: '',
                                hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 0, fontSize: 16, fontWeight: FontWeight.normal),
                                filled: true,
                                fillColor: const Color(0xFFF7F8F6),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF164431), width: 1.5),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'OTP is required';
                                if (v.trim().length != 6) return 'Must be 6 digits';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildButton(
                              text: 'Verify & Proceed',
                              icon: Icons.check_circle_outline_rounded,
                              loading: auth.loading,
                              onPressed: _handleVerifyOtp,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _step = AuthStep.phone;
                                    _otpCtrl.clear();
                                  });
                                },
                                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF164431)),
                                label: const Text('Change Number', style: TextStyle(color: Color(0xFF164431), fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ] else ...[
                            _buildLabel('Your Full Name'),
                            TextFormField(
                              key: const ValueKey('name_field'),
                              controller: _nameCtrl,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Enter your full name',
                                hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                                filled: true,
                                fillColor: const Color(0xFFF7F8F6),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF164431), width: 1.5),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Name is required';
                                if (v.trim().length < 3) return 'Must be at least 3 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildButton(
                              text: 'Start Shopping',
                              icon: Icons.shopping_cart_outlined,
                              loading: auth.loading,
                              onPressed: _handleUpdateName,
                            ),
                          ],
                          
                          if (auth.error != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE8E8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFBD5D5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE53E3E), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF555555),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required IconData icon,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF164431),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 18),
                ],
              ),
      ),
    );
  }
}
