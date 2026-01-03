import 'package:gooble_goblin/core/models/category.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_live/sqflite_live.dart';

import '../models/card.dart';
import '../models/payment.dart';

class DatabaseHelper {

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();
  

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
      version: 3,
      onCreate: _createDB,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: _onUpgrade,
    );
    
    // Initialize sqflite_live on the opened database
    db.live(port: 8080, enabled: true, level: Level.all);
    
    return db;
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE cards ADD COLUMN type TEXT'); 
    }
    if (oldVersion < 3) {
      // Add new columns to cards table
      await db.execute('ALTER TABLE cards ADD COLUMN isPrimary INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE cards ADD COLUMN createdAt TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN updatedAt TEXT');
      
      // Update existing cards with current timestamp
      final now = DateTime.now().toIso8601String();
      await db.execute("UPDATE cards SET createdAt = '$now', updatedAt = '$now'");
      
      // Create card_history table
      await db.execute('''CREATE TABLE card_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardId INTEGER NOT NULL,
        isPrimary INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        FOREIGN KEY (cardId) REFERENCES cards (id) ON DELETE CASCADE
      )''');
      
      // Create daily_expenditure table
      await db.execute('''CREATE TABLE daily_expenditure (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardId INTEGER NOT NULL,
        date TEXT NOT NULL,
        totalAmount REAL NOT NULL DEFAULT 0,
        transactionCount INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (cardId) REFERENCES cards (id) ON DELETE CASCADE,
        UNIQUE(cardId, date)
      )''');
      
      // Create monthly_expenditure table
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
      
      // Add note and createdAt to payments table
      await db.execute('ALTER TABLE payments ADD COLUMN note TEXT');
      await db.execute('ALTER TABLE payments ADD COLUMN createdAt TEXT');
      await db.execute("UPDATE payments SET createdAt = '$now'");
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      label TEXT,
      icon TEXT
    )''');
    
    await db.execute('''CREATE TABLE cards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bankName TEXT NOT NULL,
      balance REAL NOT NULL DEFAULT 0,
      date TEXT NOT NULL,
      type TEXT NOT NULL,
      isPrimary INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )''');
    
    await db.execute('''CREATE TABLE card_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cardId INTEGER NOT NULL,
      isPrimary INTEGER NOT NULL,
      startDate TEXT NOT NULL,
      endDate TEXT,
      FOREIGN KEY (cardId) REFERENCES cards (id) ON DELETE CASCADE
    )''');
    
    await db.execute('''CREATE TABLE daily_expenditure (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cardId INTEGER NOT NULL,
      date TEXT NOT NULL,
      totalAmount REAL NOT NULL DEFAULT 0,
      transactionCount INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (cardId) REFERENCES cards (id) ON DELETE CASCADE,
      UNIQUE(cardId, date)
    )''');
    
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
  }

  // Helper methods to insert data
  Future<int> insertCard(BankCard card) async {
    final db = await instance.database;
    return await db.insert('cards', card.toMap());
  }

  Future<int> insertPayment(Payment payment) async {
    final db = await instance.database;
    final id = await db.insert('payments', payment.toMap());
    
    // Update expenditure aggregates
    final date = DateTime.parse(payment.date);
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD
    final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    
    await updateDailyExpenditure(payment.cardId, dateStr);
    await updateMonthlyExpenditure(payment.cardId, yearMonth);
    
    return id;
  }

  Future<List<BankCard>> getAllCards() async {
    final db = await instance.database;
    final result = await db.query('cards');
    return result.map((json) => BankCard.fromMap(json)).toList();
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await instance.database;
    final result = await db.query('payments');
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCard(BankCard card) async {
    final db = await instance.database;
    return await db.update('cards', card.toMap(), where: 'id = ?', whereArgs: [card.id]);
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await instance.database;
    final result = await db.update(
      'payments', 
      payment.toMap(), 
      where: 'id = ?', 
      whereArgs: [payment.id]
    );
    
    // Update expenditure aggregates
    final date = DateTime.parse(payment.date);
    final dateStr = date.toIso8601String().split('T')[0];
    final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    
    await updateDailyExpenditure(payment.cardId, dateStr);
    await updateMonthlyExpenditure(payment.cardId, yearMonth);
    
    return result;
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCard(int id) async {
    final db = await instance.database;
    return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePayment(int id) async {
    final db = await instance.database;
    
    // Get payment details before deleting
    final payment = await db.query('payments', where: 'id = ?', whereArgs: [id]);
    if (payment.isEmpty) return 0;
    
    final cardId = payment.first['cardId'] as int;
    final dateStr = payment.first['date'] as String;
    final date = DateTime.parse(dateStr);
    final datePart = date.toIso8601String().split('T')[0];
    final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    
    // Delete the payment
    final result = await db.delete('payments', where: 'id = ?', whereArgs: [id]);
    
    // Update expenditure aggregates
    await updateDailyExpenditure(cardId, datePart);
    await updateMonthlyExpenditure(cardId, yearMonth);
    
    return result;
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ===== Primary Card Management =====
  
  /// Set a card as primary (only one card can be primary at a time)
  Future<void> setPrimaryCard(int cardId) async {
    final db = await instance.database;
    
    await db.transaction((txn) async {
      // 1. Get current primary card (if any)
      final currentPrimary = await txn.query(
        'cards',
        where: 'isPrimary = ?',
        whereArgs: [1],
      );
      
      // 2. If there's a current primary, update its history
      if (currentPrimary.isNotEmpty) {
        final oldPrimaryId = currentPrimary.first['id'];
        
        // Set old primary to non-primary
        await txn.update(
          'cards',
          {'isPrimary': 0, 'updatedAt': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [oldPrimaryId],
        );
        
        // Close the history record for old primary
        await txn.update(
          'card_history',
          {'endDate': DateTime.now().toIso8601String()},
          where: 'cardId = ? AND endDate IS NULL',
          whereArgs: [oldPrimaryId],
        );
      }
      
      // 3. Set new primary card
      await txn.update(
        'cards',
        {'isPrimary': 1, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [cardId],
      );
      
      // 4. Create history record for new primary
      await txn.insert('card_history', {
        'cardId': cardId,
        'isPrimary': 1,
        'startDate': DateTime.now().toIso8601String(),
        'endDate': null,
      });
    });
  }

  /// Get the current primary card
  Future<BankCard?> getPrimaryCard() async {
    final db = await instance.database;
    final result = await db.query(
      'cards',
      where: 'isPrimary = ?',
      whereArgs: [1],
    );
    
    if (result.isEmpty) return null;
    return BankCard.fromMap(result.first);
  }

  /// Get card history (when it was primary)
  Future<List<Map<String, dynamic>>> getCardHistory(int cardId) async {
    final db = await instance.database;
    return await db.query(
      'card_history',
      where: 'cardId = ?',
      whereArgs: [cardId],
      orderBy: 'startDate DESC',
    );
  }

  Future<List<Payment>> getPaymentByCategory(String category) async {
    final db = await instance.database;
    final result = await db.query(
      'payments',
      where: 'category = ?',
      whereArgs: [category],
    );
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  // ===== Expenditure Tracking =====
  
  /// Update daily expenditure aggregates for a specific card and date
  Future<void> updateDailyExpenditure(int cardId, String date) async {
    final db = await instance.database;
    
    // Calculate total for the day
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total, COUNT(*) as count
      FROM payments
      WHERE cardId = ? AND date(date) = date(?)
    ''', [cardId, date]);
    
    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    final count = (result.first['count'] as int?) ?? 0;
    
    // Insert or update daily expenditure
    await db.insert(
      'daily_expenditure',
      {
        'cardId': cardId,
        'date': date,
        'totalAmount': total,
        'transactionCount': count,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update monthly expenditure aggregates for a specific card and month
  Future<void> updateMonthlyExpenditure(int cardId, String yearMonth) async {
    final db = await instance.database;
    
    // Calculate monthly totals
    final result = await db.rawQuery('''
      SELECT 
        SUM(amount) as total, 
        COUNT(*) as count,
        AVG(amount) as avgDaily
      FROM payments
      WHERE cardId = ? AND strftime('%Y-%m', date) = ?
    ''', [cardId, yearMonth]);
    
    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    final count = (result.first['count'] as int?) ?? 0;
    final avgDaily = (result.first['avgDaily'] as num?)?.toDouble() ?? 0.0;
    
    // Insert or update monthly expenditure
    await db.insert(
      'monthly_expenditure',
      {
        'cardId': cardId,
        'yearMonth': yearMonth,
        'totalAmount': total,
        'transactionCount': count,
        'avgDailyExpenditure': avgDaily,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get daily expenditure for chart (last N days)
  Future<List<Map<String, dynamic>>> getDailyExpenditure(int cardId, int days) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT date, totalAmount, transactionCount
      FROM daily_expenditure
      WHERE cardId = ?
      AND date >= date('now', '-$days days')
      ORDER BY date ASC
    ''', [cardId]);
  }

  /// Get monthly expenditure for chart (last 12 months)
  Future<List<Map<String, dynamic>>> getMonthlyExpenditure(int cardId, {int months = 12}) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT yearMonth, totalAmount, transactionCount, avgDailyExpenditure
      FROM monthly_expenditure
      WHERE cardId = ?
      AND yearMonth >= strftime('%Y-%m', date('now', '-$months months'))
      ORDER BY yearMonth ASC
    ''', [cardId]);
  }

  /// Compare all cards for current month
  Future<List<Map<String, dynamic>>> compareCardsThisMonth() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        c.id,
        c.bankName, 
        c.type, 
        c.isPrimary, 
        c.balance,
        COALESCE(m.totalAmount, 0) as totalAmount,
        COALESCE(m.transactionCount, 0) as transactionCount
      FROM cards c
      LEFT JOIN monthly_expenditure m ON c.id = m.cardId
        AND m.yearMonth = strftime('%Y-%m', 'now')
      ORDER BY c.isPrimary DESC, m.totalAmount DESC
    ''');
  }

  /// Get expenditure by category for a card
  Future<List<Map<String, dynamic>>> getExpenditureByCategoryForCard(
    int cardId, 
    {String? startDate, String? endDate}
  ) async {
    final db = await instance.database;
    
    String whereClause = 'p.cardId = ?';
    List<dynamic> whereArgs = [cardId];
    
    if (startDate != null && endDate != null) {
      whereClause += ' AND p.date BETWEEN ? AND ?';
      whereArgs.addAll([startDate, endDate]);
    }
    
    return await db.rawQuery('''
      SELECT 
        c.label as categoryName,
        c.icon as categoryIcon,
        SUM(p.amount) as totalAmount,
        COUNT(p.id) as transactionCount
      FROM payments p
      LEFT JOIN categories c ON p.categoryId = c.id
      WHERE $whereClause
      GROUP BY p.categoryId
      ORDER BY totalAmount DESC
    ''', whereArgs);
  }


}