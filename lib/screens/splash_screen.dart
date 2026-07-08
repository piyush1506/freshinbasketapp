import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    // Navigate to home after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF164431),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'fresh',
                              style: GoogleFonts.outfit(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'in',
                              style: GoogleFonts.outfit(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB0B0B0),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'basket',
                          style: GoogleFonts.outfit(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
