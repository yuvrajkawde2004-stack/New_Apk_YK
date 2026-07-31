// Model: Customer
class Customer {
  final int? id;
  final String name;
  final String? phone;
  final double outstandingBalance;
  final String? notes;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.outstandingBalance = 0,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'outstanding_balance': outstandingBalance,
        'notes': notes,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'],
        name: map['name'],
        phone: map['phone'],
        outstandingBalance: (map['outstanding_balance'] as num?)?.toDouble() ?? 0,
        notes: map['notes'],
      );
}
