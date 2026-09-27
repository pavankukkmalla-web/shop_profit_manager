import 'package:flutter_test/flutter_test.dart';
import 'package:shop_profit_manager/main.dart';

void main() {
  testWidgets('Shop Profit Manager loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ShopProfitManager());

    expect(find.text('Shop Profit Manager'), findsOneWidget);
    expect(find.text("TODAY'S PROFIT"), findsOneWidget);
    expect(find.text('₹0.00'), findsOneWidget);
  });
}