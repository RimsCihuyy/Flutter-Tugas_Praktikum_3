import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PastelStoreApp());
}

// ==================== THEME ====================

class AppColors {
  static const background = Color(0xFFFFF9F5);
  static const lavender = Color(0xFFDCD6F7);
  static const pink = Color(0xFFFFDCE5);
  static const mint = Color(0xFFDDF4E7);
  static const cream = Color(0xFFFFEBC8);
  static const purple = Color(0xFF8174B8);
  static const text = Color(0xFF393447);
  static const subtitle = Color(0xFF96909F);
  static const white = Colors.white;
}

class PastelStoreApp extends StatelessWidget {
  const PastelStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pastel Store',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.purple,
          surface: AppColors.background,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ==================== PRODUCT MODEL ====================

class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final double discountPercentage;
  final String brand;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    required this.images,
    required this.discountPercentage,
    required this.brand,
  });

  // Parsing dibuat toleran: MySQL/PHP kadang mengirim angka sebagai string ("20")
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? 'Unknown Product',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      price: _toDouble(json['price']),
      rating: _toDouble(json['rating']),
      stock: _toInt(json['stock']),
      thumbnail: json['thumbnail']?.toString() ?? '',
      images: _toImages(json['images']),
      discountPercentage: _toDouble(json['discountPercentage']),
      brand: json['brand']?.toString() ?? 'Pastel Collection',
    );
  }
}

// ==================== API SERVICE ====================

class ProductService {
  // Android emulator: 10.0.2.2 = "localhost" milik laptop.
  // HP asli: ganti dengan IP laptop di WiFi yang sama, mis. '192.168.1.10'.
  static const String host = 'localhost';
  static const String baseUrl = 'http://$host:8080/products';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };
  static const Duration _timeout = Duration(seconds: 15);

  // READ - semua produk
  static Future<List<Product>> fetchProducts() async {
    final response = await http
        .get(Uri.parse('$baseUrl?limit=0'))
        .timeout(_timeout);
    _check(response, 'Memuat produk');

    final data = jsonDecode(response.body);
    final List products = data is Map ? data['products'] : data;
    return products.map((item) => Product.fromJson(item)).toList();
  }

  // CREATE
  static Future<void> createProduct(Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/add'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    _check(response, 'Menambah produk');
  }

  // UPDATE
  static Future<void> updateProduct(int id, Map<String, dynamic> body) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/$id'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    _check(response, 'Mengubah produk');
  }

  // DELETE
  static Future<void> deleteProduct(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/$id'))
        .timeout(_timeout);
    _check(response, 'Menghapus produk');
  }

  static void _check(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$action gagal (${response.statusCode})');
    }
  }
}

// ==================== HOME PAGE ====================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await ProductService.fetchProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
        _applyFilters();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load products. Please try again.';
      });
    }
  }

  List<String> get _categories {
    final categories =
        _products.map((product) => product.category).toSet().toList()..sort();

    return ['All', ...categories];
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    _filteredProducts = _products.where((product) {
      final matchesSearch =
          product.title.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _applyFilters();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormPage()),
          );
          if (added == true) _loadProducts();
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              )
            : _errorMessage != null
            ? _buildError()
            : RefreshIndicator(
                color: AppColors.purple,
                onRefresh: _loadProducts,
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    SliverToBoxAdapter(child: _buildCategorySection()),
                    SliverToBoxAdapter(child: _buildSectionTitle()),
                    if (_filteredProducts.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No products found 🥺',
                            style: TextStyle(
                              color: AppColors.subtitle,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final product = _filteredProducts[index];

                            return ProductCard(
                              product: product,
                              index: index,
                              onTap: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(product: product),
                                  ),
                                );
                                if (changed == true) _loadProducts();
                              },
                            );
                          }, childCount: _filteredProducts.length),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.61,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: AppColors.purple,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rim Store',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Little things, lovely days ✨',
                  style: TextStyle(fontSize: 12, color: AppColors.subtitle),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.pink,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFE88CA8),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.lavender.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Find something lovely...',
            hintStyle: const TextStyle(color: AppColors.subtitle, fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.purple,
            ),
            suffixIcon: IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close_rounded, color: AppColors.subtitle),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = _categories;

    return SizedBox(
      height: 57,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 5),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => _selectCategory(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? AppColors.purple : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: selected ? AppColors.purple : AppColors.lavender,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                category == 'All' ? 'All items' : _capitalize(category),
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore collection',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your next favorite is waiting 💗',
                  style: TextStyle(color: AppColors.subtitle, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${_filteredProducts.length} items',
            style: const TextStyle(
              color: AppColors.purple,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 65,
              color: AppColors.purple,
            ),
            const SizedBox(height: 18),
            const Text(
              'Oops! Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subtitle),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loadProducts,
              style: FilledButton.styleFrom(backgroundColor: AppColors.purple),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PRODUCT CARD ====================

class ProductCard extends StatelessWidget {
  final Product product;
  final int index;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.onTap,
  });

  static const List<Color> pastelColors = [
    AppColors.lavender,
    AppColors.pink,
    AppColors.mint,
    AppColors.cream,
  ];

  @override
  Widget build(BuildContext context) {
    final background = pastelColors[index % pastelColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.lavender.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: background.withValues(alpha: 0.65),
                    padding: const EdgeInsets.all(12),
                    child: Image.network(
                      product.thumbnail,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) {
                        return const Icon(
                          Icons.image_not_supported_outlined,
                          size: 42,
                          color: AppColors.purple,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '-${product.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalize(product.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.subtitle,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC45C),
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PRODUCT DETAIL PAGE ====================

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              title: const Text(
                'Product details',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_rounded, color: AppColors.purple),
                  onPressed: () async {
                    final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductFormPage(product: product),
                      ),
                    );
                    if (saved == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFD9667F),
                  ),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 25, 22, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategory(),
                        const SizedBox(height: 12),
                        Text(
                          product.title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 27,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pink,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                                style: const TextStyle(
                                  color: Color(0xFFB95D7A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 19),
                        _buildStats(),
                        const SizedBox(height: 28),
                        const Text(
                          'About this item',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          product.description,
                          style: const TextStyle(
                            color: AppColors.subtitle,
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildInfoRow(
                          Icons.sell_outlined,
                          'Brand',
                          product.brand,
                          AppColors.lavender,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.inventory_2_outlined,
                          'Availability',
                          product.stock > 0
                              ? '${product.stock} items in stock'
                              : 'Out of stock',
                          AppColors.mint,
                        ),
                        const SizedBox(height: 25),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(17),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFE7A94C),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'A little something to brighten your day.',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product.title}" will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ProductService.deleteProduct(product.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product deleted')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _buildProductImage() {
    return Container(
      width: double.infinity,
      height: 310,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.purple,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Center(
              child: Image.network(
                product.thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    size: 65,
                    color: AppColors.purple,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _capitalize(product.category),
        style: const TextStyle(
          color: Color(0xFF468A69),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            Icons.star_rounded,
            product.rating.toStringAsFixed(1),
            'Rating',
            AppColors.cream,
            const Color(0xFFE3A43C),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            Icons.inventory_2_rounded,
            '${product.stock}',
            'Stock',
            AppColors.mint,
            const Color(0xFF579777),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    IconData icon,
    String value,
    String label,
    Color background,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 25),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.purple, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PRODUCT FORM PAGE (ADD / EDIT) ====================

class ProductFormPage extends StatefulWidget {
  // null = tambah produk baru, berisi = edit produk
  final Product? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _brand;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _thumbnail;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _title = TextEditingController(text: p?.title ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _price = TextEditingController(text: p == null ? '' : '${p.price}');
    _stock = TextEditingController(text: p == null ? '' : '${p.stock}');
    _thumbnail = TextEditingController(text: p?.thumbnail ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    _brand.dispose();
    _price.dispose();
    _stock.dispose();
    _thumbnail.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'category': _category.text.trim().toLowerCase().replaceAll(' ', '-'),
      'brand': _brand.text.trim(),
      'price': double.parse(_price.text.trim().replaceAll(',', '.')),
      'stock': int.parse(_stock.text.trim()),
    };
    if (_thumbnail.text.trim().isNotEmpty) {
      body['thumbnail'] = _thumbnail.text.trim();
    }

    try {
      if (_isEdit) {
        await ProductService.updateProduct(widget.product!.id, body);
      } else {
        await ProductService.createProduct(body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Product updated' : 'Product added')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  String? _validPrice(String? v) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    return (n == null || n < 0) ? 'Isi dengan angka yang valid' : null;
  }

  String? _validStock(String? v) {
    final n = int.tryParse((v ?? '').trim());
    return (n == null || n < 0) ? 'Isi dengan bilangan bulat' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit product' : 'Add product',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _field(_title, 'Title', validator: _required),
              _field(_description, 'Description', maxLines: 3),
              _field(
                _category,
                'Category (contoh: laptops)',
                validator: _required,
              ),
              _field(_brand, 'Brand'),
              _field(
                _price,
                'Price',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validator: _validPrice,
              ),
              _field(
                _stock,
                'Stock',
                keyboard: TextInputType.number,
                validator: _validStock,
              ),
              _field(
                _thumbnail,
                'Thumbnail URL (opsional)',
                keyboard: TextInputType.url,
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Add product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HELPER ====================

int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

List<String> _toImages(dynamic v) {
  dynamic value = v;
  if (value is String && value.isNotEmpty) {
    try {
      value = jsonDecode(value);
    } catch (_) {
      return [value as String];
    }
  }
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}

String _capitalize(String value) {
  if (value.isEmpty) return value;

  return value
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
