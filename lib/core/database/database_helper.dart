import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static const tableRoommates = 'roommates';
  static const tableExpenses = 'expenses';
  static const tableExpenseSplits = 'expense_splits';
  static const tableMessSessions = 'mess_sessions';
  static const tableGoals = 'goals';
  static const tableAlerts = 'alerts';

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mess_buddy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw Exception("SQLite requires native platforms (iOS/Android/macOS/Windows/Linux). If testing on Web, this will crash without proper web FF setup.");
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE mess_sessions ADD COLUMN addons TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE expenses ADD COLUMN is_split INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE expenses ADD COLUMN split_with TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE alerts ADD COLUMN is_read INTEGER DEFAULT 0');
        }
        if (oldVersion < 5) {
          // Migration for goals table
          // Since it's a structural change, we recreate or add columns
          // Here we just add columns for simplicity, or recreate if needed.
          await db.execute('ALTER TABLE goals ADD COLUMN saving_rate REAL DEFAULT 0');
          await db.execute('ALTER TABLE goals ADD COLUMN rate_period TEXT DEFAULT "monthly"');
          await db.execute('ALTER TABLE goals ADD COLUMN created_at TEXT');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // ... rooms, expenses, splits, sessions as before ... (Keeping them unchanged)
    // ONLY UPDATING GOALS TABLE BELOW
    
    // ROOMMATES TABLE
    await db.execute('''
      CREATE TABLE roommates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // EXPENSES TABLE
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        payer_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        is_split INTEGER DEFAULT 0,
        split_with TEXT,
        FOREIGN KEY (payer_id) REFERENCES roommates (id)
      )
    ''');
    
    // EXPENSE SPLITS TABLE
    await db.execute('''
      CREATE TABLE expense_splits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id INTEGER NOT NULL,
        roommate_id INTEGER NOT NULL,
        amount_owed REAL NOT NULL,
        is_settled INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (expense_id) REFERENCES expenses (id),
        FOREIGN KEY (roommate_id) REFERENCES roommates (id)
      )
    ''');

    // MESS SESSIONS TABLE
    await db.execute('''
      CREATE TABLE mess_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_date TEXT NOT NULL,
        session_type TEXT NOT NULL,
        status TEXT NOT NULL,
        session_cost REAL NOT NULL,
        addons TEXT
      )
    ''');

    // GOALS TABLE (UPDATED)
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL,
        saving_rate REAL NOT NULL,
        rate_period TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // ALERTS TABLE
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER DEFAULT 0
      )
    ''');
  }

  // --- CRUD helpers can go below ---
  
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<int> update(String table, Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
