class ProfitCalculation {
  final double soldQuantity;
  final double costOfGoodsSold;
  final double salesAmount;
  final double profit;
  final double remainingStockValue;

  ProfitCalculation({
    required this.soldQuantity,
    required this.costOfGoodsSold,
    required this.salesAmount,
    required this.profit,
    required this.remainingStockValue,
  });
}

class ProfitCalculator {
  static ProfitCalculation calculate({
    required double purchasePrice,
    required double sellingPrice,
    required double openingQuantity,
    required double remainingQuantity,
  }) {
    final soldQuantity = openingQuantity - remainingQuantity;

    final costOfGoodsSold = soldQuantity * purchasePrice;

    final salesAmount = soldQuantity * sellingPrice;

    final profit = salesAmount - costOfGoodsSold;

    final remainingStockValue = remainingQuantity * purchasePrice;

    return ProfitCalculation(
      soldQuantity: soldQuantity,
      costOfGoodsSold: costOfGoodsSold,
      salesAmount: salesAmount,
      profit: profit,
      remainingStockValue: remainingStockValue,
    );
  }
}