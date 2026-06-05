import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_live/sqflite_live.dart';
import 'package:uuid/uuid.dart';
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
  static const int _dbVersion = 11;

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
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );

    // Repair any records that are missing UUIDs (e.g. categories seeded
    // before the UUID fix). This is idempotent and fast when no rows match.
    await _repairCardsSchemaCompatibility(db);
    await _repairCategoriesSchemaCompatibility(db);
    await _repairMissingUuids(db);
    await _repairCategoryAssetPathsToPng(db);
    await _normalizeCategoriesToPredefinedSet(db);

    // Initialize sqflite_live for debugging (only in debug mode)
    assert(() {
      db.live(port: 8080, enabled: true, level: Level.all);
      return true;
    }());

    return db;
  }

  /// Assign UUIDs to any rows that are still missing one.
  /// This covers records inserted before the UUID fix (e.g. seeded categories).
  /// The method is idempotent — it does nothing when every row already has a UUID.
  Future<void> _repairMissingUuids(Database db) async {
    final uuidGen = const Uuid();
    for (final table in ['categories', 'cards', 'payments', 'wishlist']) {
      try {
        final rows = await db.query(table, where: 'uuid IS NULL');
        for (final row in rows) {
          await db.update(
            table,
            {'uuid': uuidGen.v4(), 'syncStatus': 'PENDING_CREATE'},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      } catch (_) {
        // Table may not exist yet on very first launch before onCreate runs
      }
    }
  }

  Future<void> _repairCategoryAssetPathsToPng(Database db) async {
    try {
      await db.execute('''
        UPDATE categories
        SET assetPath = REPLACE(assetPath, '.svg', '.png')
        WHERE assetPath LIKE 'assets/images/%.svg'
      ''');

      await db.execute('''
        UPDATE categories
        SET assetPath = 'assets/images/grocery.png'
        WHERE assetPath = 'assets/images/groceries.png'
      ''');
    } catch (_) {}
  }

  Future<void> _repairCardsSchemaCompatibility(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(cards)');
      final columnNames = columns
          .map((row) => row['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();

      if (!columnNames.contains('createdAt')) {
        await db.execute('ALTER TABLE cards ADD COLUMN createdAt TEXT');
      }
      if (!columnNames.contains('updatedAt')) {
        await db.execute('ALTER TABLE cards ADD COLUMN updatedAt TEXT');
      }
      if (!columnNames.contains('isDeleted')) {
        await db.execute(
          'ALTER TABLE cards ADD COLUMN isDeleted INTEGER DEFAULT 0',
        );
      }

      if (columnNames.contains('created_at')) {
        await db.execute('''
          UPDATE cards
          SET createdAt = COALESCE(createdAt, created_at, date)
          WHERE createdAt IS NULL
        ''');
      } else {
        await db.execute('''
          UPDATE cards
          SET createdAt = COALESCE(createdAt, date)
          WHERE createdAt IS NULL
        ''');
      }

      if (columnNames.contains('updated_at')) {
        await db.execute('''
          UPDATE cards
          SET updatedAt = COALESCE(updatedAt, updated_at, createdAt, date)
          WHERE updatedAt IS NULL
        ''');
      } else {
        await db.execute('''
          UPDATE cards
          SET updatedAt = COALESCE(updatedAt, createdAt, date)
          WHERE updatedAt IS NULL
        ''');
      }

      await db.execute('''
        UPDATE cards
        SET isDeleted = COALESCE(isDeleted, 0)
        WHERE isDeleted IS NULL
      ''');
    } catch (_) {}
  }

  Future<void> _repairCategoriesSchemaCompatibility(Database db) async {
    try {
      final columnNames = await _getColumnNames(db, 'categories');

      if (!columnNames.contains('assetPath')) {
        await db.execute('ALTER TABLE categories ADD COLUMN assetPath TEXT');
      }
      if (!columnNames.contains('isPredefined')) {
        await db.execute(
          'ALTER TABLE categories ADD COLUMN isPredefined INTEGER DEFAULT 1',
        );
      }
      if (!columnNames.contains('uuid')) {
        await db.execute('ALTER TABLE categories ADD COLUMN uuid TEXT');
      }
      if (!columnNames.contains('syncStatus')) {
        await db.execute(
          "ALTER TABLE categories ADD COLUMN syncStatus TEXT DEFAULT 'PENDING_CREATE'",
        );
      }
      if (!columnNames.contains('lastSyncedAt')) {
        await db.execute('ALTER TABLE categories ADD COLUMN lastSyncedAt TEXT');
      }
      if (!columnNames.contains('isDeleted')) {
        await db.execute(
          'ALTER TABLE categories ADD COLUMN isDeleted INTEGER DEFAULT 0',
        );
      }

      await db.execute('''
        UPDATE categories
        SET isPredefined = COALESCE(isPredefined, 1),
            syncStatus = COALESCE(syncStatus, 'PENDING_CREATE'),
            isDeleted = COALESCE(isDeleted, 0)
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_categories_uuid ON categories(uuid)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_categories_syncStatus ON categories(syncStatus)',
      );
    } catch (_) {}
  }

  /// Version 4 migration: Add account types, credit limits, app settings
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await _migrateToVersion4(db);
    }
    if (oldVersion < 5) {
      await _migrateToVersion5(db);
    }
    if (oldVersion < 6) {
      await _migrateToVersion6(db);
    }
    if (oldVersion < 7) {
      await _migrateToVersion7(db);
    }
    if (oldVersion < 8) {
      await _migrateToVersion8(db);
    }
    if (oldVersion < 9) {
      await _migrateToVersion9(db);
    }
    if (oldVersion < 10) {
      await _migrateToVersion10(db);
    }
    if (oldVersion < 11) {
      await _migrateToVersion11(db);
    }
  }

  /// Version 6 migration: Add isExternalTransaction to payments
  Future<void> _migrateToVersion6(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE payments ADD COLUMN isExternalTransaction INTEGER DEFAULT 0',
      );
    } catch (_) {}
  }

  /// Version 7 migration: Add Grocery category for existing users
  Future<void> _migrateToVersion7(Database db) async {
    try {
      // Check if Grocery category already exists
      final existing = await db.query(
        'categories',
        where: 'LOWER(label) = ?',
        whereArgs: ['grocery'],
      );

      if (existing.isEmpty) {
        await db.insert('categories', {
          'label': 'Grocery',
          'icon': 'grocery',
          'assetPath': 'assets/images/grocery.png',
          'isPredefined': 1,
          'uuid': const Uuid().v4(),
          'syncStatus': 'PENDING_CREATE',
          'isDeleted': 0,
        });
      }
    } catch (_) {}
  }

  /// Version 8 migration: Replace merchant categories with broad categories.
  Future<void> _migrateToVersion8(Database db) async {
    await _normalizeCategoriesToPredefinedSet(db);
  }

  /// Version 9 migration: Prune all non-canonical categories and remap data.
  Future<void> _migrateToVersion9(Database db) async {
    await _normalizeCategoriesToPredefinedSet(db);
  }

  /// Version 10 migration: Add customSvg column for custom category icons.
  Future<void> _migrateToVersion10(Database db) async {
    try {
      await db.execute('ALTER TABLE categories ADD COLUMN customSvg TEXT');
    } catch (_) {}
  }

  /// Version 11 migration: Add isIncome column to distinguish credits from debits.
  Future<void> _migrateToVersion11(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE payments ADD COLUMN isIncome INTEGER DEFAULT 0',
      );
    } catch (_) {}
  }

  Future<void> _normalizeCategoriesToPredefinedSet(Database db) async {
    try {
      final categoryColumns = await _getColumnNames(db, 'categories');
      final paymentColumns = await _getColumnNames(db, 'payments');
      final targetRows = <String, ({int id, String? uuid})>{};

      for (final category in PredefinedCategories.all) {
        final row = await _upsertPredefinedCategory(db, category);
        targetRows[category.label] = (
          id: row['id'] as int,
          uuid: row['uuid'] as String?,
        );
      }

      final activeCategories = await db.query(
        'categories',
        columns: ['id', 'label'],
        where: 'COALESCE(isDeleted, 0) = 0',
      );

      for (final row in activeCategories) {
        final id = _asInt(row['id']);
        if (id == null) continue;

        final targetLabel = PredefinedCategories.legacyTargetLabel(
          row['label']?.toString(),
        );
        if (targetLabel == null) continue;
        final target = targetRows[targetLabel] ?? targetRows['Shopping'];
        if (target == null || target.id == id) continue;

        await db.update(
          'payments',
          _filterColumns({
            'categoryId': target.id,
            'categoryUuid': target.uuid,
          }, paymentColumns),
          where: 'categoryId = ?',
          whereArgs: [id],
        );

        await db.update(
          'categories',
          _filterColumns({
            'isDeleted': 1,
            'syncStatus': SyncStatus.pendingDelete.dbValue,
          }, categoryColumns),
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {}
  }

  Future<Map<String, Object?>> _upsertPredefinedCategory(
    Database db,
    Category category,
  ) async {
    final categoryColumns = await _getColumnNames(db, 'categories');
    final rows = await db.query(
      'categories',
      where: 'LOWER(label) = ?',
      whereArgs: [category.label.toLowerCase()],
      orderBy: 'COALESCE(isDeleted, 0) ASC, id ASC',
      limit: 1,
    );

    if (rows.isNotEmpty) {
      final id = rows.first['id'] as int;
      final uuid = rows.first['uuid'] as String? ?? const Uuid().v4();
      await db.update(
        'categories',
        _filterColumns({
          'label': category.label,
          'icon': category.icon,
          'assetPath': category.assetPath,
          'isPredefined': 1,
          'uuid': uuid,
          'syncStatus': SyncStatus.pendingUpdate.dbValue,
          'isDeleted': 0,
        }, categoryColumns),
        where: 'id = ?',
        whereArgs: [id],
      );
      return {'id': id, 'uuid': uuid};
    }

    final uuid = const Uuid().v4();
    final id = await db.insert(
      'categories',
      _filterColumns({
        'label': category.label,
        'icon': category.icon,
        'assetPath': category.assetPath,
        'isPredefined': 1,
        'uuid': uuid,
        'syncStatus': SyncStatus.pendingCreate.dbValue,
        'isDeleted': 0,
      }, categoryColumns),
    );
    return {'id': id, 'uuid': uuid};
  }

  Future<void> _ensurePredefinedCategories(Database db) async {
    for (final category in PredefinedCategories.all) {
      await _upsertPredefinedCategory(db, category);
    }
  }

  Future<Set<String>> _getColumnNames(Database db, String table) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    return columns
        .map((row) => row['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();
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

  /// Version 5 migration: Add sync columns for offline-first architecture
  Future<void> _migrateToVersion5(Database db) async {
    const uuidGen = Uuid();

    // Add sync columns to cards
    final cardsColumns = [
      'uuid TEXT UNIQUE',
      'syncStatus TEXT DEFAULT \'PENDING_CREATE\'',
      'lastSyncedAt TEXT',
      'isDeleted INTEGER DEFAULT 0',
    ];
    for (final col in cardsColumns) {
      try {
        await db.execute('ALTER TABLE cards ADD COLUMN $col');
      } catch (_) {}
    }

    // Add sync columns to categories
    final catColumns = [
      'uuid TEXT UNIQUE',
      'syncStatus TEXT DEFAULT \'PENDING_CREATE\'',
      'lastSyncedAt TEXT',
      'isDeleted INTEGER DEFAULT 0',
    ];
    for (final col in catColumns) {
      try {
        await db.execute('ALTER TABLE categories ADD COLUMN $col');
      } catch (_) {}
    }

    // Add sync columns to payments
    final payColumns = [
      'uuid TEXT UNIQUE',
      'cardUuid TEXT',
      'categoryUuid TEXT',
      'syncStatus TEXT DEFAULT \'PENDING_CREATE\'',
      'lastSyncedAt TEXT',
      'isDeleted INTEGER DEFAULT 0',
    ];
    for (final col in payColumns) {
      try {
        await db.execute('ALTER TABLE payments ADD COLUMN $col');
      } catch (_) {}
    }

    // Add sync columns to wishlist
    final wishColumns = [
      'uuid TEXT UNIQUE',
      'syncStatus TEXT DEFAULT \'PENDING_CREATE\'',
      'lastSyncedAt TEXT',
      'isDeleted INTEGER DEFAULT 0',
    ];
    for (final col in wishColumns) {
      try {
        await db.execute('ALTER TABLE wishlist ADD COLUMN $col');
      } catch (_) {}
    }

    // Create indexes for sync
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cards_uuid ON cards(uuid)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payments_uuid ON payments(uuid)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_categories_uuid ON categories(uuid)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_wishlist_uuid ON wishlist(uuid)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cards_syncStatus ON cards(syncStatus)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payments_syncStatus ON payments(syncStatus)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_categories_syncStatus ON categories(syncStatus)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_wishlist_syncStatus ON wishlist(syncStatus)',
      );
    } catch (_) {}

    // Assign UUIDs to existing records that don't have one
    final cards = await db.query('cards', where: 'uuid IS NULL');
    for (final card in cards) {
      await db.update(
        'cards',
        {'uuid': uuidGen.v4(), 'syncStatus': 'PENDING_CREATE'},
        where: 'id = ?',
        whereArgs: [card['id']],
      );
    }

    final categories = await db.query('categories', where: 'uuid IS NULL');
    for (final cat in categories) {
      await db.update(
        'categories',
        {'uuid': uuidGen.v4(), 'syncStatus': 'PENDING_CREATE'},
        where: 'id = ?',
        whereArgs: [cat['id']],
      );
    }

    final payments = await db.query('payments', where: 'uuid IS NULL');
    for (final pay in payments) {
      final cardId = pay['cardId'];
      final categoryId = pay['categoryId'];
      // Look up card UUID
      String? cardUuid;
      if (cardId != null) {
        final cardRow = await db.query(
          'cards',
          columns: ['uuid'],
          where: 'id = ?',
          whereArgs: [cardId],
        );
        if (cardRow.isNotEmpty) cardUuid = cardRow.first['uuid'] as String?;
      }
      // Look up category UUID
      String? categoryUuid;
      if (categoryId != null) {
        final catRow = await db.query(
          'categories',
          columns: ['uuid'],
          where: 'id = ?',
          whereArgs: [categoryId],
        );
        if (catRow.isNotEmpty) categoryUuid = catRow.first['uuid'] as String?;
      }
      await db.update(
        'payments',
        {
          'uuid': uuidGen.v4(),
          'cardUuid': cardUuid,
          'categoryUuid': categoryUuid,
          'syncStatus': 'PENDING_CREATE',
        },
        where: 'id = ?',
        whereArgs: [pay['id']],
      );
    }

    final wishlist = await db.query('wishlist', where: 'uuid IS NULL');
    for (final item in wishlist) {
      await db.update(
        'wishlist',
        {'uuid': uuidGen.v4(), 'syncStatus': 'PENDING_CREATE'},
        where: 'id = ?',
        whereArgs: [item['id']],
      );
    }
  }

  /// Create all tables (fresh install)
  Future _createDB(Database db, int version) async {
    // Categories table
    await db.execute('''CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      label TEXT NOT NULL,
      icon TEXT,
      assetPath TEXT,
      customSvg TEXT,
      isPredefined INTEGER DEFAULT 1,
      uuid TEXT UNIQUE,
      syncStatus TEXT DEFAULT 'PENDING_CREATE',
      lastSyncedAt TEXT,
      isDeleted INTEGER DEFAULT 0
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
      usedAmount REAL DEFAULT 0,
      uuid TEXT UNIQUE,
      syncStatus TEXT DEFAULT 'PENDING_CREATE',
      lastSyncedAt TEXT,
      isDeleted INTEGER DEFAULT 0
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
      uuid TEXT UNIQUE,
      cardUuid TEXT,
      categoryUuid TEXT,
      syncStatus TEXT DEFAULT 'PENDING_CREATE',
      lastSyncedAt TEXT,
      isDeleted INTEGER DEFAULT 0,
      isExternalTransaction INTEGER DEFAULT 0,
      isIncome INTEGER DEFAULT 0,
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
    await db.execute('CREATE INDEX idx_cards_uuid ON cards(uuid)');
    await db.execute('CREATE INDEX idx_payments_uuid ON payments(uuid)');
    await db.execute('CREATE INDEX idx_categories_uuid ON categories(uuid)');
    await db.execute('CREATE INDEX idx_cards_syncStatus ON cards(syncStatus)');
    await db.execute(
      'CREATE INDEX idx_payments_syncStatus ON payments(syncStatus)',
    );
    await db.execute(
      'CREATE INDEX idx_categories_syncStatus ON categories(syncStatus)',
    );

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
      updated_at TEXT,
      uuid TEXT UNIQUE,
      syncStatus TEXT DEFAULT 'PENDING_CREATE',
      lastSyncedAt TEXT,
      isDeleted INTEGER DEFAULT 0
    )''');
    await db.execute('CREATE INDEX idx_wishlist_uuid ON wishlist(uuid)');
    await db.execute(
      'CREATE INDEX idx_wishlist_syncStatus ON wishlist(syncStatus)',
    );
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

    // Keep this idempotent. Older installs may have the seeded flag set while
    // category rows are missing, soft-deleted, duplicated, or still on legacy
    // merchant names.
    await _normalizeCategoriesToPredefinedSet(db);

    // Mark as seeded
    await setSetting(AppSettingsKeys.categoriesSeeded, 'true');
  }

  /// Get all categories (excluding soft-deleted)
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    var result = await db.query(
      'categories',
      where: 'COALESCE(isDeleted, 0) = 0',
      orderBy: 'label ASC',
    );
    if (result.isEmpty) {
      await seedPredefinedCategories();
      result = await db.query(
        'categories',
        where: 'COALESCE(isDeleted, 0) = 0',
        orderBy: 'label ASC',
      );
    }
    final categories = result.map((json) => Category.fromMap(json)).toList();
    final preferredOrder = {
      for (var index = 0; index < PredefinedCategories.all.length; index++)
        PredefinedCategories.all[index].label.toLowerCase(): index,
    };
    categories.sort((a, b) {
      final orderA = preferredOrder[a.label.toLowerCase()] ?? 999;
      final orderB = preferredOrder[b.label.toLowerCase()] ?? 999;
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return categories;
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
    final map = card.toMap();
    // Ensure UUID is assigned
    map['uuid'] ??= generateUuid();
    map['syncStatus'] ??= SyncStatus.pendingCreate.dbValue;
    return await db.insert('cards', map);
  }

  /// Get all cards/accounts (excluding soft-deleted)
  Future<List<BankCard>> getAllCards() async {
    final db = await database;
    final result = await db.query(
      'cards',
      where: 'COALESCE(isDeleted, 0) = 0',
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
    final map = {...card.toMap(), 'updatedAt': now};
    // Mark as pending update if currently synced
    if (card.syncStatus == SyncStatus.synced) {
      map['syncStatus'] = SyncStatus.pendingUpdate.dbValue;
    }
    return await db.update('cards', map, where: 'id = ?', whereArgs: [card.id]);
  }

  /// Delete a card (soft delete for sync)
  Future<int> deleteCard(int id) async {
    final db = await database;
    // Check if record was ever synced
    final record = await db.query('cards', where: 'id = ?', whereArgs: [id]);
    if (record.isNotEmpty &&
        (record.first['syncStatus'] == 'SYNCED' ||
            record.first['syncStatus'] == 'PENDING_UPDATE')) {
      // Soft delete - mark for remote deletion
      return await db.update(
        'cards',
        {'isDeleted': 1, 'syncStatus': 'PENDING_DELETE'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    // Never synced - just delete locally
    return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  /// Set primary card (unsets previous primary)
  Future<void> setPrimaryCard(int cardId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Get current primary card id before changing
    final oldPrimary = await db.query(
      'cards',
      columns: ['id'],
      where: 'isPrimary = 1',
    );

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

    // Mark both old and new primary cards
    for (final row in oldPrimary) {
      final oldId = row['id'] as int;
      if (oldId != cardId) {}
    }
  }

  /// Update card balance (for Cash/Debit)
  Future<void> updateCardBalance(int cardId, double newBalance) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE cards SET balance = ?, updatedAt = ? WHERE id = ?
    ''',
      [newBalance, now, cardId],
    );
  }

  /// Update credit card used amount
  Future<void> updateCreditUsed(int cardId, double usedAmount) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE cards SET usedAmount = ?, updatedAt = ? WHERE id = ?
    ''',
      [usedAmount, now, cardId],
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
      // Ensure UUID is assigned
      final map = payment.toMap();
      map['uuid'] ??= generateUuid();
      map['syncStatus'] ??= SyncStatus.pendingCreate.dbValue;

      // Resolve card UUID
      if (map['cardUuid'] == null) {
        final cardRow = await txn.query(
          'cards',
          columns: ['uuid'],
          where: 'id = ?',
          whereArgs: [payment.cardId],
        );
        if (cardRow.isNotEmpty) map['cardUuid'] = cardRow.first['uuid'];
      }
      // Resolve category UUID
      if (map['categoryUuid'] == null && payment.categoryId > 0) {
        final catRow = await txn.query(
          'categories',
          columns: ['uuid'],
          where: 'id = ?',
          whereArgs: [payment.categoryId],
        );
        if (catRow.isNotEmpty) map['categoryUuid'] = catRow.first['uuid'];
      }

      // 1. Insert the payment
      final id = await txn.insert('payments', map);

      // 2. Update card balance based on transaction type
      if (!payment.isExternalTransaction) {
        final cardResult = await txn.query(
          'cards',
          where: 'id = ?',
          whereArgs: [payment.cardId],
        );
        if (cardResult.isNotEmpty) {
          final card = BankCard.fromMap(cardResult.first);
          final now = DateTime.now().toIso8601String();

          if (payment.isIncome) {
            // Income: add money back to the card
            if (card.accountType == AccountType.credit) {
              // For credit cards: decrease used amount (payment towards card)
              await txn.execute(
                '''
                UPDATE cards SET usedAmount = MAX(0, usedAmount - ?), updatedAt = ? WHERE id = ?
              ''',
                [payment.amount, now, payment.cardId],
              );
            } else {
              // For cash/debit: increase balance
              await txn.execute(
                '''
                UPDATE cards SET balance = balance + ?, updatedAt = ? WHERE id = ?
              ''',
                [payment.amount, now, payment.cardId],
              );
            }
          } else {
            // Expense: deduct from card
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

          await txn.execute(
            "UPDATE cards SET syncStatus = 'PENDING_UPDATE' WHERE id = ? AND syncStatus = 'SYNCED'",
            [payment.cardId],
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

  /// Get all payments with category info (excluding soft-deleted)
  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.*, c.label as category_label, c.icon as category_icon, c.assetPath as category_asset, c.customSvg as category_customSvg
      FROM payments p
      LEFT JOIN categories c ON p.categoryId = c.id
      WHERE p.isDeleted = 0
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
      SELECT p.*, c.label as category_label, c.icon as category_icon, c.assetPath as category_asset, c.customSvg as category_customSvg
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
      SELECT p.*, c.label as category_label, c.icon as category_icon, c.assetPath as category_asset, c.customSvg as category_customSvg
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

        // Adjust balance only when neither old nor new payment is external
        if (amountDiff != 0 &&
            !payment.isExternalTransaction &&
            !oldPayment.isExternalTransaction) {
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

            await txn.execute(
              "UPDATE cards SET syncStatus = 'PENDING_UPDATE' WHERE id = ? AND syncStatus = 'SYNCED'",
              [payment.cardId],
            );
          }
        } else if (amountDiff != 0 &&
            !payment.isExternalTransaction &&
            oldPayment.isExternalTransaction) {
          // Was external, now not — deduct the full new amount
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
                'UPDATE cards SET usedAmount = usedAmount + ?, updatedAt = ? WHERE id = ?',
                [payment.amount, now, payment.cardId],
              );
            } else {
              await txn.execute(
                'UPDATE cards SET balance = balance - ?, updatedAt = ? WHERE id = ?',
                [payment.amount, now, payment.cardId],
              );
            }
            await txn.execute(
              "UPDATE cards SET syncStatus = 'PENDING_UPDATE' WHERE id = ? AND syncStatus = 'SYNCED'",
              [payment.cardId],
            );
          }
        } else if (payment.isExternalTransaction &&
            !oldPayment.isExternalTransaction) {
          // Was normal, now external — restore the old amount
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
                'UPDATE cards SET usedAmount = usedAmount - ?, updatedAt = ? WHERE id = ?',
                [oldPayment.amount, now, payment.cardId],
              );
            } else {
              await txn.execute(
                'UPDATE cards SET balance = balance + ?, updatedAt = ? WHERE id = ?',
                [oldPayment.amount, now, payment.cardId],
              );
            }
            await txn.execute(
              "UPDATE cards SET syncStatus = 'PENDING_UPDATE' WHERE id = ? AND syncStatus = 'SYNCED'",
              [payment.cardId],
            );
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

  /// Delete a payment (soft delete for sync)
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

        // Only restore balance for non-external transactions
        if (!payment.isExternalTransaction) {
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

  /// Get spending for the current billing cycle (starting from the 7th)
  Future<double> getCurrentMonthSpending() async {
    final db = await database;
    final now = DateTime.now();
    final startOfCycle = now.day >= 7
        ? DateTime(now.year, now.month, 7)
        : DateTime(now.year, now.month - 1, 7);

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM payments
      WHERE date >= ?
    ''',
      [startOfCycle.toIso8601String()],
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
    item['uuid'] ??= generateUuid();
    item['syncStatus'] ??= SyncStatus.pendingCreate.dbValue;
    return await db.insert('wishlist', item);
  }

  /// Get all wishlist items (excluding soft-deleted)
  Future<List<Map<String, dynamic>>> getAllWishlistItems() async {
    final db = await database;
    return await db.query(
      'wishlist',
      where: 'isDeleted = 0',
      orderBy: 'date_added DESC',
    );
  }

  /// Update a wishlist item
  Future<int> updateWishlistItem(Map<String, dynamic> item) async {
    final db = await database;
    // Mark dirty if previously synced
    final existing = await db.query(
      'wishlist',
      where: 'id = ?',
      whereArgs: [item['id']],
    );
    if (existing.isNotEmpty && existing.first['syncStatus'] == 'SYNCED') {
      item['syncStatus'] = SyncStatus.pendingUpdate.dbValue;
    }
    return await db.update(
      'wishlist',
      item,
      where: 'id = ?',
      whereArgs: [item['id']],
    );
  }

  /// Delete a wishlist item (soft delete for sync)
  Future<int> deleteWishlistItem(int id) async {
    final db = await database;
    final record = await db.query('wishlist', where: 'id = ?', whereArgs: [id]);
    if (record.isNotEmpty &&
        (record.first['syncStatus'] == 'SYNCED' ||
            record.first['syncStatus'] == 'PENDING_UPDATE')) {
      return await db.update(
        'wishlist',
        {'isDeleted': 1, 'syncStatus': 'PENDING_DELETE'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return await db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
  }

  /// Mark wishlist item as purchased
  Future<void> markWishlistAsPurchased(int id) async {
    final db = await database;
    final update = <String, dynamic>{'is_purchased': 1};
    // Mark dirty if previously synced
    final existing = await db.query(
      'wishlist',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (existing.isNotEmpty && existing.first['syncStatus'] == 'SYNCED') {
      update['syncStatus'] = SyncStatus.pendingUpdate.dbValue;
    }
    await db.update('wishlist', update, where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // ANALYTICS & INSIGHTS
  // ============================================================

  /// Get spending trend (current billing cycle vs previous billing cycle)
  Future<Map<String, double>> getSpendingTrend() async {
    final db = await database;
    final now = DateTime.now();

    // Current billing cycle (7th to 6th)
    final thisCycleStart = now.day >= 7
        ? DateTime(now.year, now.month, 7)
        : DateTime(now.year, now.month - 1, 7);
    final thisCycleResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE date >= ?
    ''',
      [thisCycleStart.toIso8601String()],
    );
    final thisCycle = (thisCycleResult.first['total'] as num?)?.toDouble() ?? 0;

    // Previous billing cycle
    final prevCycleEnd = thisCycleStart.subtract(const Duration(days: 1));
    final prevCycleStart = DateTime(
      prevCycleEnd.year,
      prevCycleEnd.month - (prevCycleEnd.day < 7 ? 1 : 0),
      7,
    );
    final prevCycleResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE date BETWEEN ? AND ?
    ''',
      [prevCycleStart.toIso8601String(), prevCycleEnd.toIso8601String()],
    );
    final lastCycle = (prevCycleResult.first['total'] as num?)?.toDouble() ?? 0;

    return {
      'thisMonth': thisCycle,
      'lastMonth': lastCycle,
      'difference': thisCycle - lastCycle,
      'percentChange': lastCycle > 0
          ? ((thisCycle - lastCycle) / lastCycle * 100)
          : 0,
    };
  }

  /// Get fun stats for month-end summary
  Future<Map<String, dynamic>> getMonthEndStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfCycle = now.day >= 7
        ? DateTime(now.year, now.month, 7)
        : DateTime(now.year, now.month - 1, 7);

    // Total spending
    final totalResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total, COUNT(*) as count FROM payments WHERE date >= ?
    ''',
      [startOfCycle.toIso8601String()],
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
      [startOfCycle.toIso8601String()],
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
      [startOfCycle.toIso8601String()],
    );

    // Days with spending
    final activeDaysResult = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT date(date)) as days FROM payments WHERE date >= ?
    ''',
      [startOfCycle.toIso8601String()],
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
    final map = category.toMap();
    map['uuid'] ??= generateUuid();
    map['syncStatus'] ??= SyncStatus.pendingCreate.dbValue;
    return await db.insert('categories', map);
  }

  /// Update a category
  Future<int> updateCategory(Category category) async {
    final db = await database;
    final map = category.toMap();
    // Mark dirty if previously synced
    if (category.syncStatus == SyncStatus.synced) {
      map['syncStatus'] = SyncStatus.pendingUpdate.dbValue;
    }
    return await db.update(
      'categories',
      map,
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete a category (soft delete for sync)
  Future<int> deleteCategory(int id) async {
    final db = await database;
    final record = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (record.isNotEmpty &&
        (record.first['syncStatus'] == 'SYNCED' ||
            record.first['syncStatus'] == 'PENDING_UPDATE')) {
      return await db.update(
        'categories',
        {'isDeleted': 1, 'syncStatus': 'PENDING_DELETE'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
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
      SELECT p.*, c.label as category_label, c.icon as category_icon, c.assetPath as category_asset, c.customSvg as category_customSvg
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
      for (final table in ['payments', 'cards', 'categories', 'wishlist']) {
        await txn.delete(table);
      }
      // Clean up aggregation tables
      await txn.delete('daily_expenditure');
      await txn.delete('monthly_expenditure');
      await txn.delete('card_history');
      // Preserve onboarding status and other essential settings
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
      SELECT p.*, c.label as category_label, c.icon as category_icon, c.assetPath as category_asset, c.customSvg as category_customSvg
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
      SELECT p.*, c.label as category_label, c.icon as category_icon, c.assetPath as category_asset, c.customSvg as category_customSvg
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
  // LOCAL DATABASE BACKUP / RESTORE
  // ============================================================

  static const List<String> _backupTables = [
    'app_settings',
    'categories',
    'cards',
    'payments',
    'wishlist',
    'card_history',
    'daily_expenditure',
    'monthly_expenditure',
  ];

  Future<Map<String, dynamic>> exportLocalDbSnapshot() async {
    final db = await database;
    final tables = <String, List<Map<String, Object?>>>{};

    for (final table in _backupTables) {
      try {
        tables[table] = await db.query(table);
      } catch (_) {
        tables[table] = const [];
      }
    }

    return {
      'format': 'gooble_goblin_local_db',
      'formatVersion': 1,
      'dbVersion': _dbVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
    };
  }

  Future<void> importLocalDbSnapshot(Map<String, dynamic> snapshot) async {
    final tablesValue = snapshot['tables'];
    if (tablesValue is! Map) {
      throw const FormatException('Invalid GoobleGoblin backup JSON');
    }

    final db = await database;
    final columnsByTable = <String, Set<String>>{};
    for (final table in _backupTables) {
      columnsByTable[table] = await _getTableColumns(db, table);
    }

    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('card_history');
      await txn.delete('daily_expenditure');
      await txn.delete('monthly_expenditure');
      await txn.delete('cards');
      await txn.delete('categories');
      await txn.delete('wishlist');
      await txn.delete('app_settings');

      await _insertImportedRows(
        txn,
        'app_settings',
        _rowsFromSnapshot(tablesValue['app_settings']),
        columnsByTable['app_settings']!,
      );

      await _insertImportedRows(
        txn,
        'cards',
        _rowsFromSnapshot(tablesValue['cards']),
        columnsByTable['cards']!,
      );

      await _insertImportedRows(
        txn,
        'wishlist',
        _rowsFromSnapshot(tablesValue['wishlist']),
        columnsByTable['wishlist']!,
      );

      await _insertImportedRows(
        txn,
        'card_history',
        _rowsFromSnapshot(tablesValue['card_history']),
        columnsByTable['card_history']!,
      );

      final importedCategories = _rowsFromSnapshot(tablesValue['categories']);
      final categoryTargets = await _insertImportCategories(
        txn,
        importedCategories,
        columnsByTable['categories']!,
      );

      await _insertImportPayments(
        txn,
        _rowsFromSnapshot(tablesValue['payments']),
        categoryTargets,
        columnsByTable['payments']!,
      );

      await _rebuildExpenditureAggregates(txn);

      await txn.insert('app_settings', {
        'key': AppSettingsKeys.categoriesSeeded,
        'value': 'true',
        'updatedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final hasCards = (await txn.query('cards', limit: 1)).isNotEmpty;
      final hasPayments = (await txn.query('payments', limit: 1)).isNotEmpty;
      if (hasCards || hasPayments) {
        await txn.insert('app_settings', {
          'key': AppSettingsKeys.onboardingCompleted,
          'value': 'true',
          'updatedAt': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<Set<String>> _getTableColumns(Database db, String table) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result.map((row) => row['name'] as String).toSet();
  }

  List<Map<String, Object?>> _rowsFromSnapshot(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (row) => row.map(
            (key, value) => MapEntry(key.toString(), value as Object?),
          ),
        )
        .toList();
  }

  Future<void> _insertImportedRows(
    Transaction txn,
    String table,
    List<Map<String, Object?>> rows,
    Set<String> columns,
  ) async {
    for (final row in rows) {
      final filtered = _filterColumns(row, columns);
      if (filtered.isEmpty) continue;
      await txn.insert(
        table,
        filtered,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Map<String, Object?> _filterColumns(
    Map<String, Object?> row,
    Set<String> columns,
  ) {
    return {
      for (final entry in row.entries)
        if (columns.contains(entry.key)) entry.key: entry.value,
    };
  }

  Future<Map<int, ({int id, String? uuid})>> _insertImportCategories(
    Transaction txn,
    List<Map<String, Object?>> importedCategories,
    Set<String> columns,
  ) async {
    final targetByLabel = <String, ({int id, String? uuid})>{};
    final importedTargetLabels = <String, String>{};

    for (final row in importedCategories) {
      final oldId = _asInt(row['id']);
      final label = row['label']?.toString() ?? '';
      if (oldId != null) importedTargetLabels[oldId.toString()] = label;
    }

    for (final category in PredefinedCategories.all) {
      final importedMatch = importedCategories.firstWhere(
        (row) =>
            _targetCategoryLabel(row['label']?.toString()) == category.label,
        orElse: () => const {},
      );
      final preferredUuid = importedMatch['uuid']?.toString();

      final row = <String, Object?>{
        'label': category.label,
        'icon': category.icon,
        'assetPath': category.assetPath,
        'isPredefined': 1,
        'uuid': preferredUuid?.isNotEmpty == true
            ? preferredUuid
            : const Uuid().v4(),
        'syncStatus': SyncStatus.pendingUpdate.dbValue,
        'isDeleted': 0,
      };
      final id = await txn.insert(
        'categories',
        _filterColumns(row, columns),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      targetByLabel[_labelKey(category.label)] = (
        id: id,
        uuid: row['uuid'] as String?,
      );
    }

    for (final row in importedCategories) {
      final oldId = _asInt(row['id']);
      if (oldId == null) continue;

      final targetLabel = _targetCategoryLabel(row['label']?.toString());
      final targetKey = _labelKey(targetLabel);
      if (!targetByLabel.containsKey(targetKey)) {
        final icon = row['icon']?.toString().trim();
        final assetPath = row['assetPath']?.toString().trim();
        final preferredUuid = row['uuid']?.toString();
        final categoryUuid = preferredUuid?.isNotEmpty == true
            ? preferredUuid
            : const Uuid().v4();
        final insertedId = await txn.insert(
          'categories',
          _filterColumns({
            'label': targetLabel,
            'icon': icon?.isNotEmpty == true ? icon : 'category',
            'assetPath': assetPath?.isNotEmpty == true ? assetPath : null,
            'isPredefined': 0,
            'uuid': categoryUuid,
            'syncStatus': SyncStatus.pendingUpdate.dbValue,
            'isDeleted': 0,
          }, columns),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        targetByLabel[targetKey] = (id: insertedId, uuid: categoryUuid);
      }
    }

    final mapped = <int, ({int id, String? uuid})>{};
    for (final row in importedCategories) {
      final oldId = _asInt(row['id']);
      if (oldId == null) continue;
      final targetLabel = _targetCategoryLabel(importedTargetLabels['$oldId']);
      mapped[oldId] =
          targetByLabel[_labelKey(targetLabel)] ??
          targetByLabel[_labelKey('Shopping')]!;
    }

    mapped[-1] = targetByLabel[_labelKey('Shopping')]!;
    return mapped;
  }

  Future<void> _insertImportPayments(
    Transaction txn,
    List<Map<String, Object?>> rows,
    Map<int, ({int id, String? uuid})> categoryTargets,
    Set<String> columns,
  ) async {
    final fallbackCategory = categoryTargets.values.firstOrNull;

    for (final row in rows) {
      final oldCategoryId = _asInt(row['categoryId']);
      final categoryTarget =
          (oldCategoryId != null ? categoryTargets[oldCategoryId] : null) ??
          fallbackCategory;
      final normalized = Map<String, Object?>.from(row);

      if (categoryTarget != null) {
        normalized['categoryId'] = categoryTarget.id;
        normalized['categoryUuid'] = categoryTarget.uuid;
      }
      normalized['isDeleted'] ??= 0;
      normalized['syncStatus'] ??= SyncStatus.pendingUpdate.dbValue;
      normalized['createdAt'] ??= DateTime.now().toIso8601String();

      await txn.insert(
        'payments',
        _filterColumns(normalized, columns),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  String _targetCategoryLabel(String? label) {
    final remapped = PredefinedCategories.legacyTargetLabel(label);
    if (remapped != null) return remapped;

    final trimmed = label?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed : 'Shopping';
  }

  String _labelKey(String label) {
    return label.trim().toLowerCase();
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _rebuildExpenditureAggregates(Transaction txn) async {
    await txn.delete('daily_expenditure');
    await txn.delete('monthly_expenditure');

    final rows = await txn.rawQuery('''
      SELECT DISTINCT cardId, date(date) as day
      FROM payments
      WHERE cardId IS NOT NULL AND date IS NOT NULL
    ''');

    final monthKeys = <String>{};
    for (final row in rows) {
      final cardId = _asInt(row['cardId']);
      final day = row['day']?.toString();
      if (cardId == null || day == null || day.isEmpty) continue;

      await _updateDailyExpenditureWithTxn(txn, cardId, day);
      final date = DateTime.tryParse(day);
      if (date == null) continue;

      final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthKeys.add('$cardId|$yearMonth');
    }

    for (final key in monthKeys) {
      final parts = key.split('|');
      await _updateMonthlyExpenditureWithTxn(
        txn,
        int.parse(parts[0]),
        parts[1],
      );
    }
  }

  // ============================================================
  // UUID GENERATION
  // ============================================================

  static const _uuidGen = Uuid();

  /// Generate a new UUID
  String generateUuid() => _uuidGen.v4();

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
        categoryId: categoryMap['Home Utils']!,
        isRecurring: true,
        frequency: 'Monthly',
        reminderNotification: true,
        note: 'Monthly Rent',
      ),
      Payment(
        amount: 799,
        date: DateTime(now.year, now.month, 5).toIso8601String(),
        cardId: cardIds['ICICI Amazon']!,
        categoryId: categoryMap['Subscriptions']!,
        isRecurring: true,
        frequency: 'Monthly',
        reminderNotification: true,
        note: 'Netflix Premium',
      ),
      Payment(
        amount: 189,
        date: DateTime(now.year, now.month, 10).toIso8601String(),
        cardId: cardIds['SBI Savings']!,
        categoryId: categoryMap['Subscriptions']!,
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
      'Bike',
      'Food & Dining',
      'Food & Dining',
      'Subscriptions',
      'Bike',
      'Home Utils',
      'Shopping',
      'Home Utils',
      'Home Utils',
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
