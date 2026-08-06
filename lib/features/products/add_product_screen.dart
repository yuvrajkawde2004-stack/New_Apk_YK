import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../../widgets/animated_premium_button.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _mrpController = TextEditingController();
  final _purchaseController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _unitController = TextEditingController(text: 'PCS');

  List<String> _availableUnits = ['PCS', 'PAIR', 'KG', 'MTR', 'BOX', 'LTR'];
  String? _selectedGst;
  String? _selectedColor;
  bool _isSaving = false;
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  final _categories = ['Saree', 'Kurti', 'Lehenga', 'Suit', 'Dupatta', 'Gown', 'Other'];
  final _gstRates = ['0%', '5%', '12%', '18%', '28%'];
  final _colors = ['Red', 'Blue', 'Green', 'Yellow', 'Pink', 'Orange', 'White', 'Black', 'Maroon', 'Navy', 'Teal'];

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final units = await DatabaseHelper.instance.getUnits();
    if (units.isNotEmpty) {
      setState(() => _availableUnits = units);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _mrpController.dispose();
    _purchaseController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product Name is required')));
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      String unitText = _unitController.text.trim().toUpperCase();
      if (unitText.isEmpty) unitText = 'PCS';
      
      // Silently add new unit to database if it doesn't exist
      await DatabaseHelper.instance.addUnit(unitText);

      await DatabaseHelper.instance.addProduct({
        'product_name': _nameController.text.trim(),
        'category': 'Default', // Category removed per request
        'purchase_rate': double.tryParse(_purchaseController.text) ?? 0.0,
        'quantity': int.tryParse(_stockController.text) ?? 0,
        'supplier_name': _brandController.text.trim(),
        'image_url': _selectedImage?.path ?? '',
        'purchase_date': DateTime.now().toIso8601String(),
        'low_stock_limit': 5,
        'created_at': DateTime.now().toIso8601String(),
        'unit': unitText,
      });

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Product saved successfully!'),
            ],
          ),
          backgroundColor: AppColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Placeholder
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.royalBlue.withValues(alpha: 0.1), AppColors.purpleAccent.withValues(alpha: 0.1)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: AppColors.royalBlue, size: 32),
                              SizedBox(height: 6),
                              Text('Add Photo', style: TextStyle(color: AppColors.royalBlue, fontSize: 12)),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                ),
              ),
              const SizedBox(height: 28),

              _sectionHeader('Basic Details'),
              const SizedBox(height: 14),
              _buildCard([
                _field(controller: _nameController, label: 'Product Name *',
                    icon: Icons.label_rounded),
                const SizedBox(height: 16),
                _field(controller: _brandController, label: 'Supplier / Purchase Name', icon: Icons.branding_watermark),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _unitAutocompleteField(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _dropdown(
                        label: 'Color',
                        value: _selectedColor,
                        items: _colors,
                        onChanged: (v) => setState(() => _selectedColor = v),
                      ),
                    ),
                  ],
                ),
              ], 0),

              const SizedBox(height: 20),
              _sectionHeader('Pricing'),
              const SizedBox(height: 14),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: _field(
                          controller: _mrpController,
                          label: 'MRP (₹)',
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                          controller: _purchaseController,
                          label: 'Purchase ₹',
                          icon: Icons.shopping_bag_rounded,
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                          label: 'GST Rate',
                          value: _selectedGst,
                          items: _gstRates,
                          onChanged: (v) => setState(() => _selectedGst = v)),
                    ),
                    const SizedBox(width: 12),
                    const Spacer(),
                  ],
                ),
              ], 200),

              const SizedBox(height: 20),
              _sectionHeader('Stock & Barcode'),
              const SizedBox(height: 14),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: _field(
                          controller: _stockController,
                          label: 'Opening Stock',
                          icon: Icons.inventory_2_rounded,
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                          controller: _barcodeController,
                          label: 'Barcode',
                          icon: Icons.qr_code_scanner_rounded),
                    ),
                  ],
                ),
              ], 300),

              const SizedBox(height: 32),
              AnimatedPremiumButton(
                text: 'SAVE PRODUCT',
                onPressed: _saveProduct,
                isLoading: _isSaving,
                icon: Icons.save_rounded,
              ).animate().slideY(begin: 0.2, end: 0, delay: 400.ms).fadeIn(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight),
    );
  }

  Widget _buildCard(List<Widget> children, int delay) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    ).animate().slideY(begin: 0.2, end: 0, delay: delay.ms).fadeIn();
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.royalBlue, size: 20),
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
          .toList(),
    );
  }

  Widget _unitAutocompleteField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _unitController.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _availableUnits;
        }
        return _availableUnits.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _unitController.text = selection;
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        textEditingController.addListener(() {
          _unitController.text = textEditingController.text;
        });
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Unit',
            prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.royalBlue, size: 20),
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 150),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(option, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;
}
