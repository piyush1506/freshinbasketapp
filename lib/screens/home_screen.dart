import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/slide.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_card.dart';
import 'main_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _homeFuture;
  final _pageCtrl = PageController(viewportFraction: 1);
  int _currentSlide = 0;
  Timer? _slideTimer;
  @override
  void initState() {
    super.initState();
    _homeFuture = ApiService.fetchHome();
    context.read<CartProvider>().fetchStoreSettings();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _slideTimer?.cancel();
    super.dispose();
  }

  void _startSlideTimer(int count) {
    _slideTimer?.cancel();
    if (count < 2) return;
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentSlide + 1) % count;
      _pageCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                ],
              ),
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          if (error.contains('credentials') ||
              error.contains('log in') ||
              error.contains('session')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pushReplacementNamed(context, '/auth');
            });
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        }
        final data = snapshot.data!;
        final slides = (data['slides'] as List?)
                ?.map((s) => Slide.fromJson(s))
                .toList() ??
            [];
        final categories = (data['categories'] as List?)
                ?.map((c) => Category.fromJson(c))
                .toList() ??
            [];

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: slides.isNotEmpty
                    ? _buildSlider(slides)
                    : _buildSeasonalBanner(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSectionHeader('Categories', 'View all', () {
                  MainShell.switchTab(context, 1);
                }),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildCategories(categories)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ...categories.map((cat) => SliverToBoxAdapter(child: _buildCategorySection(cat))),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSectionHeader("What's New", '', null),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildWhatsNew()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection(Category category) {
    if (category.products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSectionHeader(category.name, 'View All', () {
            Navigator.pushNamed(context, '/category/${category.slug}');
          }),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: category.products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 140,
                child: ProductCard(product: category.products[index], isHorizontal: true),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeader() {
    final user = context.watch<AuthProvider>().user;
    final initial = (user?.username.isNotEmpty == true)
        ? user!.username[0].toUpperCase()
        : 'F';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Freshinbasket',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF164431),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Fresh from farm to table',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => MainShell.switchTab(context, 4),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF164431),
            backgroundImage: (user?.avatar != null)
                ? CachedNetworkImageProvider(
                    user!.avatar!.startsWith('http')
                        ? user.avatar!
                        : '${ApiService.baseUrl}${user.avatar}',
                  )
                : null,
            child: (user?.avatar == null)
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/search'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: const Row(
          children: [
            Icon(Icons.search, color: Color(0xFF666666)),
            SizedBox(width: 12),
            Text(
              'Search for organic produce...',
              style: TextStyle(color: Color(0xFF999999), fontSize: 16),
            ),
            Spacer(),
            Icon(Icons.mic_none, color: Color(0xFF666666)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(List<Slide> slides) {
    if (_slideTimer == null || !_slideTimer!.isActive) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _startSlideTimer(slides.length));
    }

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _currentSlide = i),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: slide.imageUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(slide.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (slide.title.isNotEmpty)
                        Text(
                          slide.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (slide.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          slide.subtitle,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (slides.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(slides.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentSlide == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentSlide == i
                      ? const Color(0xFF2D9350)
                      : const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildSeasonalBanner() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
              'https://images.unsplash.com/photo-1595855761054-94639908cf2c?auto=format&fit=crop&q=80&w=600'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF164431).withValues(alpha: 0.85),
              Colors.transparent,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A6A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'SEASONAL SPECIAL',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Fresh for you',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Up to 30% off\nsummer berries and\ngreens.',
              style:
                  TextStyle(color: Colors.white70, fontSize: 14, height: 1.3),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF164431),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Shop Now',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, String action, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF222222)),
        ),
        if (action.isNotEmpty && onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style:
                  const TextStyle(fontSize: 14, color: Color(0xFF444444)),
            ),
          ),
      ],
    );
  }

  Widget _buildCategories(List<Category> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/category/${cat.slug}');
            },
            child: Column(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEBEB),
                    shape: BoxShape.circle,
                    image: cat.imageUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              cat.imageUrl!.startsWith('http')
                                  ? cat.imageUrl!
                                  : '${ApiService.baseUrl}${cat.imageUrl}',
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: cat.imageUrl == null
                      ? const Icon(Icons.category, color: Color(0xFF666666))
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  cat.name,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF444444)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWhatsNew() {
    final updates = [
      {
        'icon': Icons.local_offer,
        'title': 'Flash Sale',
        'subtitle': 'Up to 50% off on seasonal fruits',
        'color': const Color(0xFFFF7A6A),
      },
      {
        'icon': Icons.new_releases,
        'title': 'New Arrivals',
        'subtitle': 'Fresh organic veggies just landed',
        'color': const Color(0xFF2D9350),
      },
      {
        'icon': Icons.delivery_dining,
        'title': 'Free Delivery',
        'subtitle': 'On orders above ₹100',
        'color': const Color(0xFF164431),
      },
      {
        'icon': Icons.card_giftcard,
        'title': 'Refer & Earn',
        'subtitle': 'Get ₹25 off on your next order',
        'color': const Color(0xFFB14E3F),
      },
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: updates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = updates[index];
          return Container(
            width: 200,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (item['color'] as Color).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
