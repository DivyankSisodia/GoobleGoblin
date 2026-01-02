import 'package:gooble_goblin/core/models/category.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, label TEXT, icon TEXT)''');
    await db.execute('''CREATE TABLE cards (id INTEGER PRIMARY KEY AUTOINCREMENT, bankName TEXT, balance REAL, date TEXT)''');
    await db.execute('''CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        date TEXT,
        isRecurring INTEGER,
        frequency TEXT,
        reminderNotification INTEGER,
        cardId INTEGER,
        categoryId INTEGER,
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
    return await db.insert('payments', payment.toMap());
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
    return await db.update('payments', payment.toMap(), where: 'id = ?', whereArgs: [payment.id]);
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
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}