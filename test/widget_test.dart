import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:freshinbasket/main.dart';
import 'package:freshinbasket/providers/auth_provider.dart';
import 'package:freshinbasket/providers/cart_provider.dart';
import 'package:freshinbasket/providers/wishlist_provider.dart';

void main() {
  testWidgets('App renders auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: const FreshInBasketApp(),
    ));
    expect(find.text('Freshinbasket'), findsOneWidget);
  });
}
