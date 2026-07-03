import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:freshinbasket/models/slide.dart';
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
  final ScrollController _scrollCtrl = ScrollController();
  int _currentSlide = 0;
  Timer? _slideTimer;
  String _activeSection = 'fresh';
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _homeFuture = ApiService.fetchHome();
    context.read<CartProvider>().fetchStoreSettings();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.hasClients) {
        if (_scrollCtrl.offset > 110 && !_isScrolled) {
          setState(() {
            _isScrolled = true;
          });
        } else if (_scrollCtrl.offset <= 110 && _isScrolled) {
          setState(() {
            _isScrolled = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _slideTimer?.cancel();
    _scrollCtrl.dispose();
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

  void _loadHomeData() {
    setState(() {
      _homeFuture = ApiService.fetchHome();
    });
  }

  Widget _buildSectionSwitcher() {
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        children: [
          // Fresh Store Tab (Zepto style)
          GestureDetector(
            onTap: () {
              setState(() {
                _activeSection = 'fresh';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _activeSection == 'fresh' ? Colors.white : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _activeSection == 'fresh' ? const Color(0xFF2470F1) : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: _activeSection == 'fresh'
                    ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🥬 ', style: TextStyle(fontSize: 13)),
                    Text(
                      'Fresh Store',
                      style: TextStyle(
                        color: _activeSection == 'fresh' ? const Color(0xFF2470F1) : const Color(0xFF555555),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Organic Store Tab (Zepto style)
          GestureDetector(
            onTap: () {
              setState(() {
                _activeSection = 'organic';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _activeSection == 'organic' ? Colors.white : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _activeSection == 'organic' ? const Color(0xFF2470F1) : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: _activeSection == 'organic'
                    ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌿 ', style: TextStyle(fontSize: 13)),
                    Text(
                      'Organic Store',
                      style: TextStyle(
                        color: _activeSection == 'organic' ? const Color(0xFF2470F1) : const Color(0xFF555555),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _buildContent(),
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
          final rawError = snapshot.error.toString().replaceFirst('Exception: ', '');
          final bool isNetworkError = rawError.contains('Unable to connect') ||
              rawError.contains('SocketException') ||
              rawError.contains('ClientException') ||
              RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(rawError) ||
              rawError.contains('http://') ||
              rawError.contains('https://');
          final String displayMessage = isNetworkError
              ? 'Unable to connect to server. Please check your internet connection.'
              : rawError;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    displayMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadHomeData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
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

        // Filter slides based on active section
        final filteredSlides = slides.where((s) {
          if (_activeSection == 'organic') {
            return s.sectionName?.toLowerCase().contains('organic') ?? false;
          } else {
            return true;
          }
        }).toList();

        // Filter categories & nested products based on active section
        List<Category> filteredCategories = [];
        if (_activeSection == 'organic') {
          filteredCategories = categories
              .where((c) => c.sectionName?.toLowerCase().contains('organic') ?? false)
              .map((c) {
                final organicProducts = c.products.where((p) => p.sectionSlug == 'organic' || p.sectionSlug == 'organic-store').toList();
                return Category(
                  id: c.id,
                  name: c.name,
                  slug: c.slug,
                  description: c.description,
                  imageUrl: c.imageUrl,
                  products: organicProducts,
                  sectionName: c.sectionName,
                );
              })
              .where((c) => c.products.isNotEmpty)
              .toList();
        } else {
          filteredCategories = categories;
        }

        return Stack(
          children: [
            CustomScrollView(
              controller: _scrollCtrl,
              key: ValueKey(_activeSection),
              slivers: [
                // Sliver 1: Company Name Header & Section Tabs Switcher (Scrolls away / collapses)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildSectionSwitcher(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Sliver 2: Search Bar and Category list row (scrolls with view normally)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 10),
                        _buildCategories(filteredCategories),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Sliver 3: Hero slider
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: filteredSlides.isNotEmpty
                        ? _buildSlider(filteredSlides)
                        : _buildSeasonalBanner(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Sliver 4: Products sections
                ...filteredCategories.map((cat) => SliverToBoxAdapter(child: _buildCategorySection(cat))),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),

            // Pinned SearchBar + Categories Overlay (visible only when scrolled down)
            if (_isScrolled)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 10),
                      _buildCategories(filteredCategories),
                    ],
                  ),
                ),
              ),
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
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: category.products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 150,
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
              'FreshInBasket',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF164431), // Use themed primary green
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
                          style: TextStyle(
                            color: _parseHexColor(slide.textColor, Colors.white),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (slide.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          slide.subtitle,
                          style: TextStyle(
                              color: _parseHexColor(slide.textColor, Colors.white70),
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
                      ? const Color(0xFFF91C5F)
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
                color: const Color(0xFFF91C5F),
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
                  const TextStyle(fontSize: 14, color: Color(0xFFF91C5F), fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildCategories(List<Category> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/category/${cat.slug}');
            },
            child: Column(
              children: [
                Container(
                  height: 52,
                  width: 52,
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
                      ? const Icon(Icons.category, color: Color(0xFF666666), size: 20)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  cat.name,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF444444)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Color _parseHexColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (err) {
      debugPrint('Error parsing color: $err');
    }
    return fallback;
  }
}
