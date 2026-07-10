import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Cart Demo',
        initialRoute: '/cart',
        routes: {
          '/cart': (context) => CartScreen(),
          '/auth': (context) => AuthScreen(),
          '/home': (context) => HomeScreen(),
        },
      ),
    );
  }
}

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _fromCheckout = false;
  
  bool get isLoggedIn => _isLoggedIn;
  bool get fromCheckout => _fromCheckout;
  
  void setLoggedIn(bool value, bool fromCheckout) {
    _isLoggedIn = value;
    _fromCheckout = fromCheckout;
    notifyListeners();
  }
}

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  
  void addItem(String name, double price) {
    _items.add(CartItem(name: name, price: price));
    notifyListeners();
  }
}

class CartItem {
  final String name;
  final double price;
  
  CartItem({required this.name, required this.price});
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.read<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ...cart.items.map((item) => ListTile(
                  title: Text(item.name),
                  subtitle: Text('₹${item.price.toStringAsFixed(2)}'),
                )),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 16)),
                      Text('₹${cart.items.fold(0.0, (sum, item) => sum + item.price).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (auth.isLoggedIn) {
                  Navigator.pushNamed(context, '/home');
                } else {
                  Navigator.pushNamed(context, '/auth').then((_) {
                    auth.setLoggedIn(true, true);
                  });
                }
              },
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isPhoneSubmitted = false;
  bool _isOtpSubmitted = false;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
  
  void _handlePhoneSubmit() {
    if (_phoneController.text.length == 10) {
      setState(() {
        _isPhoneSubmitted = true;
      });
    }
  }
  
  void _handleOtpSubmit() {
    if (_otpController.text.length == 6) {
      setState(() {
        _isOtpSubmitted = true;
      });
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pushNamed(context, '/home');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isPhoneSubmitted) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handlePhoneSubmit,
                child: const Text('Send OTP'),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleOtpSubmit,
                child: const Text('Verify OTP'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.read<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Welcome to Home Screen', style: TextStyle(fontSize: 18)),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Proceed to Checkout'),
                  subtitle: const Text('Click to check checkout functionality'),
                  onTap: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
                if (auth.isLoggedIn) ...[
                  const ListTile(
                    title: const Text('Logout'),
                    subtitle: const Text('Click to logout'),
                    onTap: () {
                      auth.setLoggedIn(false, false);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}