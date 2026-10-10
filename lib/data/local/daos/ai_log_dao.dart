import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';

class AiLogEntry {
  const AiLogEntry({
    required this.id,
    required this.userId,
    required this.inputText,
    required this.intent,
    required this.slots,
    required this.confidence,
    required this.wasCorrected,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String inputText;
  final String intent;
  final Map<String, dynamic> slots;
  final double confidence;
  final bool wasCorrected;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'user_id': userId,
        'input_text': inputText,
        'intent': intent,
        'slots_json': jsonEncode(slots),
        'confidence': confidence,
        'was_corrected': wasCorrected ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory AiLogEntry.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedSlots = <String, dynamic>{};
    try {
      final String raw = map['slots_json'] as String? ?? '{}';
      parsedSlots = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}

    return AiLogEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      inputText: map['input_text'] as String,
      intent: map['intent'] as String,
      slots: parsedSlots,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      wasCorrected: (map['was_corrected'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class AiLogDao {
  Future<Database> get _db => AppDatabase.instance;
  static const Uuid _uuid = Uuid();

  Future<void> recordLog({
    required String inputText,
    required String intent,
    required Map<String, dynamic> slots,
    double confidence = 1.0,
    String userId = 'local_user',
    bool wasCorrected = false,
  }) async {
    try {
      final Database db = await _db;
      final AiLogEntry entry = AiLogEntry(
        id: _uuid.v4(),
        userId: userId,
        inputText: inputText,
        intent: intent,
        slots: slots,
        confidence: confidence,
        wasCorrected: wasCorrected,
        createdAt: DateTime.now(),
      );
      await db.insert(
        'ai_command_log',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Offline / Test environment safe fallback
    }
  }

  Future<List<AiLogEntry>> getRecentLogs({int limit = 30}) async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.query(
      'ai_command_log',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(AiLogEntry.fromMap).toList();
  }

  Future<void> markAsCorrected(String logId) async {
    final Database db = await _db;
    await db.update(
      'ai_command_log',
      <String, dynamic>{'was_corrected': 1},
      where: 'id = ?',
      whereArgs: <String>[logId],
    );
  }
}
