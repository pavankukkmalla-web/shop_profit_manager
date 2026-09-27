import 'dart:ui';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
    });

    final data =
        await DatabaseHelper.instance.getDailyReports();

    if (!mounted) return;

    setState(() {
      reports = data;
      isLoading = false;
    });
  }

  String _money(dynamic value) {
    final amount =
        (value as num?)?.toDouble() ?? 0;

    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);

      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text(
          'Profit History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : reports.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      30,
                    ),
                    itemCount: reports.length,
                    itemBuilder:
                        (context, index) {
                      return _buildHistoryCard(
                        reports[index],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildHistoryCard(
    Map<String, dynamic> report,
  ) {
    final profit =
        (report['total_profit'] as num?)
                ?.toDouble() ??
            0;

    final calculatedSales =
        (report['total_sales'] as num?)
                ?.toDouble() ??
            0;

    final received =
        (report['actual_money_received']
                    as num?)
                ?.toDouble() ??
            0;

    final purchaseSpend =
        (report['total_purchase_spend']
                    as num?)
                ?.toDouble() ??
            0;

    final costOfGoodsSold =
        (report['total_cost_of_goods_sold']
                    as num?)
                ?.toDouble() ??
            0;

    final remainingStock =
        (report['remaining_stock_value']
                    as num?)
                ?.toDouble() ??
            0;

    // Used only for reconciliation.
    final salesDifference =
        received - calculatedSales;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 18),

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(24),

        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ),

          child: Container(
            padding:
                const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.82),

              borderRadius:
                  BorderRadius.circular(24),

              border: Border.all(
                color: Colors.white,
                width: 1.2,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset:
                      const Offset(0, 8),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // DATE
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(10),
                      decoration:
                          BoxDecoration(
                        color: Colors.blue
                            .withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .calendar_today_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        _formatDate(
                          report['date']
                                  ?.toString() ??
                              '',
                        ),
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // PROFIT
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(18),

                  decoration:
                      BoxDecoration(
                    color: profit >= 0
                        ? Colors.green
                            .withValues(
                            alpha: 0.10,
                          )
                        : Colors.red
                            .withValues(
                            alpha: 0.10,
                          ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),

                  child: Column(
                    children: [
                      const Text(
                        'PROFIT TO SEPARATE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _money(profit),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight:
                              FontWeight.bold,
                          color: profit >= 0
                              ? Colors.green
                                  .shade700
                              : Colors.red
                                  .shade700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Actual Amount Received − Cost of Goods Sold',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // RECEIVED / CALCULATED SALES
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        title:
                            'ACTUAL RECEIVED',
                        value:
                            _money(received),
                        icon: Icons
                            .payments_rounded,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _metric(
                        title:
                            'CALCULATED SALES',
                        value:
                            _money(
                          calculatedSales,
                        ),
                        icon: Icons
                            .point_of_sale_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // PURCHASE / COGS
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        title:
                            'PURCHASE SPEND',
                        value:
                            _money(
                          purchaseSpend,
                        ),
                        icon: Icons
                            .shopping_cart_rounded,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _metric(
                        title:
                            'COST OF SOLD STOCK',
                        value:
                            _money(
                          costOfGoodsSold,
                        ),
                        icon: Icons
                            .inventory_2_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // REMAINING STOCK
                _metric(
                  title:
                      'REMAINING STOCK COST',
                  value:
                      _money(
                    remainingStock,
                  ),
                  icon:
                      Icons.inventory_rounded,
                ),

                const SizedBox(height: 18),

                // RECONCILIATION
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(14),

                  decoration:
                      BoxDecoration(
                    color:
                        salesDifference
                                    .abs() <
                                0.01
                            ? Colors.green
                                .withValues(
                                alpha: 0.08,
                              )
                            : Colors.orange
                                .withValues(
                                alpha: 0.10,
                              ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Icon(
                        salesDifference
                                    .abs() <
                                0.01
                            ? Icons
                                .check_circle_rounded
                            : Icons
                                .warning_rounded,

                        color:
                            salesDifference
                                        .abs() <
                                    0.01
                                ? Colors.green
                                : Colors.orange,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              salesDifference
                                          .abs() <
                                      0.01
                                  ? 'SALES MATCHED'
                                  : 'SALES DIFFERENCE',

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              salesDifference
                                          .abs() <
                                      0.01
                                  ? 'Actual amount received matches calculated sales.'
                                  : 'Actual received differs from calculated sales by ${_money(salesDifference.abs())}.',

                              style: TextStyle(
                                color: Colors
                                    .grey
                                    .shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // PROFIT FORMULA
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(14),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      const Text(
                        'PROFIT CALCULATION',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 13,
                          letterSpacing:
                              0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${_money(received)} − '
                        '${_money(costOfGoodsSold)} = '
                        '${_money(profit)}',

                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Actual Amount Received − Cost of Goods Sold = Profit',
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Calculated sales are shown separately for reconciliation only.',
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metric({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(8),

            decoration:
                BoxDecoration(
              color: Colors.blue
                  .withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(10),
            ),

            child: Icon(
              icon,
              size: 19,
              color: Colors.blue,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Container(
          padding:
              const EdgeInsets.all(28),

          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(24),

            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.05),
                blurRadius: 18,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                Icons.history_rounded,
                size: 60,
                color:
                    Colors.grey.shade400,
              ),

              const SizedBox(height: 16),

              const Text(
                'No Profit History',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your completed daily profit reports will appear here.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

