import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _db;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initializeDatabase();
    return _db!;
  }

  Future<Database> _initializeDatabase() async {
    String dbPath = join(await getDatabasesPath(), 'app_data.db');
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            item_id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_name TEXT NOT NULL,
            item_cost REAL NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE plans (
            plan_id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_date TEXT NOT NULL,
            plan_items TEXT NOT NULL,
            plan_budget REAL NOT NULL
          );
        ''');
      },
    );
  }

  Future<void> addItem(String itemName, double itemCost) async {
    final dbInstance = await database;
    await dbInstance.insert('items', {'item_name': itemName, 'item_cost': itemCost});
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final dbInstance = await database;
    return await dbInstance.query('items');
  }

  Future<void> removeItem(int itemId) async {
    final dbInstance = await database;
    await dbInstance.delete('items', where: 'item_id = ?', whereArgs: [itemId]);
  }

  Future<void> updateItem(int itemId, String itemName, double itemCost) async {
    final dbInstance = await database;
    await dbInstance.update(
      'items',
      {'item_name': itemName, 'item_cost': itemCost},
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> addPlan(String planDate, String planItems, double planBudget) async {
    final dbInstance = await database;
    await dbInstance.insert('plans', {
      'plan_date': planDate,
      'plan_items': planItems,
      'plan_budget': planBudget,
    });
  }

  Future<List<Map<String, dynamic>>> getPlansByDate(String planDate) async {
    final dbInstance = await database;
    return await dbInstance.query('plans', where: 'plan_date = ?', whereArgs: [planDate]);
  }

  Future<List<Map<String, dynamic>>> getAllPlans() async {
    final dbInstance = await database;
    return await dbInstance.query('plans');
  }

  Future<void> removePlan(int planId) async {
    final dbInstance = await database;
    await dbInstance.delete('plans', where: 'plan_id = ?', whereArgs: [planId]);
  }

  Future<void> updatePlan(int planId, String planItems, String planBudget) async {
    final dbInstance = await database;
    await dbInstance.update(
      'plans',
      {'plan_items': planItems, 'plan_budget': planBudget},
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
  }
}
