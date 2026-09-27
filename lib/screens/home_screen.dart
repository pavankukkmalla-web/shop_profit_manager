import 'dart:ui';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'add_stock_screen.dart';
import 'close_day_screen.dart';
import 'report_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, double> summary = {
    'purchaseSpend': 0,
    'remainingStockCost': 0,
    'sales': 0,
    'profit': 0,
    'actualReceived': 0,
  };

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  String _dateKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadSummary() async {
    final result = await DatabaseHelper.instance.getTodaySummary(
      _dateKey(),
    );

    if (!mounted) return;

    setState(() {
      summary = result;
      loading = false;
    });
  }

  Future<void> _openAddStock() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddStockScreen(),
      ),
    );

    if (result == true) {
      await loadSummary();
    }
  }

  Future<void> _openCloseBusiness() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CloseDayScreen(),
      ),
    );

    if (result == true) {
      await loadSummary();
    }
  }

  Future<void> _openTodayReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportScreen(),
      ),
    );

    await loadSummary();
  }

  Future<void> _openProfitHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryScreen(),
      ),
    );

    await loadSummary();
  }

  Future<void> _refresh() async {
    await loadSummary();
  }

  String _money(double value) {
    return '₹${value.toStringAsFixed(2)}';
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
            child: _glow(
              size: 260,
              color: const Color(0xFFB9D7FF),
            ),
          ),
          Positioned(
            top: 320,
            left: -120,
            child: _glow(
              size: 250,
              color: const Color(0xFFD8C8FF),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      30,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildHeader(),

                          const SizedBox(height: 24),

                          _buildProfitCard(),

                          const SizedBox(height: 16),

                          _buildSummaryRow(),

                          const SizedBox(height: 28),

                          _buildSectionTitle('Business'),

                          const SizedBox(height: 12),

                          _buildMainAction(
                            icon: Icons.add_rounded,
                            title: 'Add Stock',
                            subtitle: 'Add today\'s stock',
                            onTap: _openAddStock,
                          ),

                          const SizedBox(height: 12),

                          _buildMainAction(
                            icon: Icons.lock_outline_rounded,
                            title: 'Close Business',
                            subtitle:
                                'Enter remaining stock & money received',
                            onTap: _openCloseBusiness,
                          ),

                          const SizedBox(height: 28),

                          _buildSectionTitle('Insights'),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildSmallAction(
                                  icon: Icons.receipt_long_rounded,
                                  title: 'Today',
                                  subtitle: 'Report',
                                  onTap: _openTodayReport,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSmallAction(
                                  icon: Icons.history_rounded,
                                  title: 'Profit',
                                  subtitle: 'History',
                                  onTap: _openProfitHistory,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (loading)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.18),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Profit',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: Color(0xFF172033),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your business at a glance',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF687385),
              ),
            ),
          ],
        ),
        GlassContainer(
          padding: const EdgeInsets.all(11),
          borderRadius: 16,
          child: const Icon(
            Icons.storefront_rounded,
            size: 23,
            color: Color(0xFF202A38),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFIT CARD
  // ============================================================

  Widget _buildProfitCard() {
    final profit = summary['profit'] ?? 0;

    return GlassContainer(
      padding: const EdgeInsets.all(25),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 20,
                color: Color(0xFF34465F),
              ),
              SizedBox(width: 8),
              Text(
                "TODAY'S PROFIT",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFF5F6B7A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _money(profit),
              key: ValueKey(profit),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                color: Color(0xFF172033),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 17,
                  color: Color(0xFF39485D),
                ),
                SizedBox(width: 7),
                Text(
                  'PROFIT TO SEPARATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: Color(0xFF39485D),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF7B8492),
              ),
              const SizedBox(width: 7),
              Text(
                _today(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7B8492),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryRow() {
    final sales = summary['sales'] ?? 0;
    final remainingStockCost =
        summary['remainingStockCost'] ?? 0;
    final actualReceived =
        summary['actualReceived'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.payments_outlined,
                title: "TODAY'S SALES",
                value: sales,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.inventory_2_outlined,
                title: 'REMAINING STOCK COST',
                value: remainingStockCost,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildSummaryCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'AMOUNT RECEIVED',
          value: actualReceived,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required double value,
    bool fullWidth = false,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color(0xFF56657A),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: Color(0xFF7B8492),
            ),
          ),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _money(value),
              key: ValueKey(value),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF202A38),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
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
  // MAIN ACTION
  // ============================================================

  Widget _buildMainAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      borderRadius: 22,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF273244),
                  size: 23,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF273244),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF788394),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Color(0xFF7B8492),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SMALL ACTION
  // ============================================================

  Widget _buildSmallAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 23,
                color: const Color(0xFF4E5E74),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF273244),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7B8492),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BACKGROUND GLOW
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

  // ============================================================
  // DATE
  // ============================================================

  String _today() {
    final now = DateTime.now();

    final months = [
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

    return '${now.day} ${months[now.month - 1]} ${now.year}';
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
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.72),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}