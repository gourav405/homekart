class Supplier {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? gstNumber;
  final String? address;
  final bool isActive;
  final DateTime? createdAt;

  Supplier({this.id, required this.name, this.phone, this.email, this.gstNumber, this.address, this.isActive = true, this.createdAt});

  factory Supplier.fromMap(Map<String, String?> map) => Supplier(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    name: map['name'] ?? '',
    phone: map['phone'],
    email: map['email'],
    gstNumber: map['gst_number'],
    address: map['address'],
    isActive: map['is_active'] != '0',
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']!) : null,
  );
}
