class Product {
  final int? id;
  final String name;
  final double purchasePrice;
  final double sellingPrice;

  Product({
    this.id,
    required this.name,
    required this.purchasePrice,
    required this.sellingPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      purchasePrice: map['purchase_price'],
      sellingPrice: map['selling_price'],
    );
  }
}