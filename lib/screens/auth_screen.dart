import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

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
                // Top Image Header
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=1000'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFF7F8F5).withValues(alpha: 0.9),
                          const Color(0xFFF7F8F5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24, bottom: 20),
                    child: const Text(
                      'HarvestMarket',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF164431),
                      ),
                    ),
                  ),
                ),
                
                // Form Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == AuthStep.phone ? 'Welcome' : _step == AuthStep.otp ? 'Verify OTP' : 'Complete Profile',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _step == AuthStep.phone
                              ? 'Enter your mobile number to log in or create an account instantly.'
                              : _step == AuthStep.otp
                                  ? 'We have sent a 6-digit code to +91 ${_phoneCtrl.text}'
                                  : 'Just one last step to complete your account!',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        if (_step == AuthStep.phone) ...[
                          _buildLabel('Mobile Number'),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: InputDecoration(
                              hintText: '9876543210',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(14.0),
                                child: Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                              ),
                              hintStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF164431)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildButton(
                            text: 'Get OTP',
                            icon: Icons.arrow_forward,
                            loading: auth.loading,
                            onPressed: _handleSendOtp,
                          ),
                        ] else if (_step == AuthStep.otp) ...[
                          _buildLabel('6-Digit OTP'),
                          TextFormField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 8.0),
                            decoration: InputDecoration(
                              hintText: 'Enter OTP',
                              hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 0, fontSize: 16),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF164431)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildButton(
                            text: 'Verify & Proceed',
                            icon: Icons.check_circle_outline,
                            loading: auth.loading,
                            onPressed: _handleVerifyOtp,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _step = AuthStep.phone;
                                });
                              },
                              child: const Text('Change Mobile Number', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else ...[
                          _buildLabel('Full Name'),
                          TextFormField(
                            controller: _nameCtrl,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              hintStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF164431)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildButton(
                            text: 'Start Shopping',
                            icon: Icons.arrow_forward,
                            loading: auth.loading,
                            onPressed: _handleUpdateName,
                          ),
                        ],
                        
                        if (auth.error != null) ...[
                          const SizedBox(height: 16),
                          Text(auth.error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                        ],

                        const SizedBox(height: 32),
                      ],
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
          fontSize: 14,
          color: Color(0xFF333333),
          fontWeight: FontWeight.w500,
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
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 20),
                ],
              ),
      ),
    );
  }
}
