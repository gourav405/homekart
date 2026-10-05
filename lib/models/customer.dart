class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? gstNumber;
  final String? address;
  final String? state;
  final DateTime? createdAt;

  Customer({this.id, required this.name, this.phone, this.email, this.gstNumber, this.address, this.state, this.createdAt});

  factory Customer.fromMap(Map<String, String?> map) => Customer(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    name: map['name'] ?? '',
    phone: map['phone'],
    email: map['email'],
    gstNumber: map['gst_number'],
    address: map['address'],
    state: map['state'],
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']!) : null,
  );
}
