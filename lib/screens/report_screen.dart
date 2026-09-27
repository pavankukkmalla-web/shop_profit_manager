import 'dart:ui';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Map<String, dynamic>? report;
  List<Map<String, dynamic>> stockItems = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  String _dateKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadReport() async {
    final date = _dateKey();

    final result =
        await DatabaseHelper.instance.getDailyReport(date);

    final stock =
        await DatabaseHelper.instance.getDailyStock(date);

    if (!mounted) return;

    setState(() {
      report = result;
      stockItems = stock;
      loading = false;
    });
  }

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Today's Report",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF172033),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _glow(
              size: 250,
              color: const Color(0xFFB9D7FF),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -120,
            child: _glow(
              size: 250,
              color: const Color(0xFFD8C8FF),
            ),
          ),
          SafeArea(
            top: false,
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReport,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent:
                            AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            30,
                          ),
                          sliver: SliverList(
                            delegate:
                                SliverChildListDelegate(
                              [
                                if (report == null)
                                  _buildNotClosed()
                                else ...[
                                  _buildDateHeader(),

                                  const SizedBox(height: 18),

                                  _buildProfitCard(),

                                  const SizedBox(height: 16),

                                  _buildFinancialSummary(),

                                  const SizedBox(height: 28),

                                  _buildSectionTitle(
                                    'Stock Details',
                                  ),

                                  const SizedBox(height: 12),

                                  ...stockItems.map(
                                    _buildProductCard,
                                  ),

                                  const SizedBox(height: 24),

                                  _buildReconciliationCard(),

                                  const SizedBox(height: 18),

                                  _buildProfitFormulaCard(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOT CLOSED
  // ============================================================

  Widget _buildNotClosed() {
    return GlassContainer(
      padding: const EdgeInsets.all(28),
      borderRadius: 28,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 34,
              color: Color(0xFF526176),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Business Not Closed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Calculate & Close the business first to generate today\'s report.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF6D7888),
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: _loadReport,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Refresh Report',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  Widget _buildDateHeader() {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 17,
          color: Color(0xFF657286),
        ),
        const SizedBox(width: 8),
        Text(
          _formattedDate(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF657286),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color:
                Colors.white.withValues(alpha: 0.55),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: const Text(
            'CLOSED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF526176),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFIT
  // ============================================================

  Widget _buildProfitCard() {
    final profit =
        _number(report?['total_profit']);

    final received =
        _number(report?['actual_money_received']);

    final cost =
        _number(report?['total_cost_of_goods_sold']);

    return GlassContainer(
      padding: const EdgeInsets.all(25),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 21,
                color: Color(0xFF34465F),
              ),
              SizedBox(width: 8),
              Text(
                'PROFIT TO SEPARATE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Color(0xFF5F6B7A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _money(profit),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '${_money(received)} actual received − '
            '${_money(cost)} cost of goods sold',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF788394),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FINANCIAL SUMMARY
  // ============================================================

  Widget _buildFinancialSummary() {
    final purchaseSpend =
        _number(report?['total_purchase_spend']);

    final sales =
        _number(report?['total_sales']);

    final cost =
        _number(
      report?['total_cost_of_goods_sold'],
    );

    final remaining =
        _number(
      report?['remaining_stock_value'],
    );

    final received =
        _number(
      report?['actual_money_received'],
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetric(
                icon:
                    Icons.shopping_cart_outlined,
                title: 'PURCHASE SPEND',
                value: purchaseSpend,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetric(
                icon:
                    Icons.point_of_sale_outlined,
                title: "CALCULATED SALES",
                value: sales,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMetric(
                icon:
                    Icons.receipt_long_outlined,
                title: 'COST OF GOODS SOLD',
                value: cost,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetric(
                icon:
                    Icons.inventory_2_outlined,
                title: 'REMAINING STOCK COST',
                value: remaining,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildMetric(
          icon:
              Icons.account_balance_wallet_outlined,
          title: 'ACTUAL AMOUNT RECEIVED',
          value: received,
        ),
      ],
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String title,
    required double value,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(17),
      borderRadius: 21,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFF56657A),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.55,
              color: Color(0xFF7B8492),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _money(value),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF202A38),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard(
    Map<String, dynamic> item,
  ) {
    final name =
        item['name']?.toString() ?? 'Product';

    final purchasePrice =
        _number(item['purchase_price']);

    final sellingPrice =
        _number(item['selling_price']);

    final opening =
        _number(item['opening_quantity']);

    final remaining =
        _number(item['remaining_quantity']);

    final sold =
        opening - remaining;

    final costOfGoodsSold =
        sold * purchasePrice;

    final calculatedSales =
        sold * sellingPrice;

    // This is NOT the actual profit.
    // Actual profit is calculated from the total
    // amount received for the whole day.
    final expectedMargin =
        calculatedSales - costOfGoodsSold;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: 22,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.55),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
                    color:
                        Color(0xFF526176),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF273244),
                    ),
                  ),
                ),
                Text(
                  _money(expectedMargin),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF273244),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            const Text(
              'EXPECTED MARGIN',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF8892A0),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _productValue(
                    'PURCHASE',
                    '${_money(purchasePrice)}/kg',
                  ),
                ),
                Expanded(
                  child: _productValue(
                    'SELLING',
                    '${_money(sellingPrice)}/kg',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _productValue(
                    'OPENING',
                    '${_quantity(opening)} kg',
                  ),
                ),
                Expanded(
                  child: _productValue(
                    'SOLD',
                    '${_quantity(sold)} kg',
                  ),
                ),
                Expanded(
                  child: _productValue(
                    'REMAINING',
                    '${_quantity(remaining)} kg',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white
                    .withValues(alpha: 0.38),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Calculated Sales: '
                      '${_money(calculatedSales)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(0xFF596679),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'COGS: '
                      '${_money(costOfGoodsSold)}',
                      textAlign:
                          TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(0xFF596679),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productValue(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF8892A0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF39485D),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECONCILIATION
  // ============================================================

  Widget _buildReconciliationCard() {
    final sales =
        _number(report?['total_sales']);

    final received =
        _number(report?['actual_money_received']);

    final difference =
        received - sales;

    final isMatched =
        difference.abs() < 0.01;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Row(
        children: [
          Icon(
            isMatched
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: const Color(0xFF526176),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  isMatched
                      ? 'SALES MATCHED'
                      : 'SALES DIFFERENCE',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 0.7,
                    color:
                        Color(0xFF596679),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMatched
                      ? 'Actual amount received matches calculated sales.'
                      : 'Actual received differs from calculated sales by ${_money(difference.abs())}.',
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF7B8492),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFIT FORMULA
  // ============================================================

  Widget _buildProfitFormulaCard() {
    final received =
        _number(report?['actual_money_received']);

    final cost =
        _number(
      report?['total_cost_of_goods_sold'],
    );

    final profit =
        _number(report?['total_profit']);

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'PROFIT CALCULATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: Color(0xFF596679),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '${_money(received)} − '
            '${_money(cost)} = '
            '${_money(profit)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF273244),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Actual Amount Received − Cost of Goods Sold = Profit',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7B8492),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Calculated sales are used only to compare expected sales with the actual amount received.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF8892A0),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF273244),
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formattedDate() {
    final now = DateTime.now();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${now.day} '
        '${months[now.month - 1]} '
        '${now.year}';
  }

  // ============================================================
  // GLOW
  // ============================================================

  Widget _glow({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.35),
      ),
    );
  }
}

// ============================================================
// GLASS CONTAINER
// ============================================================

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding =
        const EdgeInsets.all(20),
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(alpha: 0.48),
            borderRadius:
                BorderRadius.circular(
              borderRadius,
            ),
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: 0.72),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.04),
                blurRadius: 25,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

