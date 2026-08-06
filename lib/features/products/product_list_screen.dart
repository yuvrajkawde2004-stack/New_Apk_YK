import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/product.dart';
import '../../core/database/database_helper.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with SingleTickerProviderStateMixin {
  bool _isGridView = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  late TabController _tabController;

  final List<String> _categories = [
    'All', 'Saree', 'Kurti', 'Lehenga', 'Suit', 'Dupatta', 'Gown'
  ];

  List<Product> _dbProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await DatabaseHelper.instance.getProducts(limit: 100);
    final products = data.map<Product>((json) {
      return Product(
        id: json['id'],
        name: json['product_name'] ?? '',
        category: json['category'] ?? '',
        mrp: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
        purchasePrice: (json['purchase_rate'] as num?)?.toDouble() ?? 0.0,
        sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
        stock: json['quantity'] ?? 0,
        lowStockThreshold: json['low_stock_limit'] ?? 5,
        brand: json['supplier_name'] ?? '',
        unit: json['unit'] ?? 'PCS',
      );
    }).toList();
    
    if (mounted) {
      setState(() {
        _dbProducts = products;
        _isLoading = false;
      });
    }
  }

  List<Product> get _filtered {
    var list = _dbProducts;
    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            color: AppColors.royalBlue,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_product',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ),
        backgroundColor: AppColors.royalBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Hero(
              tag: 'search_bar',
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search products, brands...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.royalBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintStyle: TextStyle(color: AppColors.textSecondaryLight.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ).animate().slideY(begin: -0.2, end: 0).fadeIn(),
          ),

          // Category Filter Chips
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    child: FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.royalBlue,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textSecondaryLight,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: selected ? AppColors.royalBlue : AppColors.textSecondaryLight.withValues(alpha: 0.2)),
                      ),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                );
              },
            ),
          ),

          // Product Count
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Text('${_filtered.length} products found',
                    style: TextStyle(
                        color: AppColors.textSecondaryLight.withValues(alpha: 0.7), fontSize: 13)),
              ],
            ),
          ),

          // Product Grid / List
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isGridView ? _buildGrid() : _buildList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _ProductGridCard(product: _filtered[i], index: i),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _ProductListCard(product: _filtered[i], index: i),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 72, color: AppColors.textSecondaryLight.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No products found',
              style: TextStyle(
                  color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ).animate().scale().fadeIn(),
    );
  }
}

// ──────────── Product Grid Card ────────────
class _ProductGridCard extends StatelessWidget {
  final Product product;
  final int index;
  const _ProductGridCard({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Icon / Image
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.royalBlue.withValues(alpha: 0.08),
                      AppColors.purpleAccent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.checkroom_rounded,
                  size: 44,
                  color: AppColors.royalBlue.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 10),
              Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(product.category ?? '',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.royalBlue.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${product.sellingPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.royalBlue),
                  ),
                  _StockBadge(product: product),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(delay: (50 * index).ms, duration: 350.ms, curve: Curves.easeOutBack);
  }
}

// ──────────── Product List Card ────────────
class _ProductListCard extends StatelessWidget {
  final Product product;
  final int index;
  const _ProductListCard({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.royalBlue.withValues(alpha: 0.1),
                      AppColors.purpleAccent.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.checkroom_rounded,
                    color: AppColors.royalBlue.withValues(alpha: 0.7), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('${product.category} • ${product.color}',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondaryLight.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${product.sellingPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.royalBlue)),
                  const SizedBox(height: 4),
                  _StockBadge(product: product),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slideX(delay: (50 * index).ms, begin: 0.1, end: 0).fadeIn();
  }
}

// ──────────── Stock Badge ────────────
class _StockBadge extends StatelessWidget {
  final Product product;
  const _StockBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    final (color, text) = product.isOutOfStock
        ? (Colors.red, 'Out of Stock')
        : product.isLowStock
            ? (AppColors.softOrange, 'Low: ${product.stock}')
            : (AppColors.emeraldGreen, 'Qty: ${product.stock}');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
