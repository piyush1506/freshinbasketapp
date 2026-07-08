import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../widgets/product_card.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String slug;

  const CategoryProductsScreen({super.key, required this.slug});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  late String _currentSlug;
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _currentSlug = widget.slug;
    _categoriesFuture = ApiService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: Text(
          _currentSlug.isNotEmpty
              ? _currentSlug[0].toUpperCase() + _currentSlug.substring(1)
              : 'Category',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF222222),
          ),
        ),
        backgroundColor: const Color(0xFFF7F8F5),
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF222222)),
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, catListSnapshot) {
          if (catListSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (catListSnapshot.hasError) {
            return Center(child: Text('Error: ${catListSnapshot.error}'));
          }

          final categories = catListSnapshot.data ?? [];
          Category? activeCategory;
          try {
            activeCategory = categories.firstWhere(
              (c) => c.slug == _currentSlug,
            );
          } catch (_) {
            if (categories.isNotEmpty) {
              activeCategory = categories.first;
            }
          }

          return FutureBuilder<List<Product>>(
            future: ApiService.fetchProducts(category: _currentSlug),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // All products shown directly
              final products = List<Product>.from(snapshot.data ?? []);

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),
                        Text(
                          activeCategory?.name ??
                              (_currentSlug[0].toUpperCase() + _currentSlug.substring(1)),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF164431),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (activeCategory?.description != null && activeCategory!.description!.isNotEmpty)
                          Text(
                            activeCategory.description!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF777777)),
                          ),
                        const SizedBox(height: 16),
                        _buildAllCategoriesList(categories),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                  if (products.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No products found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.68,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              ProductCard(product: products[index]),
                          childCount: products.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildAllCategoriesList(List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat.slug == _currentSlug;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentSlug = cat.slug;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8ECE9) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF164431)
                          : const Color(0xFFEEF0EC),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: cat.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: cat.imageUrl!.startsWith('http')
                                      ? cat.imageUrl!
                                      : '${ApiService.baseUrl}${cat.imageUrl}',
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF164431),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF164431)
                              : const Color(0xFF555555),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}
