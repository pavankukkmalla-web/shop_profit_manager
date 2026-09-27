import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return instance;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'shop_profit_manager.db',
    );

    return openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        purchase_price REAL NOT NULL,
        selling_price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        opening_quantity REAL NOT NULL,
        remaining_quantity REAL NOT NULL,
        amount_spent REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        total_purchase_spend REAL NOT NULL,
        total_sales REAL NOT NULL,
        total_cost_of_goods_sold REAL NOT NULL,
        total_profit REAL NOT NULL,
        remaining_stock_value REAL NOT NULL,
        actual_money_received REAL NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE daily_stock
        ADD COLUMN amount_spent REAL NOT NULL DEFAULT 0
      ''');
    }
  }

  // ============================================================
  // PRODUCT
  // ============================================================

  Future<int> insertProduct(
    Map<String, dynamic> product,
  ) async {
    final db = await database;

    return db.insert(
      'products',
      product,
    );
  }

  Future<int> updateProduct(
    int productId,
    Map<String, dynamic> product,
  ) async {
    final db = await database;

    return db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // ============================================================
  // DAILY STOCK
  // ============================================================

  Future<int> insertDailyStock(
    Map<String, dynamic> stock,
  ) async {
    final db = await database;

    return db.insert(
      'daily_stock',
      stock,
    );
  }

  Future<List<Map<String, dynamic>>> getDailyStock(
    String date,
  ) async {
    final db = await database;

    return db.rawQuery('''
      SELECT
        daily_stock.id,
        daily_stock.product_id,
        daily_stock.date,
        daily_stock.opening_quantity,
        daily_stock.remaining_quantity,
        daily_stock.amount_spent,
        products.name,
        products.purchase_price,
        products.selling_price
      FROM daily_stock
      INNER JOIN products
        ON daily_stock.product_id = products.id
      WHERE daily_stock.date = ?
      ORDER BY daily_stock.id ASC
    ''', [date]);
  }

  Future<int> updateDailyStock(
    int stockId, {
    required double openingQuantity,
    required double amountSpent,
  }) async {
    final db = await database;

    return db.update(
      'daily_stock',
      {
        'opening_quantity': openingQuantity,
        'amount_spent': amountSpent,
      },
      where: 'id = ?',
      whereArgs: [stockId],
    );
  }

  Future<int> updateRemainingQuantity(
    int stockId,
    double remainingQuantity,
  ) async {
    final db = await database;

    return db.update(
      'daily_stock',
      {
        'remaining_quantity': remainingQuantity,
      },
      where: 'id = ?',
      whereArgs: [stockId],
    );
  }

  Future<int> deleteDailyStock(
    int stockId,
  ) async {
    final db = await database;

    return db.delete(
      'daily_stock',
      where: 'id = ?',
      whereArgs: [stockId],
    );
  }

  // ============================================================
  // DAILY REPORT
  // ============================================================

  Future<int> insertDailyReport(
    Map<String, dynamic> report,
  ) async {
    final db = await database;

    return db.insert(
      'daily_reports',
      report,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getDailyReport(
    String date,
  ) async {
    final db = await database;

    final results = await db.query(
      'daily_reports',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  Future<List<Map<String, dynamic>>> getDailyReports() async {
    final db = await database;

    return db.query(
      'daily_reports',
      orderBy: 'date DESC',
    );
  }

  // ============================================================
  // HOME SUMMARY
  // IMPORTANT:
  // Sales / Profit / Amount Received only come from a CLOSED DAY.
  // ============================================================

  Future<Map<String, double>> getTodaySummary(
    String date,
  ) async {
    final stock = await getDailyStock(date);

    double purchaseSpend = 0;
    double remainingStockCost = 0;

    for (final item in stock) {
      purchaseSpend +=
          (item['amount_spent'] as num).toDouble();

      remainingStockCost +=
          (item['remaining_quantity'] as num).toDouble() *
              (item['purchase_price'] as num).toDouble();
    }

    final report = await getDailyReport(date);

    // Before Calculate Profit / Close Business:
    // profit, sales and received MUST stay zero.
    if (report == null) {
      return {
        'purchaseSpend': purchaseSpend,
        'remainingStockCost': remainingStockCost,
        'sales': 0,
        'profit': 0,
        'actualReceived': 0,
      };
    }

    return {
      'purchaseSpend': purchaseSpend,
      'remainingStockCost': remainingStockCost,
      'sales':
          (report['total_sales'] as num).toDouble(),
      'profit':
          (report['total_profit'] as num).toDouble(),
      'actualReceived':
          (report['actual_money_received'] as num)
              .toDouble(),
    };
  }
}