import 'dart:ui';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();

  final productController = TextEditingController();
  final purchaseController = TextEditingController();
  final sellingController = TextEditingController();
  final quantityController = TextEditingController();
  final spentController = TextEditingController();

  List<Map<String, dynamic>> stock = [];

  bool loading = true;
  bool saving = false;

  int? editingStockId;
  int? editingProductId;

  @override
  void initState() {
    super.initState();
    loadStock();
  }

  String today() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadStock() async {
    final result =
        await DatabaseHelper.instance.getDailyStock(today());

    if (!mounted) return;

    setState(() {
      stock = result;
      loading = false;
    });
  }

  @override
  void dispose() {
    productController.dispose();
    purchaseController.dispose();
    sellingController.dispose();
    quantityController.dispose();
    spentController.dispose();
    super.dispose();
  }

  void clearForm() {
    productController.clear();
    purchaseController.clear();
    sellingController.clear();
    quantityController.clear();
    spentController.clear();

    setState(() {
      editingStockId = null;
      editingProductId = null;
    });
  }

  void editItem(Map<String, dynamic> item) {
    productController.text = item['name'].toString();

    purchaseController.text =
        (item['purchase_price'] as num).toString();

    sellingController.text =
        (item['selling_price'] as num).toString();

    quantityController.text =
        (item['opening_quantity'] as num).toString();

    spentController.text =
        (item['amount_spent'] as num).toString();

    setState(() {
      editingStockId = item['id'] as int;
      editingProductId = item['product_id'] as int;
    });

    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (!mounted) return;

        Scrollable.ensureVisible(
          _formKey.currentContext!,
          duration:
              const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }

  Future<void> saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = productController.text.trim();

    final purchase =
        double.tryParse(
      purchaseController.text.trim(),
    );

    final selling =
        double.tryParse(
      sellingController.text.trim(),
    );

    final quantity =
        double.tryParse(
      quantityController.text.trim(),
    );

    final spent =
        double.tryParse(
      spentController.text.trim(),
    );

    if (purchase == null ||
        selling == null ||
        quantity == null ||
        spent == null) {
      showMessage('Enter valid values');
      return;
    }

    if (purchase <= 0 ||
        selling <= 0 ||
        quantity <= 0 ||
        spent < 0) {
      showMessage('Enter valid values');
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      // EDIT EXISTING ITEM
      if (editingStockId != null &&
          editingProductId != null) {
        await DatabaseHelper.instance.updateProduct(
          editingProductId!,
          {
            'name': name,
            'purchase_price': purchase,
            'selling_price': selling,
          },
        );

        await DatabaseHelper.instance.updateDailyStock(
          editingStockId!,
          openingQuantity: quantity,
          amountSpent: spent,
        );

        showMessage('Item updated successfully');
      }

      // ADD COMPLETELY NEW ITEM
      else {
        final productId =
            await DatabaseHelper.instance.insertProduct({
          'name': name,
          'purchase_price': purchase,
          'selling_price': selling,
        });

        await DatabaseHelper.instance.insertDailyStock({
          'product_id': productId,
          'date': today(),
          'opening_quantity': quantity,
          'remaining_quantity': quantity,
          'amount_spent': spent,
        });

        showMessage('$name added to today\'s stock');
      }

      clearForm();
      await loadStock();
    } catch (e) {
      showMessage('Could not save item');
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
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
            'Use this if the item was added by mistake.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
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

    if (editingStockId == item['id']) {
      clearForm();
    }

    await loadStock();

    showMessage('$name removed');
  }

  void showMessage(String message) {
    if (!mounted) return;

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
      backgroundColor:
          const Color(0xFFF3F6FA),
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
            child: Form(
              key: _formKey,
              child: ListView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      glassIcon(
                        Icons.arrow_back_rounded,
                        () => Navigator.pop(
                          context,
                          true,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Text(
                          'Add Stock',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),

                      // + NEW ITEM
                      Material(
                        color:
                            const Color(0xFF27364A),
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        child: InkWell(
                          onTap: clearForm,
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
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
                    'Today\'s Stock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Add new items or edit today\'s stock.',
                    style: TextStyle(
                      color:
                          Color(0xFF788394),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (loading)
                    const Center(
                      child: Padding(
                        padding:
                            EdgeInsets.all(30),
                        child:
                            CircularProgressIndicator(),
                      ),
                    )
                  else
                    ...stock.map(
                      (item) =>
                          _stockCard(item),
                    ),

                  const SizedBox(height: 12),

                  // FORM
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 18,
                        sigmaY: 18,
                      ),
                      child: Container(
                        padding:
                            const EdgeInsets.all(20),
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.48,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            26,
                          ),
                          border: Border.all(
                            color: Colors.white
                                .withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              editingStockId ==
                                      null
                                  ? 'Add New Item'
                                  : 'Edit Item',
                              style:
                                  const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),

                            const SizedBox(
                                height: 18),

                            field(
                              'Product Name',
                              'e.g. Lady\'s Finger',
                              productController,
                              Icons
                                  .shopping_basket_outlined,
                              false,
                            ),

                            field(
                              'Actual Purchase Price',
                              '₹ per kg',
                              purchaseController,
                              Icons
                                  .shopping_cart_outlined,
                              true,
                            ),

                            field(
                              'Selling Price',
                              '₹ per kg',
                              sellingController,
                              Icons.sell_outlined,
                              true,
                            ),

                            field(
                              'Opening Quantity',
                              'kg',
                              quantityController,
                              Icons
                                  .inventory_2_outlined,
                              true,
                            ),

                            field(
                              'Amount Spent',
                              'Total amount spent',
                              spentController,
                              Icons
                                  .account_balance_wallet_outlined,
                              true,
                            ),

                            const SizedBox(
                                height: 5),

                            SizedBox(
                              width:
                                  double.infinity,
                              height: 56,
                              child: Material(
                                color:
                                    const Color(
                                  0xFF27364A,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
                                ),
                                child: InkWell(
                                  onTap: saving
                                      ? null
                                      : saveItem,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),
                                  child: Center(
                                    child: saving
                                        ? const CircularProgressIndicator(
                                            color:
                                                Colors.white,
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                editingStockId ==
                                                        null
                                                    ? Icons
                                                        .add_rounded
                                                    : Icons
                                                        .save_rounded,
                                                color:
                                                    Colors.white,
                                              ),
                                              const SizedBox(
                                                  width:
                                                      8),
                                              Text(
                                                editingStockId ==
                                                        null
                                                    ? 'Add Item'
                                                    : 'Update Item',
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.white,
                                                  fontSize:
                                                      16,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _stockCard(
    Map<String, dynamic> item,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 16,
            sigmaY: 16,
          ),
          child: Container(
            padding:
                const EdgeInsets.all(17),
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.52),
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white
                    .withValues(alpha: 0.72),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color:
                      Color(0xFF40536B),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        item['name']
                            .toString(),
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                          height: 4),
                      Text(
                        '₹${item['purchase_price']} → '
                        '₹${item['selling_price']} / kg',
                        style:
                            const TextStyle(
                          color: Color(
                              0xFF788394),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(
                          height: 3),
                      Text(
                        '${item['opening_quantity']} kg • '
                        '₹${item['amount_spent']} spent',
                        style:
                            const TextStyle(
                          color: Color(
                              0xFF788394),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () =>
                      editItem(item),
                  icon: const Icon(
                    Icons.edit_rounded,
                  ),
                ),

                IconButton(
                  onPressed: () =>
                      removeItem(item),
                  icon: const Icon(
                    Icons
                        .delete_outline_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget field(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon,
    bool number,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 15,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF56657A),
            ),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            keyboardType: number
                ? const TextInputType
                    .numberWithOptions(
                    decimal: true,
                  )
                : TextInputType.text,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Required';
              }

              if (number &&
                  double.tryParse(
                        value.trim(),
                      ) ==
                      null) {
                return 'Enter a valid number';
              }

              return null;
            },
            decoration:
                InputDecoration(
              hintText: hint,
              prefixIcon:
                  Icon(icon),
              filled: true,
              fillColor: Colors.white
                  .withValues(
                alpha: 0.4,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  17,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget glassIcon(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white
          .withValues(alpha: 0.5),
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
      decoration:
          BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(
          alpha: 0.35,
        ),
      ),
    );
  }
}

