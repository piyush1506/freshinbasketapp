import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _ctrl;
  late FocusNode _focusNode;
  List<Product> _allProducts = [];
  List<Product> _suggestions = [];
  bool _loadingAll = true;
  bool _loadingSuggestions = false;
  bool _showSuggestions = false;
  bool _showResults = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
    _focusNode = FocusNode();
    _ctrl.addListener(_onTextChanged);
    _fetchAllProducts();
    if (widget.query.isNotEmpty) {
      _showResults = true;
      _fetchSuggestions(widget.query);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchAllProducts() async {
    setState(() => _loadingAll = true);
    try {
      final products = await ApiService.fetchProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _loadingAll = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAll = false);
    }
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final q = _ctrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _showResults = false;
        _loadingSuggestions = false;
      });
      return;
    }
    if (_showResults) setState(() => _showResults = false);
    if (!_showSuggestions) setState(() => _showSuggestions = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _fetchSuggestions(q));
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _loadingSuggestions = true);
    try {
      final products = await ApiService.searchProducts(query);
      if (!mounted) return;
      setState(() {
        _suggestions = products;
        _loadingSuggestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSuggestions = false);
    }
  }

  void _onSuggestionTap(Product product) {
    _focusNode.unfocus();
    _ctrl.removeListener(_onTextChanged);
    _ctrl.text = product.name;
    _ctrl.addListener(_onTextChanged);
    setState(() {
      _showSuggestions = false;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search for organic produce...',
            border: InputBorder.none,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _ctrl.clear();
                      _focusNode.requestFocus();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                        _showResults = false;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildProductsGrid(),
          if (_showSuggestions) _buildSuggestionsOverlay(),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_loadingAll) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allProducts.isEmpty) {
      return const Center(
        child: Text('No products available',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    List<Product> displayProducts;
    if (_showResults) {
      displayProducts = _suggestions;
    } else if (_ctrl.text.isNotEmpty && _suggestions.isNotEmpty && !_showSuggestions) {
      displayProducts = _suggestions;
    } else {
      displayProducts = _allProducts;
    }

    if (displayProducts.isEmpty) {
      return const Center(
        child: Text('No products found',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.95,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: displayProducts.length,
        itemBuilder: (context, index) =>
            ProductCard(product: displayProducts[index]),
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    if (_loadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_suggestions.isEmpty) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: const Text('No suggestions found',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 360),
        color: Colors.white,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final product = _suggestions[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              title: Text(product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                '₹${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Color(0xFF2D9350),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              onTap: () => _onSuggestionTap(product),
            );
          },
        ),
      ),
    );
  }
}
