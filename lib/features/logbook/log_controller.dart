import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_060/services/mongo_service.dart';
import 'package:logbook_app_060/helpers/log_helper.dart';
import '../models/log_model.dart';

/// Manages logs with dual storage: local (SharedPreferences) and cloud (MongoDB)
/// All CRUD operations sync automatically to both storage layers
class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  late final String _storageKey;
  final String username;
  final String _source = "log_controller.dart";

  LogController(this.username) {
    _storageKey = 'logs_$username';
    print('[INIT] LogController for user: $username');
  }

  /// Adds new log to local storage and syncs to cloud
  Future<void> addLogAsync(
    String title,
    String desc, {
    LogCategory category = LogCategory.pribadi,
  }) async {
    try {
      final newLog = LogModel(
        title: title,
        description: desc,
        date: DateTime.now().toString(),
        category: category,
      );

      logsNotifier.value = [...logsNotifier.value, newLog];
      await saveToDisk();

      // Sync to cloud
      try {
        final mongoService = MongoService();
        final insertedId = await mongoService.insertLog(newLog);

        if (insertedId != null) {
          final indexToUpdate = logsNotifier.value.indexWhere(
            (log) => log.title == title,
          );
          if (indexToUpdate != -1) {
            final updatedLogs = List<LogModel>.from(logsNotifier.value);
            updatedLogs[indexToUpdate] = LogModel(
              id: insertedId,
              title: newLog.title,
              date: newLog.date,
              description: newLog.description,
              category: newLog.category,
            );
            logsNotifier.value = updatedLogs;
            await saveToDisk();
          }
        }

        await LogHelper.writeLog(
          "✅ Log '$title' added locally & synced to cloud",
          source: _source,
          level: 2,
        );
      } catch (mongoError) {
        await LogHelper.writeLog(
          "⚠️  Log '$title' added locally but cloud sync failed: $mongoError",
          source: _source,
          level: 2,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Error adding log: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// Updates log and syncs to cloud
  Future<void> updateLogAsync(
    int index,
    String title,
    String desc, {
    LogCategory category = LogCategory.pribadi,
  }) async {
    try {
      final currentLog = logsNotifier.value[index];
      final updatedLog = LogModel(
        id: currentLog.id,
        title: title,
        description: desc,
        date: DateTime.now().toString(),
        category: category,
      );

      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;
      await saveToDisk();

      if (currentLog.id != null) {
        try {
          final mongoService = MongoService();
          await mongoService.updateLog(updatedLog);

          await LogHelper.writeLog(
            "✅ Log '$title' updated locally & synced to cloud",
            source: _source,
            level: 2,
          );
        } catch (mongoError) {
          await LogHelper.writeLog(
            "⚠️  Log '$title' updated locally but cloud sync failed: $mongoError",
            source: _source,
            level: 2,
          );
        }
      }
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Error updating log: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// Deletes log by ObjectId (safer for FutureBuilder pattern)
  Future<void> removeLogByObjectId(ObjectId id, String title) async {
    try {
      final mongoService = MongoService();
      await mongoService.deleteLog(id);

      await LogHelper.writeLog(
        "✅ Log '$title' deleted from cloud",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Error deleting log: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// Deletes log and syncs to cloud
  Future<void> removeLogAsync(int index) async {
    try {
      final logToDelete = logsNotifier.value[index];

      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;
      await saveToDisk();

      if (logToDelete.id != null) {
        try {
          final mongoService = MongoService();
          await mongoService.deleteLog(logToDelete.id!);

          await LogHelper.writeLog(
            "✅ Log '${logToDelete.title}' deleted locally & synced to cloud",
            source: _source,
            level: 2,
          );
        } catch (mongoError) {
          await LogHelper.writeLog(
            "⚠️  Log '${logToDelete.title}' deleted locally but cloud sync failed: $mongoError",
            source: _source,
            level: 2,
          );
        }
      }
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Error deleting log: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// Synchronous add for backward compatibility
  void addLog(
    String title,
    String desc, {
    LogCategory category = LogCategory.pribadi,
  }) {
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );
    logsNotifier.value = [...logsNotifier.value, newLog];
    saveToDisk();
  }

  /// Synchronous update for backward compatibility
  void updateLog(
    int index,
    String title,
    String desc, {
    LogCategory category = LogCategory.pribadi,
  }) {
    final updatedLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs[index] = updatedLog;
    logsNotifier.value = currentLogs;
    saveToDisk();
  }

  /// Synchronous delete for backward compatibility
  void removeLog(int index) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    saveToDisk();
  }

  /// Saves logs to local disk via SharedPreferences
  Future<void> saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapList = logsNotifier.value.map((e) => e.toMap()).toList();
      final encodedData = jsonEncode(mapList);
      await prefs.setString(_storageKey, encodedData);
    } catch (e) {
      print('❌ [SAVE ERROR] $e');
    }
  }

  /// Fetches logs from MongoDB cloud
  Future<void> loadFromCloudAsync() async {
    try {
      await LogHelper.writeLog(
        "🌐 Fetching logs from cloud...",
        source: _source,
        level: 3,
      );

      final mongoService = MongoService();
      final cloudLogs = await mongoService.getLogs();

      logsNotifier.value = cloudLogs;
      await saveToDisk();

      await LogHelper.writeLog(
        "✅ Fetched ${cloudLogs.length} logs from cloud",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "⚠️  Cloud fetch failed, using local cache: $e",
        source: _source,
        level: 2,
      );
      await loadFromDisk();
    }
  }

  /// Loads logs from local disk via SharedPreferences
  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);

      if (data != null) {
        final List decoded = jsonDecode(data);
        final logs = decoded.map((e) => LogModel.fromMap(e)).toList();
        logsNotifier.value = logs;
        print('✅ [LOAD-DISK] Loaded ${logs.length} logs');
      }
    } catch (e) {
      print('❌ [LOAD-DISK ERROR] $e');
    }
  }
}
