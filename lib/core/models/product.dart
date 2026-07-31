// Model: Product
class Product {
  final int? id;
  final String name;
  final String? category;
  final String? brand;
  final String? color;
  final String? size;
  final double mrp;
  final double sellingPrice;
  final double purchasePrice;
  final double gst;
  final String? barcode;
  final int stock;
  final int lowStockThreshold;
  final String? imagePath;

  const Product({
    this.id,
    required this.name,
    this.category,
    this.brand,
    this.color,
    this.size,
    required this.mrp,
    required this.sellingPrice,
    required this.purchasePrice,
    this.gst = 0,
    this.barcode,
    required this.stock,
    this.lowStockThreshold = 5,
    this.imagePath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'brand': brand,
        'color': color,
        'size': size,
        'mrp': mrp,
        'selling_price': sellingPrice,
        'purchase_price': purchasePrice,
        'gst': gst,
        'barcode': barcode,
        'stock': stock,
        'low_stock_threshold': lowStockThreshold,
        'image_path': imagePath,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'],
        name: map['name'],
        category: map['category'],
        brand: map['brand'],
        color: map['color'],
        size: map['size'],
        mrp: (map['mrp'] as num).toDouble(),
        sellingPrice: (map['selling_price'] as num).toDouble(),
        purchasePrice: (map['purchase_price'] as num).toDouble(),
        gst: (map['gst'] as num).toDouble(),
        barcode: map['barcode'],
        stock: map['stock'],
        lowStockThreshold: map['low_stock_threshold'] ?? 5,
        imagePath: map['image_path'],
      );

  Product copyWith({
    int? id,
    String? name,
    String? category,
    String? brand,
    String? color,
    String? size,
    double? mrp,
    double? sellingPrice,
    double? purchasePrice,
    double? gst,
    String? barcode,
    int? stock,
    int? lowStockThreshold,
    String? imagePath,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        brand: brand ?? this.brand,
        color: color ?? this.color,
        size: size ?? this.size,
        mrp: mrp ?? this.mrp,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        gst: gst ?? this.gst,
        barcode: barcode ?? this.barcode,
        stock: stock ?? this.stock,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        imagePath: imagePath ?? this.imagePath,
      );

  bool get isLowStock => stock <= lowStockThreshold;
  bool get isOutOfStock => stock == 0;
}
