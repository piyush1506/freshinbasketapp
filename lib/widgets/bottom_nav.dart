import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    final itemCount = context.watch<CartProvider>().itemCount;

    return Container(
      color: const Color(0xFFF7F8F5),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(context, 0, Icons.home_outlined, Icons.home, 'Home', '/home'),
            _buildNavItem(context, 1, Icons.storefront_outlined, Icons.storefront, 'Shop', '/categories'),
            _buildNavItem(context, 2, Icons.shopping_cart_outlined, Icons.shopping_cart, 'Cart', '/cart', badge: itemCount),
            _buildNavItem(context, 3, Icons.receipt_long_outlined, Icons.receipt_long, 'Orders', '/orders'),
            _buildNavItem(context, 4, Icons.person_outline, Icons.person, 'Profile', '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label, String route, {int badge = 0}) {
    final isActive = currentIndex == index;
    final color = isActive ? Colors.white : const Color(0xFF4A4A4A);
    final bgColor = isActive ? const Color(0xFF164431) : Colors.transparent;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isActive ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, color: color, size: 24),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFB14E3F),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
