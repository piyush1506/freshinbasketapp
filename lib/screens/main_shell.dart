import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'home_screen.dart';
import 'category_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;

  const MainShell({super.key, this.initialTab = 0});

  static void switchTab(BuildContext context, int index) {
    context.findAncestorStateOfType<MainShellState>()?.switchTab(index);
  }

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _currentTab;

  final _pages = const [
    HomeScreen(),
    CategoryScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  void switchTab(int index) {
    if (index != _currentTab) setState(() => _currentTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: switchTab,
        backgroundColor: const Color(0xFFF7F8F5),
        indicatorColor: const Color(0xFF164431),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(_currentTab == 0 ? Icons.home : Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(_currentTab == 1 ? Icons.storefront : Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront, color: Colors.white),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: itemCount > 0,
              label: Text(itemCount > 99 ? '99+' : '$itemCount'),
              child: Icon(_currentTab == 2 ? Icons.shopping_cart : Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: itemCount > 0,
              label: Text(itemCount > 99 ? '99+' : '$itemCount'),
              child: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(_currentTab == 3 ? Icons.receipt_long : Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long, color: Colors.white),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(_currentTab == 4 ? Icons.person : Icons.person_outline),
            selectedIcon: const Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
