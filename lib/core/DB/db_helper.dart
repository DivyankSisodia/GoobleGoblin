import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_live/sqflite_live.dart';
import 'dart:math';

import '../models/app_settings.dart';
import '../models/card.dart';
import '../models/category.dart';
import '../models/payment.dart';

/// Database helper singleton for all database operations
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Current database version
  static const int _dbVersion = 4;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );

    // Initialize sqflite_live for debugging (only in debug mode)
    assert(() {
      db.live(port: 8080, enabled: true, level: Level.all);
      return true;
    }());

    return db;
  }

  /// Version 4 migration: Add account types, credit limits, app settings
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await _migrateToVersion4(db);
    }
  }
  Future<void> _migrateToVersion4(Database db) async {
    // 1. Add new columns to cards table
    try {
      await db.execute(
        'ALTER TABLE cards ADD COLUMN accountType TEXT DEFAULT "DEBIT"',
      );
    } catch (_) {} // Column might already exist

    try {
      await db.execute(
        'ALTER TABLE cards ADD COLUMN creditLimit REAL DEFAULT 0',
      );
    } catch (_) {}

    try {
      await db.execute(
        'ALTER TABLE cards ADD COLUMN usedAmount REAL DEFAULT 0',
      );
    } catch (_) {}

    // 2. Add new columns to categories table
    try {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN isPredefined INTEGER DEFAULT 1',
      );
    } catch (_) {}

    try {
      await db.execute('ALTER TABLE categories ADD COLUMN assetPath TEXT');
    } catch (_) {}

    // 3. Create app_settings table
    await db.execute('''CREATE TABLE IF NOT EXISTS app_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT UNIQUE NOT NULL,
      value TEXT,
      updatedAt TEXT
    )''');

    // 4. Create indexes for performance
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(date)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payments_cardId ON payments(cardId)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payments_categoryId ON payments(categoryId)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cards_accountType ON cards(accountType)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_settings_key ON app_settings(key)',
      );
    } catch (_) {}

    // 5. Migrate existing cards to set accountType based on type field
    await db.execute('''
      UPDATE cards SET accountType = 
        CASE 
          WHEN LOWER(type) = 'credit' THEN 'CREDIT'
          WHEN LOWER(type) = 'cash' THEN 'CASH'
          ELSE 'DEBIT'
        END
      WHERE accountType IS NULL OR accountType = 'DEBIT'
    ''');
  }

  /// Create all tables (fresh install)
  Future _createDB(Database db, int version) async {
    // Categories table
    await db.execute('''CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      label TEXT NOT NULL,
      icon TEXT,
      assetPath TEXT,
      isPredefined INTEGER DEFAULT 1
    )''');

    // Cards table with account types
    await db.execute('''CREATE TABLE cards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bankName TEXT NOT NULL,
      balance REAL NOT NULL DEFAULT 0,
      date TEXT NOT NULL,
      type TEXT NOT NULL,
      isPrimary INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      accountType TEXT DEFAULT 'DEBIT',
      creditLimit REAL DEFAULT 0,
      usedAmount REAL DEFAULT 0
    )''');

    // Card history table
    await db.execute('''CREATE TABLE card_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cardId INTEGER NOT NULL,
      isPrimary INTEGER NOT NULL,
      startDate TEXT NOT NULL,
      endDate TEXT,
      FOREIGN KEY (cardId) REFERENCES cards (id) ON DELETE CASCADE
    )''');

    // Daily expenditure table
    await db.execute('''CREATE TABLE daily_expenditure (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cardId INTEGER NOT NULL,
      date TEXT NOT NULL,
      totalAmount REAL NOT NULL DEFAULT 0,
      transactionCount INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (cardId) REFERENCES cards (id) ON DELETE CASCADE,
      UNIQUE(cardId, date)
    )''');

    // Monthly expenditure table
    await db.execute('''CREATE TABLE monthly_expenditure (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cardId INTEGER NOT NULL,
      yearMonth TEXT NOT NULL,
      totalAmount REAL NOT NULL DEFAULT 0,
      transactionCount INTEGER NOT NULL DEFAULT 0,
      avgDailyExpenditure REAL NOT NULL DEFAULT 0,
      FOREIGN KEY (cardId) REFERENCES cards (id) ON DELETE CASCADE,
      UNIQUE(cardId, yearMonth)
    )''');

    // Payments table
    await db.execute('''CREATE TABLE payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      isRecurring INTEGER,
      frequency TEXT,
      reminderNotification INTEGER,
      note TEXT,
      cardId INTEGER NOT NULL,
      categoryId INTEGER,
      createdAt TEXT NOT NULL,
      FOREIGN KEY (cardId) REFERENCES cards (id) ON DELETE CASCADE,
      FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL
    )''');

    // App settings table
    await db.execute('''CREATE TABLE app_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT UNIQUE NOT NULL,
      value TEXT,
      updatedAt TEXT
    )''');

    // Create indexes
    await db.execute('CREATE INDEX idx_payments_date ON payments(date)');
    await db.execute('CREATE INDEX idx_payments_cardId ON payments(cardId)');
    await db.execute(
      'CREATE INDEX idx_payments_categoryId ON payments(categoryId)',
    );
    await db.execute(
      'CREATE INDEX idx_cards_accountType ON cards(accountType)',
    );
    await db.execute('CREATE INDEX idx_settings_key ON app_settings(key)');

    // Wishlist table
    await db.execute('''CREATE TABLE wishlist (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      url TEXT NOT NULL,
      title TEXT,
      image_url TEXT,
      price REAL,
      notes TEXT,
      date_added TEXT NOT NULL,
      is_purchased INTEGER DEFAULT 0,
      updated_at TEXT
    )''');
  }

  // ============================================================
  // APP SETTINGS OPERATIONS
  // ============================================================

  /// Get a setting value by key
  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  /// Set a setting value
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all settings
  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final result = await db.query('app_settings');
    return {
      for (final row in result)
        row['key'] as String: row['value'] as String? ?? '',
    };
  }

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    final value = await getSetting(AppSettingsKeys.onboardingCompleted);
    return value == 'true';
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    await setSetting(AppSettingsKeys.onboardingCompleted, 'true');
  }

  /// Get monthly budget
  Future<double> getMonthlyBudget() async {
    final value = await getSetting(AppSettingsKeys.monthlyBudget);
    return double.tryParse(value ?? '') ?? 0;
  }

  /// Set monthly budget
  Future<void> setMonthlyBudget(double amount) async {
    await setSetting(AppSettingsKeys.monthlyBudget, amount.toString());
  }

  // ============================================================
  // CATEGORY OPERATIONS
  // ============================================================

  /// Seed predefined categories (called once during onboarding)
  Future<void> seedPredefinedCategories() async {
    final db = await database;

    // Check if already seeded
    final seeded = await getSetting(AppSettingsKeys.categoriesSeeded);
    if (seeded == 'true') return;

    // Insert predefined categories
    for (final category in PredefinedCategories.all) {
      await db.insert('categories', {
        'label': category.label,
        'icon': category.icon,
        'assetPath': category.assetPath,
        'isPredefined': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Mark as seeded
    await setSetting(AppSettingsKeys.categoriesSeeded, 'true');
  }

  /// Get all categories
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'label ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  /// Get category by ID
  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Category.fromMap(result.first);
  }

  // ============================================================
  // CARD OPERATIONS
  // ============================================================

  /// Insert a new card/account
  Future<int> insertCard(BankCard card) async {
    final db = await database;
    return await db.insert('cards', card.toMap());
  }

  /// Get all cards/accounts
  Future<List<BankCard>> getAllCards() async {
    final db = await database;
    final result = await db.query(
      'cards',
      orderBy: 'isPrimary DESC, bankName ASC',
    );
    return result.map((json) => BankCard.fromMap(json)).toList();
  }

  /// Get cards by account type
  Future<List<BankCard>> getCardsByType(AccountType type) async {
    final db = await database;
    final result = await db.query(
      'cards',
      where: 'accountType = ?',
      whereArgs: [type.dbValue],
      orderBy: 'bankName ASC',
    );
    return result.map((json) => BankCard.fromMap(json)).toList();
  }

  /// Get cash account
  Future<BankCard?> getCashAccount() async {
    final cards = await getCardsByType(AccountType.cash);
    return cards.isNotEmpty ? cards.first : null;
  }

  /// Get primary card
  Future<BankCard?> getPrimaryCard() async {
    final db = await database;
    final result = await db.query('cards', where: 'isPrimary = 1', limit: 1);
    if (result.isEmpty) return null;
    return BankCard.fromMap(result.first);
  }

  /// Update a card
  Future<int> updateCard(BankCard card) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'cards',
      {...card.toMap(), 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  /// Delete a card
  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  /// Set primary card (unsets previous primary)
  Future<void> setPrimaryCard(int cardId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Unset current primary
      await txn.execute(
        '''
        UPDATE cards SET isPrimary = 0, updatedAt = ? WHERE isPrimary = 1
      ''',
        [now],
      );

      // Set new primary
      await txn.execute(
        '''
        UPDATE cards SET isPrimary = 1, updatedAt = ? WHERE id = ?
      ''',
        [now, cardId],
      );
    });
  }

  /// Update card balance (for Cash/Debit)
  Future<void> updateCardBalance(int cardId, double newBalance) async {
    final db = await database;
    await db.execute(
      '''
      UPDATE cards SET balance = ?, updatedAt = ? WHERE id = ?
    ''',
      [newBalance, DateTime.now().toIso8601String(), cardId],
    );
  }

  /// Update credit card used amount
  Future<void> updateCreditUsed(int cardId, double usedAmount) async {
    final db = await database;
    await db.execute(
      '''
      UPDATE cards SET usedAmount = ?, updatedAt = ? WHERE id = ?
    ''',
      [usedAmount, DateTime.now().toIso8601String(), cardId],
    );
  }

  /// Get total balance across all accounts
  Future<double> getTotalBalance() async {
    final db = await database;

    // Sum of Cash + Debit balances
    final debitResult = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total 
      FROM cards 
      WHERE accountType IN ('CASH', 'DEBIT')
    ''');
    final debitTotal = (debitResult.first['total'] as num?)?.toDouble() ?? 0;

    // Available credit from credit cards
    final creditResult = await db.rawQuery('''
      SELECT COALESCE(SUM(creditLimit - usedAmount), 0) as total 
      FROM cards 
      WHERE accountType = 'CREDIT'
    ''');
    final creditAvailable =
        (creditResult.first['total'] as num?)?.toDouble() ?? 0;

    return debitTotal + creditAvailable;
  }

  // ============================================================
  // PAYMENT OPERATIONS
  // ============================================================

  /// Insert a payment and update balances
  Future<int> insertPayment(Payment payment) async {
    final db = await database;

    return await db.transaction((txn) async {
      // 1. Insert the payment
      final id = await txn.insert('payments', payment.toMap());

      // 2. Get the card to determine how to update balance
      final cardResult = await txn.query(
        'cards',
        where: 'id = ?',
        whereArgs: [payment.cardId],
      );
      if (cardResult.isNotEmpty) {
        final card = BankCard.fromMap(cardResult.first);
        final now = DateTime.now().toIso8601String();

        if (card.accountType == AccountType.credit) {
          // For credit cards: increase used amount
          await txn.execute(
            '''
            UPDATE cards SET usedAmount = usedAmount + ?, updatedAt = ? WHERE id = ?
          ''',
            [payment.amount, now, payment.cardId],
          );
        } else {
          // For cash/debit: decrease balance
          await txn.execute(
            '''
            UPDATE cards SET balance = balance - ?, updatedAt = ? WHERE id = ?
          ''',
            [payment.amount, now, payment.cardId],
          );
        }
      }

      // 3. Update expenditure aggregates
      final date = DateTime.parse(payment.date);
      final dateStr = date.toIso8601String().split('T')[0];
      final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      await _updateDailyExpenditureWithTxn(txn, payment.cardId, dateStr);
      await _updateMonthlyExpenditureWithTxn(txn, payment.cardId, yearMonth);

      return id;
    });
  }

  /// Get all payments with category info
  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.*, c.label as category_label, c.icon as category_icon, c.assetPath as category_asset
      FROM payments p
      LEFT JOIN categories c ON p.categoryId = c.id
      ORDER BY p.date DESC
    ''');
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  /// Get payments by date range
  Future<List<Payment>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT p.*, c.label as category_label, c.icon as category_icon, c.assetPath as category_asset
      FROM payments p
      LEFT JOIN categories c ON p.categoryId = c.id
      WHERE p.date BETWEEN ? AND ?
      ORDER BY p.date DESC
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  /// Get recurring payments
  Future<List<Payment>> getRecurringPayments() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.*, c.label as category_label, c.icon as category_icon, c.assetPath as category_asset
      FROM payments p
      LEFT JOIN categories c ON p.categoryId = c.id
      WHERE p.isRecurring = 1
      ORDER BY p.date ASC
    ''');
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  /// Update a payment
  Future<int> updatePayment(Payment payment) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Get old payment for balance adjustment
      final oldResult = await txn.query(
        'payments',
        where: 'id = ?',
        whereArgs: [payment.id],
      );
      if (oldResult.isNotEmpty) {
        final oldPayment = Payment.fromMap(oldResult.first);
        final amountDiff = payment.amount - oldPayment.amount;

        if (amountDiff != 0) {
          final cardResult = await txn.query(
            'cards',
            where: 'id = ?',
            whereArgs: [payment.cardId],
          );
          if (cardResult.isNotEmpty) {
            final card = BankCard.fromMap(cardResult.first);
            final now = DateTime.now().toIso8601String();

            if (card.accountType == AccountType.credit) {
              await txn.execute(
                '''
                UPDATE cards SET usedAmount = usedAmount + ?, updatedAt = ? WHERE id = ?
              ''',
                [amountDiff, now, payment.cardId],
              );
            } else {
              await txn.execute(
                '''
                UPDATE cards SET balance = balance - ?, updatedAt = ? WHERE id = ?
              ''',
                [amountDiff, now, payment.cardId],
              );
            }
          }
        }
      }

      return await txn.update(
        'payments',
        payment.toMap(),
        where: 'id = ?',
        whereArgs: [payment.id],
      );
    });
  }

  /// Delete a payment
  Future<int> deletePayment(int id) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Get payment to restore balance
      final result = await txn.query(
        'payments',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        final payment = Payment.fromMap(result.first);
        final cardResult = await txn.query(
          'cards',
          where: 'id = ?',
          whereArgs: [payment.cardId],
        );

        if (cardResult.isNotEmpty) {
          final card = BankCard.fromMap(cardResult.first);
          final now = DateTime.now().toIso8601String();

          if (card.accountType == AccountType.credit) {
            await txn.execute(
              '''
              UPDATE cards SET usedAmount = usedAmount - ?, updatedAt = ? WHERE id = ?
            ''',
              [payment.amount, now, payment.cardId],
            );
          } else {
            await txn.execute(
              '''
              UPDATE cards SET balance = balance + ?, updatedAt = ? WHERE id = ?
            ''',
              [payment.amount, now, payment.cardId],
            );
          }
        }
      }

      return await txn.delete('payments', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ============================================================
  // EXPENDITURE TRACKING
  // ============================================================

  Future<void> _updateDailyExpenditureWithTxn(
    Transaction txn,
    int cardId,
    String date,
  ) async {
    final result = await txn.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total, COUNT(*) as count
      FROM payments
      WHERE cardId = ? AND date(date) = date(?)
    ''',
      [cardId, date],
    );

    final total = (result.first['total'] as num?)?.toDouble() ?? 0;
    final count = (result.first['count'] as int?) ?? 0;

    await txn.insert('daily_expenditure', {
      'cardId': cardId,
      'date': date,
      'totalAmount': total,
      'transactionCount': count,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _updateMonthlyExpenditureWithTxn(
    Transaction txn,
    int cardId,
    String yearMonth,
  ) async {
    final parts = yearMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final result = await txn.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total, COUNT(*) as count
      FROM payments
      WHERE cardId = ? AND date BETWEEN ? AND ?
    ''',
      [cardId, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final total = (result.first['total'] as num?)?.toDouble() ?? 0;
    final count = (result.first['count'] as int?) ?? 0;
    final daysInMonth = endDate.day;
    final avgDaily = daysInMonth > 0 ? total / daysInMonth : 0;

    await txn.insert('monthly_expenditure', {
      'cardId': cardId,
      'yearMonth': yearMonth,
      'totalAmount': total,
      'transactionCount': count,
      'avgDailyExpenditure': avgDaily,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get monthly spending for current month
  Future<double> getCurrentMonthSpending() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM payments
      WHERE date >= ?
    ''',
      [startOfMonth.toIso8601String()],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Get spending by category for date range
  Future<List<Map<String, dynamic>>> getSpendingByCategory({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        c.id, c.label, c.icon, c.assetPath,
        COALESCE(SUM(p.amount), 0) as total,
        COUNT(p.id) as count
      FROM categories c
      LEFT JOIN payments p ON c.id = p.categoryId AND p.date BETWEEN ? AND ?
      GROUP BY c.id
      HAVING total > 0
      ORDER BY total DESC
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
  }

  // ============================================================
  // WISHLIST OPERATIONS
  // ============================================================

  /// Insert a wishlist item
  Future<int> insertWishlistItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('wishlist', item);
  }

  /// Get all wishlist items
  Future<List<Map<String, dynamic>>> getAllWishlistItems() async {
    final db = await database;
    return await db.query('wishlist', orderBy: 'date_added DESC');
  }

  /// Update a wishlist item
  Future<int> updateWishlistItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.update(
      'wishlist',
      item,
      where: 'id = ?',
      whereArgs: [item['id']],
    );
  }

  /// Delete a wishlist item
  Future<int> deleteWishlistItem(int id) async {
    final db = await database;
    return await db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
  }

  /// Mark wishlist item as purchased
  Future<void> markWishlistAsPurchased(int id) async {
    final db = await database;
    await db.update(
      'wishlist',
      {'is_purchased': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // ANALYTICS & INSIGHTS
  // ============================================================

  /// Get spending trend (this month vs last month)
  Future<Map<String, double>> getSpendingTrend() async {
    final db = await database;
    final now = DateTime.now();

    // This month
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE date >= ?
    ''',
      [thisMonthStart.toIso8601String()],
    );
    final thisMonth = (thisMonthResult.first['total'] as num?)?.toDouble() ?? 0;

    // Last month
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    final lastMonthResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE date BETWEEN ? AND ?
    ''',
      [lastMonthStart.toIso8601String(), lastMonthEnd.toIso8601String()],
    );
    final lastMonth = (lastMonthResult.first['total'] as num?)?.toDouble() ?? 0;

    return {
      'thisMonth': thisMonth,
      'lastMonth': lastMonth,
      'difference': thisMonth - lastMonth,
      'percentChange': lastMonth > 0
          ? ((thisMonth - lastMonth) / lastMonth * 100)
          : 0,
    };
  }

  /// Get fun stats for month-end summary
  Future<Map<String, dynamic>> getMonthEndStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Total spending
    final totalResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total, COUNT(*) as count FROM payments WHERE date >= ?
    ''',
      [startOfMonth.toIso8601String()],
    );

    // Top category
    final topCatResult = await db.rawQuery(
      '''
      SELECT c.label, COUNT(*) as count, SUM(p.amount) as total
      FROM payments p
      LEFT JOIN categories c ON p.categoryId = c.id
      WHERE p.date >= ?
      GROUP BY c.id
      ORDER BY count DESC
      LIMIT 1
    ''',
      [startOfMonth.toIso8601String()],
    );

    // Biggest single expense
    final biggestResult = await db.rawQuery(
      '''
      SELECT p.amount, c.label as category
      FROM payments p
      LEFT JOIN categories c ON p.categoryId = c.id
      WHERE p.date >= ?
      ORDER BY p.amount DESC
      LIMIT 1
    ''',
      [startOfMonth.toIso8601String()],
    );

    // Days with spending
    final activeDaysResult = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT date(date)) as days FROM payments WHERE date >= ?
    ''',
      [startOfMonth.toIso8601String()],
    );

    return {
      'totalSpent': (totalResult.first['total'] as num?)?.toDouble() ?? 0,
      'transactionCount': totalResult.first['count'] ?? 0,
      'topCategory': topCatResult.isNotEmpty
          ? topCatResult.first['label']
          : null,
      'topCategoryCount': topCatResult.isNotEmpty
          ? topCatResult.first['count']
          : 0,
      'biggestExpense': biggestResult.isNotEmpty
          ? (biggestResult.first['amount'] as num?)?.toDouble()
          : null,
      'biggestExpenseCategory': biggestResult.isNotEmpty
          ? biggestResult.first['category']
          : null,
      'activeDays': activeDaysResult.first['days'] ?? 0,
      'daysInMonth': now.day,
    };
  }

  // ============================================================
  // LEGACY METHODS (for backwards compatibility)
  // ============================================================

  /// Get card history
  Future<List<Map<String, dynamic>>> getCardHistory(int cardId) async {
    final db = await database;
    return await db.query(
      'card_history',
      where: 'cardId = ?',
      whereArgs: [cardId],
      orderBy: 'startDate DESC',
    );
  }

  /// Insert a category (legacy support)
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  /// Update a category
  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete a category
  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  /// Get recurring payments (alias)
  Future<List<Payment>> getRecurringPayment() async {
    return await getRecurringPayments();
  }

  /// Get payments by category
  Future<List<Payment>> getPaymentByCategory(int categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT p.*, c.label as category_label, c.icon as category_icon, c.assetPath as category_asset
      FROM payments p
      LEFT JOIN categories c ON p.categoryId = c.id
      WHERE p.categoryId = ?
      ORDER BY p.date DESC
    ''',
      [categoryId],
    );
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  /// Delete all data (reset app)
  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('daily_expenditure');
      await txn.delete('monthly_expenditure');
      await txn.delete('card_history');
      await txn.delete('cards');
      await txn.delete('categories');
      // Preserve onboarding status and other essential settings if needed
      await txn.delete(
        'app_settings',
        where: 'key != ?',
        whereArgs: [AppSettingsKeys.onboardingCompleted],
      );
    });
  }

  /// Get a card by ID
  Future<BankCard?> getCardById(int id) async {
    final db = await database;
    final result = await db.query('cards', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return BankCard.fromMap(result.first);
  }

  /// Get payment by ID
  Future<Payment?> getPaymentById(int id) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT p.*, c.label as category_label, c.icon as category_icon
      FROM payments p
      LEFT JOIN categories c ON p.categoryId = c.id
      WHERE p.id = ?
    ''',
      [id],
    );
    if (result.isEmpty) return null;
    return Payment.fromMap(result.first);
  }

  /// Search payments by note
  Future<List<Payment>> searchPayments(String query) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT p.*, c.label as category_label, c.icon as category_icon
      FROM payments p
      LEFT JOIN categories c ON p.categoryId = c.id
      WHERE p.note LIKE ? OR c.label LIKE ?
      ORDER BY p.date DESC
    ''',
      ['%$query%', '%$query%'],
    );
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  // ============================================================
  // TEST DATA SEEDING
  // ============================================================

  /// Seed the database with comprehensive test data
  Future<void> seedTestData() async {
    // 1. Clear existing data to start fresh
    await deleteAllData();

    // 2. Seed Categories (Important for foreign keys)
    await seedPredefinedCategories();
    final categories = await getAllCategories();
    final categoryMap = {for (var c in categories) c.label: c.id!};

    // 3. Seed Cards
    final cards = [
      BankCard.debit(bankName: 'HDFC Bank', balance: 75000.0), // Main account
      BankCard.debit(bankName: 'SBI Savings', balance: 12000.0), // Secondary
      BankCard.credit(
        bankName: 'ICICI Amazon',
        creditLimit: 150000.0,
      ), // Credit
      BankCard.cash(balance: 4500.0), // Cash
    ];

    final cardIds = <String, int>{};
    for (var card in cards) {
      final id = await insertCard(card);
      cardIds[card.bankName] = id;
    }

    // Set HDFC as primary
    await setPrimaryCard(cardIds['HDFC Bank']!);

    // 4. Set Budget
    await setMonthlyBudget(45000.0);

    // 5. Seed Payments (spanning last 45 days)
    final now = DateTime.now();
    final random = Random();

    // Recurring Payments
    final recurringPayments = [
      Payment(
        amount: 15000,
        date: DateTime(now.year, now.month, 1).toIso8601String(),
        cardId: cardIds['HDFC Bank']!,
        categoryId: categoryMap['Rent']!,
        isRecurring: true,
        frequency: 'Monthly',
        reminderNotification: true,
        note: 'Monthly Rent',
      ),
      Payment(
        amount: 799,
        date: DateTime(now.year, now.month, 5).toIso8601String(),
        cardId: cardIds['ICICI Amazon']!,
        categoryId: categoryMap['Netflix']!,
        isRecurring: true,
        frequency: 'Monthly',
        reminderNotification: true,
        note: 'Netflix Premium',
      ),
      Payment(
        amount: 189,
        date: DateTime(now.year, now.month, 10).toIso8601String(),
        cardId: cardIds['SBI Savings']!,
        categoryId: categoryMap['YouTube']!,
        isRecurring: true,
        frequency: 'Monthly',
        reminderNotification: false,
        note: 'YouTube Premium',
      ),
    ];

    for (var p in recurringPayments) {
      await insertPayment(p);
    }

    // Historical Payments for Analytics
    final titles = [
      'Grocery Shopping',
      'Dinner Out',
      'Uber Ride',
      'Starbucks',
      'Zomato Order',
      'Movie Night',
      'Fuel Refill',
      'Pharmacy',
      'New Shoes',
      'Internet Bill',
      'Electricity Bill',
      'Gift for Friend',
    ];

    final historicalCategories = [
      'Shopping',
      'Food & Dining',
      'Transport',
      'Food & Dining',
      'Zomato',
      'Netflix',
      'Transport',
      'Utilities',
      'Shopping',
      'Utilities',
      'Utilities',
      'Shopping',
    ];

    // Add ~40 random transactions over last 40 days
    for (int i = 0; i < 40; i++) {
      final daysAgo = i + random.nextInt(2);
      if (daysAgo > 45) continue;

      final date = now.subtract(Duration(days: daysAgo));
      final cardKeys = cardIds.keys.toList();
      final randomCardKey = cardKeys[random.nextInt(cardKeys.length)];
      final idx = random.nextInt(titles.length);

      final p = Payment(
        amount: (random.nextInt(2500) + 50).toDouble(),
        date: date.toIso8601String(),
        cardId: cardIds[randomCardKey]!,
        categoryId:
            categoryMap[historicalCategories[idx]] ?? categories.first.id!,
        isRecurring: false,
        reminderNotification: false,
        note: titles[idx],
      );

      await insertPayment(p);
    }
  }
}

