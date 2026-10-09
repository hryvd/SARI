import 'package:sqflite/sqflite.dart';

import '../../../domain/entities/store_profile.dart';
import '../database.dart';

class StoreProfileDao {
  Future<Database> get _db => AppDatabase.instance;

  Future<StoreProfile?> getProfile() async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      'store_profile',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return StoreProfile.fromMap(rows.first);
  }

  Future<void> saveProfile(StoreProfile profile) async {
    final Database db = await _db;
    await db.insert(
      'store_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStoreType(String storeType) async {
    final Database db = await _db;
    final StoreProfile? current = await getProfile();
    if (current != null) {
      await db.update(
        'store_profile',
        <String, dynamic>{'store_type': storeType},
        where: 'id = ?',
        whereArgs: <String>[current.id],
      );
    } else {
      await saveProfile(
        StoreProfile(
          id: 'default_store',
          storeType: storeType,
          storeName: 'My Store',
          ownerName: 'Owner',
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> deleteAll() async {
    final Database db = await _db;
    await db.delete('store_profile');
  }
}
