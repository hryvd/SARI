import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';

class RestockDraftEntry {
  const RestockDraftEntry({
    required this.id,
    required this.title,
    required this.lines,
    required this.totalCost,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<Map<String, dynamic>> lines;
  final double totalCost;
  final String status; // 'open', 'confirmed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'lines_json': jsonEncode(lines),
        'total_cost': totalCost,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory RestockDraftEntry.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> lines = <Map<String, dynamic>>[];
    try {
      final String raw = map['lines_json'] as String? ?? '[]';
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        lines = decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    return RestockDraftEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      lines: lines,
      totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'open',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class RestockDraftDao {
  Future<Database> get _db => AppDatabase.instance;
  static const Uuid _uuid = Uuid();

  Future<void> saveDraft({
    required String title,
    required List<Map<String, dynamic>> lines,
    required double totalCost,
    String status = 'open',
  }) async {
    final Database db = await _db;
    final DateTime now = DateTime.now();
    final RestockDraftEntry entry = RestockDraftEntry(
      id: _uuid.v4(),
      title: title,
      lines: lines,
      totalCost: totalCost,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert(
      'restock_drafts',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RestockDraftEntry>> getOpenDrafts() async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      'restock_drafts',
      where: 'status = ?',
      whereArgs: <String>['open'],
      orderBy: 'created_at DESC',
    );
    return rows.map(RestockDraftEntry.fromMap).toList();
  }

  Future<void> updateStatus(String id, String newStatus) async {
    final Database db = await _db;
    await db.update(
      'restock_drafts',
      <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <String>[id],
    );
  }
}
