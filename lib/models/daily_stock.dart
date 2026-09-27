class DailyStock {
  final int? id;
  final int productId;
  final String date;
  final double openingQuantity;
  final double remainingQuantity;

  DailyStock({
    this.id,
    required this.productId,
    required this.date,
    required this.openingQuantity,
    required this.remainingQuantity,
  });

  double get soldQuantity {
    return openingQuantity - remainingQuantity;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'date': date,
      'opening_quantity': openingQuantity,
      'remaining_quantity': remainingQuantity,
    };
  }

  factory DailyStock.fromMap(Map<String, dynamic> map) {
    return DailyStock(
      id: map['id'],
      productId: map['product_id'],
      date: map['date'],
      openingQuantity: map['opening_quantity'],
      remainingQuantity: map['remaining_quantity'],
    );
  }
}