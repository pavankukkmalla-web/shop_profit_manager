class DailyReport {
  final String date;

  final double totalPurchaseSpend;
  final double totalSales;
  final double totalCostOfGoodsSold;
  final double totalProfit;
  final double remainingStockValue;

  final double actualMoneyReceived;

  DailyReport({
    required this.date,
    required this.totalPurchaseSpend,
    required this.totalSales,
    required this.totalCostOfGoodsSold,
    required this.totalProfit,
    required this.remainingStockValue,
    required this.actualMoneyReceived,
  });

  double get salesDifference {
    return actualMoneyReceived - totalSales;
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'total_purchase_spend': totalPurchaseSpend,
      'total_sales': totalSales,
      'total_cost_of_goods_sold': totalCostOfGoodsSold,
      'total_profit': totalProfit,
      'remaining_stock_value': remainingStockValue,
      'actual_money_received': actualMoneyReceived,
    };
  }

  factory DailyReport.fromMap(Map<String, dynamic> map) {
    return DailyReport(
      date: map['date'],
      totalPurchaseSpend: map['total_purchase_spend'],
      totalSales: map['total_sales'],
      totalCostOfGoodsSold: map['total_cost_of_goods_sold'],
      totalProfit: map['total_profit'],
      remainingStockValue: map['remaining_stock_value'],
      actualMoneyReceived: map['actual_money_received'],
    );
  }
}