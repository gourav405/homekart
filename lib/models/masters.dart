class ProductType {
  final int? id;
  final String name;
  final int? subcategoryId;
  final bool isActive;

  ProductType({this.id, required this.name, this.subcategoryId, this.isActive = true});

  factory ProductType.fromMap(Map<String, String?> map) => ProductType(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    name: map['name'] ?? '',
    subcategoryId: map['subcategory_id'] != null ? int.tryParse(map['subcategory_id']!) : null,
    isActive: map['is_active'] != '0',
  );
}

class Unit {
  final int? id;
  final String name;
  final String symbol;

  Unit({this.id, required this.name, required this.symbol});

  factory Unit.fromMap(Map<String, String?> map) => Unit(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    name: map['name'] ?? '',
    symbol: map['symbol'] ?? '',
  );
}

class PaintColor {
  final int? id;
  final String name;
  final String? code;
  final String? hexCode;
  final bool isActive;

  PaintColor({this.id, required this.name, this.code, this.hexCode, this.isActive = true});

  factory PaintColor.fromMap(Map<String, String?> map) => PaintColor(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    name: map['name'] ?? '',
    code: map['code'],
    hexCode: map['hex_code'],
    isActive: map['is_active'] != '0',
  );
}

class TaxRate {
  final int? id;
  final String name;
  final double percentage;
  final bool isActive;

  TaxRate({this.id, required this.name, required this.percentage, this.isActive = true});

  factory TaxRate.fromMap(Map<String, String?> map) => TaxRate(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    name: map['name'] ?? '',
    percentage: map['percentage'] != null ? double.parse(map['percentage']!) : 0,
    isActive: map['is_active'] != '0',
  );
}
