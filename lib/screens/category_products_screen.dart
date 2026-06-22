import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../widgets/product_card.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String slug;

  const CategoryProductsScreen({super.key, required this.slug});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  int _selectedFilterIndex = 0;
  late Future<Category?> _categoryFuture;

  @override
  void initState() {
    super.initState();
    _categoryFuture = ApiService.fetchCategory(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: Text(
          widget.slug.isNotEmpty
              ? widget.slug[0].toUpperCase() + widget.slug.substring(1)
              : 'Category',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222222)),
        ),
        backgroundColor: const Color(0xFFF7F8F5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF222222)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF222222)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Category?>(
        future: _categoryFuture,
        builder: (context, catSnapshot) {
          final category = catSnapshot.data;

          return FutureBuilder<List<Product>>(
            future: ApiService.fetchProducts(category: widget.slug),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final products = snapshot.data ?? [];

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 12),
                        _buildBanner(category),
                        const SizedBox(height: 24),
                        _buildFilters(category?.name ?? widget.slug),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                  if (products.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No products found', style: TextStyle(color: Colors.grey)),
                      )),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.95,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => ProductCard(product: products[index]),
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

  Widget _buildBanner(Category? category) {
    final imageUrl = category?.imageUrl;
    final name = category?.name ?? (widget.slug[0].toUpperCase() + widget.slug.substring(1));
    final description = category?.description;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: imageUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(
                  imageUrl.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl',
                ),
                fit: BoxFit.cover,
              )
            : null,
        color: const Color(0xFF164431),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(String title) {
    final filters = ['All $title', 'Organic', 'Popular', 'Sale'];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilterIndex = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF164431) : const Color(0xFFEBEBEB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF444444),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
