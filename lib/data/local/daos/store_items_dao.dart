import 'package:sqflite/sqflite.dart';

import '../../../domain/entities/item_dish.dart';
import '../../../domain/entities/item_gulay.dart';
import '../../../domain/entities/item_rice.dart';
import '../database.dart';

class StoreItemsDao {
  Future<Database> get _db => AppDatabase.instance;

  // ── Gulay (Produce) ─────────────────────────────────────────────────────────

  Future<ItemGulay?> getGulay(String itemId) async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      'item_gulay',
      where: 'item_id = ?',
      whereArgs: <String>[itemId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ItemGulay.fromMap(rows.first);
  }

  Future<List<ItemGulay>> getAllGulay() async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.query('item_gulay');
    return rows.map(ItemGulay.fromMap).toList();
  }

  Future<void> upsertGulay(ItemGulay gulay) async {
    final Database db = await _db;
    await db.insert(
      'item_gulay',
      gulay.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateGulayStock(String itemId, double newStockKg) async {
    final Database db = await _db;
    await db.update(
      'item_gulay',
      <String, dynamic>{'stock_kg': newStockKg},
      where: 'item_id = ?',
      whereArgs: <String>[itemId],
    );
  }

  // ── Rice (Bigasan) ──────────────────────────────────────────────────────────

  Future<ItemRice?> getRice(String itemId) async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      'item_rice',
      where: 'item_id = ?',
      whereArgs: <String>[itemId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ItemRice.fromMap(rows.first);
  }

  Future<List<ItemRice>> getAllRice() async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.query('item_rice');
    return rows.map(ItemRice.fromMap).toList();
  }

  Future<void> upsertRice(ItemRice rice) async {
    final Database db = await _db;
    await db.insert(
      'item_rice',
      rice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRiceStock(String itemId, double newStockKg) async {
    final Database db = await _db;
    await db.update(
      'item_rice',
      <String, dynamic>{'stock_kg': newStockKg},
      where: 'item_id = ?',
      whereArgs: <String>[itemId],
    );
  }

  // ── Dish (Carinderia) ───────────────────────────────────────────────────────

  Future<ItemDish?> getDish(String itemId) async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      'item_dish',
      where: 'item_id = ?',
      whereArgs: <String>[itemId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ItemDish.fromMap(rows.first);
  }

  Future<List<ItemDish>> getAllDishes() async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.query('item_dish');
    return rows.map(ItemDish.fromMap).toList();
  }

  Future<void> upsertDish(ItemDish dish) async {
    final Database db = await _db;
    await db.insert(
      'item_dish',
      dish.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> decrementDishPortion(String itemId, [int count = 1]) async {
    final Database db = await _db;
    await db.rawUpdate(
      'UPDATE item_dish SET portions_left = MAX(0, portions_left - ?) WHERE item_id = ?',
      <Object>[count, itemId],
    );
  }
}
