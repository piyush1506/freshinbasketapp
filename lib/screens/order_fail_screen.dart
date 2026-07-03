import 'package:flutter/material.dart';

class OrderFailScreen extends StatefulWidget {
  final String? reason;

  const OrderFailScreen({super.key, this.reason});

  @override
  State<OrderFailScreen> createState() => _OrderFailScreenState();
}

class _OrderFailScreenState extends State<OrderFailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated X circle
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 68),
                ),
              ),
              const SizedBox(height: 36),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text(
                      'Order Failed',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.reason?.isNotEmpty == true
                          ? widget.reason!
                          : 'Something went wrong while processing your order. Please try again.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF777777), height: 1.6),
                    ),
                    const SizedBox(height: 40),

                    // What to do card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('What can I do?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
                          const SizedBox(height: 16),
                          _tip(Icons.refresh_rounded, 'Try placing the order again'),
                          const SizedBox(height: 12),
                          _tip(Icons.credit_card_rounded, 'Check your payment method details'),
                          const SizedBox(height: 12),
                          _tip(Icons.wifi_rounded, 'Ensure you have a stable internet connection'),
                          const SizedBox(height: 12),
                          _tip(Icons.support_agent_rounded, 'Contact support if the issue persists'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Retry button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          // Pop back to checkout
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Try Again', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Go home button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/main', arguments: 0),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF164431),
                          side: const BorderSide(color: Color(0xFF164431), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Go to Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF164431), size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
      ],
    );
  }
}
