import 'dart:ui';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'add_stock_screen.dart';

class CloseDayScreen extends StatefulWidget {
  const CloseDayScreen({super.key});

  @override
  State<CloseDayScreen> createState() => _CloseDayScreenState();
}

class _CloseDayScreenState extends State<CloseDayScreen> {
  List<Map<String, dynamic>> stock = [];

  final receivedController = TextEditingController();

  final Map<int, TextEditingController> remainingControllers = {};

  bool loading = true;
  bool calculating = false;

  String today() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    loadStock();
  }

  Future<void> loadStock() async {
    for (final controller in remainingControllers.values) {
      controller.dispose();
    }

    remainingControllers.clear();

    final result =
        await DatabaseHelper.instance.getDailyStock(today());

    for (final item in result) {
      final id = item['id'] as int;

      remainingControllers[id] = TextEditingController(
        text: (item['remaining_quantity'] as num).toString(),
      );
    }

    if (!mounted) return;

    setState(() {
      stock = result;
      loading = false;
    });
  }

  @override
  void dispose() {
    receivedController.dispose();

    for (final controller in remainingControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> markNoStock(
    Map<String, dynamic> item,
  ) async {
    final id = item['id'] as int;

    remainingControllers[id]?.text = '0';

    await DatabaseHelper.instance.updateRemainingQuantity(id, 0);

    await loadStock();

    showMessage(
      '${item['name']} marked as no stock',
    );
  }

  Future<void> removeItem(
    Map<String, dynamic> item,
  ) async {
    final name = item['name'].toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Item?'),
          content: Text(
            'Remove $name from today\'s stock?\n\n'
            'Use this only if the item was added by mistake.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await DatabaseHelper.instance.deleteDailyStock(
      item['id'] as int,
    );

    await loadStock();

    showMessage(
      '$name removed from today\'s stock',
    );
  }

  Future<void> calculateAndClose() async {
    final received = double.tryParse(
      receivedController.text.trim(),
    );

    if (received == null || received < 0) {
      showMessage(
        'Enter a valid amount received',
      );
      return;
    }

    // Validate EVERYTHING first.
    for (final item in stock) {
      final id = item['id'] as int;

      final opening =
          (item['opening_quantity'] as num).toDouble();

      final remaining = double.tryParse(
        remainingControllers[id]!.text.trim(),
      );

      if (remaining == null ||
          remaining < 0 ||
          remaining > opening) {
        showMessage(
          'Check remaining quantity for ${item['name']}',
        );
        return;
      }
    }

    setState(() {
      calculating = true;
    });

    double totalPurchaseSpend = 0;
    double totalCalculatedSales = 0;
    double totalCostOfGoodsSold = 0;
    double remainingStockValue = 0;

    try {
      for (final item in stock) {
        final id = item['id'] as int;

        final opening =
            (item['opening_quantity'] as num).toDouble();

        final purchase =
            (item['purchase_price'] as num).toDouble();

        final selling =
            (item['selling_price'] as num).toDouble();

        final spent =
            (item['amount_spent'] as num).toDouble();

        final remaining = double.parse(
          remainingControllers[id]!.text.trim(),
        );

        await DatabaseHelper.instance.updateRemainingQuantity(
          id,
          remaining,
        );

        // ------------------------------------------------
        // SOLD QUANTITY
        // ------------------------------------------------
        final sold = opening - remaining;

        // ------------------------------------------------
        // COST OF GOODS SOLD
        // Only the stock that was actually sold is today's
        // cost.
        // ------------------------------------------------
        final costOfGoodsSold = sold * purchase;

        // ------------------------------------------------
        // CALCULATED SALES
        // This is used only to compare with actual money
        // received.
        // ------------------------------------------------
        final calculatedSales = sold * selling;

        // ------------------------------------------------
        // REMAINING STOCK COST
        // Unsold stock remains inventory.
        // ------------------------------------------------
        final remainingCost = remaining * purchase;

        totalPurchaseSpend += spent;
        totalCostOfGoodsSold += costOfGoodsSold;
        totalCalculatedSales += calculatedSales;
        remainingStockValue += remainingCost;
      }

      // ------------------------------------------------
      // IMPORTANT:
      //
      // PROFIT TO SEPARATE
      // = ACTUAL AMOUNT RECEIVED
      //   - COST OF GOODS SOLD
      //
      // We DO NOT use calculated sales here.
      // ------------------------------------------------
      final totalProfit =
          received - totalCostOfGoodsSold;

      // ------------------------------------------------
      // Save today's report
      // ------------------------------------------------
      await DatabaseHelper.instance.insertDailyReport({
        'date': today(),
        'total_purchase_spend': totalPurchaseSpend,

        // Calculated sales are stored for reconciliation.
        'total_sales': totalCalculatedSales,

        'total_cost_of_goods_sold':
            totalCostOfGoodsSold,

        // Actual profit calculation.
        'total_profit': totalProfit,

        'remaining_stock_value':
            remainingStockValue,

        'actual_money_received': received,
      });

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      showMessage(
        'Could not close business',
      );
    } finally {
      if (mounted) {
        setState(() {
          calculating = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: glow(
              260,
              const Color(0xFFB9D7FF),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -120,
            child: glow(
              250,
              const Color(0xFFD8C8FF),
            ),
          ),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    glassIcon(
                      Icons.arrow_back_rounded,
                      () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Close Business',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    // ADD ITEM BUBBLE
                    Material(
                      color: const Color(0xFF27364A),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AddStockScreen(),
                            ),
                          );

                          await loadStock();
                        },
                        borderRadius:
                            BorderRadius.circular(18),
                        child: const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                const Text(
                  'Remaining Stock',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Edit, remove, or mark items with no stock.',
                  style: TextStyle(
                    color: Color(0xFF788394),
                  ),
                ),

                const SizedBox(height: 20),

                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (stock.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withValues(alpha: 0.5),
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 45,
                          color: Color(0xFF788394),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No stock added today.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...stock.map(
                    (item) => _productCard(item),
                  ),

                const SizedBox(height: 16),

                if (stock.isNotEmpty) _receivedCard(),

                const SizedBox(height: 20),

                if (stock.isNotEmpty)
                  SizedBox(
                    height: 58,
                    child: Material(
                      color: const Color(0xFF27364A),
                      borderRadius:
                          BorderRadius.circular(20),
                      child: InkWell(
                        onTap: calculating
                            ? null
                            : calculateAndClose,
                        borderRadius:
                            BorderRadius.circular(20),
                        child: Center(
                          child: calculating
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Calculate & Close Business',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(
    Map<String, dynamic> item,
  ) {
    final id = item['id'] as int;

    final opening =
        (item['opening_quantity'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(alpha: 0.48),
              borderRadius:
                  BorderRadius.circular(24),
              border: Border.all(
                color:
                    Colors.white.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'].toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                      ),
                      onSelected: (value) async {
                        if (value == 'no_stock') {
                          await markNoStock(item);
                        }

                        if (value == 'remove') {
                          await removeItem(item);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'no_stock',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .inventory_2_outlined,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Mark No Stock',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .delete_outline_rounded,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Remove Item',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  'Opening: $opening kg',
                  style: const TextStyle(
                    color: Color(0xFF788394),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller:
                      remainingControllers[id],
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        'Remaining Quantity',
                    suffixText: 'kg',
                    prefixIcon: const Icon(
                      Icons.inventory_2_outlined,
                    ),
                    filled: true,
                    fillColor:
                        Colors.white.withValues(
                      alpha: 0.4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed: () {
                          remainingControllers[id]
                              ?.text = '0';
                        },
                        icon: const Icon(
                          Icons
                              .remove_shopping_cart_outlined,
                        ),
                        label: const Text(
                          'No Stock',
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed: () {
                          remainingControllers[id]
                                  ?.text =
                              item[
                                      'remaining_quantity']
                                  .toString();
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                        ),
                        label: const Text(
                          'Reset',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receivedCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                Colors.white.withValues(alpha: 0.48),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color:
                  Colors.white.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'ACTUAL MONEY RECEIVED',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Enter the actual cash/payment received from today\'s sales.',
                style: TextStyle(
                  color: Color(0xFF788394),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: receivedController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount Received',
                  prefixText: '₹ ',
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white.withValues(
                    alpha: 0.4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget glassIcon(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color:
          Colors.white.withValues(alpha: 0.5),
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon),
        ),
      ),
    );
  }

  Widget glow(
    double size,
    Color color,
  ) {
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

