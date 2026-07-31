import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/database/database_helper.dart';
import '../dashboard/providers/dashboard_provider.dart';
import '../products/add_product_screen.dart';

class _StockItem {
  final int id;
  final String name, category;
  int stock;
  final int threshold;
  final double value;

  _StockItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.threshold,
    required this.value,
  });
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_StockItem> _items = [
    _StockItem(id: 1, name: 'Kanjivaram Silk Saree', category: 'Saree', stock: 15, threshold: 5, value: 10500),
    _StockItem(id: 2, name: 'Cotton Kurti - Block Print', category: 'Kurti', stock: 3, threshold: 5, value: 950),
    _StockItem(id: 3, name: 'Bridal Lehenga Set', category: 'Lehenga', stock: 2, threshold: 3, value: 38000),
    _StockItem(id: 4, name: 'Georgette Dupatta', category: 'Dupatta', stock: 25, threshold: 8, value: 650),
    _StockItem(id: 5, name: 'Salwar Suit Set', category: 'Suit', stock: 0, threshold: 5, value: 2800),
    _StockItem(id: 6, name: 'Anarkali Gown', category: 'Gown', stock: 8, threshold: 3, value: 4200),
    _StockItem(id: 7, name: 'Chiffon Saree', category: 'Saree', stock: 4, threshold: 5, value: 3200),
    _StockItem(id: 8, name: 'Silk Kurta Set', category: 'Kurti', stock: 0, threshold: 5, value: 2100),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddStockSheet([_StockItem? preselectedItem]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStockSheet(
        items: _items,
        preselectedItem: preselectedItem,
        onStockAdded: (selectedItem, qtyAdded) {
          setState(() {
            selectedItem.stock += qtyAdded;
          });

          // Sync with local SQLite Database
          DatabaseHelper.instance.increaseStock(selectedItem.id, qtyAdded).catchError((_) {});

          // Refresh Dashboard metrics
          if (mounted) {
            Provider.of<DashboardProvider>(context, listen: false).refreshDashboard();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added +$qtyAdded stock to "${selectedItem.name}"! Total: ${selectedItem.stock}'),
                backgroundColor: AppColors.emeraldGreen,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.translate('inventory')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _openAddStockSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.royalBlue, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Add Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.royalBlue,
          indicatorWeight: 3,
          labelColor: AppColors.royalBlue,
          unselectedLabelColor: AppColors.textSecondaryLight,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'All Stock'),
            Tab(text: 'Low Stock'),
            Tab(text: 'Out of Stock'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_stock',
        onPressed: () => _openAddStockSheet(),
        backgroundColor: AppColors.royalBlue,
        icon: const Icon(Icons.add_box_rounded, color: Colors.white),
        label: const Text(
          'Add Stock',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StockList(items: _items, filter: 'all', onAddStock: _openAddStockSheet),
          _StockList(items: _items, filter: 'low', onAddStock: _openAddStockSheet),
          _StockList(items: _items, filter: 'out', onAddStock: _openAddStockSheet),
        ],
      ),
    );
  }
}

class _StockList extends StatelessWidget {
  final List<_StockItem> items;
  final String filter;
  final Function(_StockItem) onAddStock;

  const _StockList({
    required this.items,
    required this.filter,
    required this.onAddStock,
  });

  List<_StockItem> get _filteredItems {
    switch (filter) {
      case 'low':
        return items.where((i) => i.stock > 0 && i.stock <= i.threshold).toList();
      case 'out':
        return items.where((i) => i.stock == 0).toList();
      default:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredItems;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter == 'low' ? Icons.check_circle_outline : Icons.inventory_2_outlined,
              size: 72,
              color: AppColors.emeraldGreen.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              filter == 'low' ? 'No low stock items! 🎉' : 'No out of stock items! 🎉',
              style: TextStyle(
                color: AppColors.textSecondaryLight.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().scale().fadeIn(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (_, i) => _StockCard(
        item: list[i],
        index: i,
        onAddStock: () => onAddStock(list[i]),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final _StockItem item;
  final int index;
  final VoidCallback onAddStock;

  const _StockCard({
    required this.item,
    required this.index,
    required this.onAddStock,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = item.stock == 0;
    final isLow = item.stock > 0 && item.stock <= item.threshold;
    final (color, label) = isOut
        ? (Colors.red, 'Out of Stock')
        : isLow
            ? (AppColors.softOrange, 'Low Stock')
            : (AppColors.emeraldGreen, 'In Stock');

    final stockPct = (item.stock / (item.threshold * 3)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.checkroom_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(item.category,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondaryLight.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(label,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(height: 4),
                  Text('Qty: ${item.stock}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimaryLight)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stock progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isOut ? 0 : stockPct,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹${item.value.toStringAsFixed(0)} per unit',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondaryLight.withValues(alpha: 0.8))),
                  Text('Min Threshold: ${item.threshold}',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondaryLight.withValues(alpha: 0.6))),
                ],
              ),

              // Quick "+ Add Stock" Button on card
              ElevatedButton.icon(
                onPressed: onAddStock,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.white),
                label: const Text(
                  '+ Stock',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(delay: (index * 60).ms, begin: 0.15, end: 0).fadeIn();
  }
}

// ─────────────────── ADD / UPDATE STOCK SHEET ───────────────────
class _AddStockSheet extends StatefulWidget {
  final List<_StockItem> items;
  final _StockItem? preselectedItem;
  final Function(_StockItem selectedItem, int qtyAdded) onStockAdded;

  const _AddStockSheet({
    required this.items,
    this.preselectedItem,
    required this.onStockAdded,
  });

  @override
  State<_AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<_AddStockSheet> {
  _StockItem? _selectedItem;
  final TextEditingController _qtyController = TextEditingController(text: '10');
  final TextEditingController _supplierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.preselectedItem ?? (widget.items.isNotEmpty ? widget.items.first : null);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_box_rounded, color: AppColors.royalBlue),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Product Stock',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Select Product Dropdown
          const Text('Select Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_StockItem>(
                value: _selectedItem,
                isExpanded: true,
                items: widget.items.map((item) {
                  return DropdownMenuItem<_StockItem>(
                    value: item,
                    child: Text('${item.name} (Current: ${item.stock})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedItem = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quantity to Add Input
          const Text('Quantity to Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final cur = int.tryParse(_qtyController.text) ?? 1;
                  if (cur > 1) {
                    _qtyController.text = (cur - 1).toString();
                  }
                },
                icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.royalBlue, size: 28),
              ),
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final cur = int.tryParse(_qtyController.text) ?? 0;
                  _qtyController.text = (cur + 1).toString();
                },
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.royalBlue, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Optional Supplier Name
          TextField(
            controller: _supplierController,
            decoration: InputDecoration(
              labelText: 'Supplier Name (optional)',
              prefixIcon: const Icon(Icons.store_outlined, color: AppColors.royalBlue),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Update & Save Stock Button
          ElevatedButton(
            onPressed: () {
              if (_selectedItem == null) return;
              final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
              if (qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity')),
                );
                return;
              }

              widget.onStockAdded(_selectedItem!, qty);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text(
              'Update & Save Stock',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
              icon: const Icon(Icons.add, color: AppColors.royalBlue, size: 18),
              label: const Text(
                'Add Entirely New Product',
                style: TextStyle(color: AppColors.royalBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
