import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart' as hive;
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:logbook_app_060/services/mongo_service.dart';
import 'package:logbook_app_060/services/log_remote_data_source.dart';
import 'package:logbook_app_060/services/user_context_service.dart';
import 'package:logbook_app_060/helpers/log_helper.dart';
import '../models/log_model.dart';

/// Hybrid Sync Controller: Hive (Primary/Local) + MongoDB (Secondary/Cloud)
/// Implements Offline-First strategy for fault-tolerant collaborative app
class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  final LogRemoteDataSource _remoteDataSource;
  late final hive.Box<LogModel> _myBox;
  final String _source = "log_controller.dart";

  LogController({
    LogRemoteDataSource? remoteDataSource,
    hive.Box<LogModel>? localBox,
  }) : _remoteDataSource = remoteDataSource ?? MongoService() {
    _myBox = localBox ?? hive.Hive.box<LogModel>('offline_logs');
  }

  /// Visibility filter:
  /// - Catatan private (isPublic = false) hanya bisa dilihat pemiliknya.
  /// - Catatan public (isPublic = true) hanya bisa dilihat user satu tim.
  List<LogModel> filterVisibleLogs(
    List<LogModel> allLogs,
    String currentUserId,
    String currentTeamId,
  ) {
    return allLogs.where((log) {
      if (log.isDeleted) {
        return log.authorId == currentUserId;
      }

      return log.authorId == currentUserId ||
          (log.isPublic && log.teamId == currentTeamId);
    }).toList();
  }

  List<LogModel> _teamLogsFromLocal(
    String teamId, {
    bool includeDeleted = false,
  }) {
    return _myBox.values.where((log) {
      return log.teamId == teamId && (includeDeleted || !log.isDeleted);
    }).toList();
  }

  Future<void> _removeLocalById(String logId) async {
    for (var i = 0; i < _myBox.length; i++) {
      final current = _myBox.getAt(i);
      if (current?.id == logId) {
        await _myBox.deleteAt(i);
        break;
      }
    }
  }

  Future<void> _replaceTeamLogs(String teamId, List<LogModel> logs) async {
    final keysToDelete = <int>[];
    for (var i = 0; i < _myBox.length; i++) {
      final log = _myBox.getAt(i);
      if (log?.teamId == teamId) {
        keysToDelete.add(i);
      }
    }

    for (final key in keysToDelete.reversed) {
      await _myBox.deleteAt(key);
    }

    await _myBox.addAll(logs);
  }

  Future<void> _markSyncedInLocalAndNotifier(String logId, bool synced) async {
    // Catat waktu sinkronisasi ke MongoDB
    final syncTimestamp = synced ? DateTime.now().toIso8601String() : null;

    for (var i = 0; i < _myBox.length; i++) {
      final current = _myBox.getAt(i);
      if (current?.id == logId) {
        final updated = LogModel(
          id: current!.id,
          title: current.title,
          description: current.description,
          date: current.date,
          authorId: current.authorId,
          teamId: current.teamId,
          isPublic: current.isPublic,
          isSynced: synced,
          category: current.category,
          syncedAt: syncTimestamp ?? current.syncedAt,
          isDeleted: current.isDeleted,
        );
        await _myBox.putAt(i, updated);
        break;
      }
    }

    final updatedNotifier = logsNotifier.value.map((log) {
      if (log.id == logId) {
        return LogModel(
          id: log.id,
          title: log.title,
          description: log.description,
          date: log.date,
          authorId: log.authorId,
          teamId: log.teamId,
          isPublic: log.isPublic,
          isSynced: synced,
          category: log.category,
          syncedAt: syncTimestamp ?? log.syncedAt,
          isDeleted: log.isDeleted,
        );
      }
      return log;
    }).toList();
    logsNotifier.value = updatedNotifier;
  }

  Future<int> _syncPendingLocalLogs(String teamId) async {
    int syncedCount = 0;
    final pendingLogs = _teamLogsFromLocal(
      teamId,
      includeDeleted: true,
    ).where((log) => !log.isSynced && !log.isDeleted).toList();

    for (final pending in pendingLogs) {
      try {
        await _remoteDataSource.insertLog(pending);
        if (pending.id != null) {
          await _markSyncedInLocalAndNotifier(pending.id!, true);
        }
        syncedCount++;
      } catch (_) {
        // Keep pending log in local queue for next reconnect attempt.
      }
    }

    return syncedCount;
  }

  Future<int> _syncPendingDeletedLogs(String teamId) async {
    int deletedCount = 0;
    final pendingDeletes = _teamLogsFromLocal(
      teamId,
      includeDeleted: true,
    ).where((log) => log.isDeleted).toList();

    for (final pendingDelete in pendingDeletes) {
      final logId = pendingDelete.id;
      if (logId == null) {
        continue;
      }

      try {
        await _remoteDataSource.deleteLog(mongo.ObjectId.fromHexString(logId));
        await _removeLocalById(logId);
        deletedCount++;
      } catch (_) {
        // Keep tombstone locally until next reconnect attempt.
      }
    }

    return deletedCount;
  }

  List<LogModel> _mergeWithoutDuplicate({
    required List<LogModel> cloudLogs,
    required List<LogModel> pendingLocalLogs,
    required Set<String> deletedLocalIds,
  }) {
    final mergedById = <String, LogModel>{};

    for (final cloudLog in cloudLogs) {
      if (cloudLog.id != null && !deletedLocalIds.contains(cloudLog.id)) {
        mergedById[cloudLog.id!] = LogModel(
          id: cloudLog.id,
          title: cloudLog.title,
          description: cloudLog.description,
          date: cloudLog.date,
          authorId: cloudLog.authorId,
          teamId: cloudLog.teamId,
          isPublic: cloudLog.isPublic,
          isSynced: true,
          category: cloudLog.category,
          // Tandai waktu sinkronisasi jika belum ada
          syncedAt: cloudLog.syncedAt ?? DateTime.now().toIso8601String(),
          isDeleted: false,
        );
      }
    }

    for (final localLog in pendingLocalLogs) {
      final key = localLog.id;
      if (key != null && !mergedById.containsKey(key)) {
        mergedById[key] = localLog;
      }
    }

    return mergedById.values.toList();
  }

  /// STEP 1: LOAD DATA (Offline-First Strategy)
  /// Instantly loads from Hive, then syncs with Cloud in background
  Future<void> loadLogs(String teamId) async {
    try {
      // ACTION 1: Load from Hive instantly (< 1ms)
      logsNotifier.value = _teamLogsFromLocal(teamId, includeDeleted: true);

      await LogHelper.writeLog(
        "📦 Loaded ${logsNotifier.value.length} logs from local cache (Hive)",
        source: _source,
        level: 3,
      );

      // ACTION 2: Sync from Cloud in background
      try {
        final deletedPendingCount = await _syncPendingDeletedLogs(teamId);
        final syncedPendingCount = await _syncPendingLocalLogs(teamId);
        final cloudData = await _remoteDataSource.getLogs(teamId);

        final pendingLocal = _teamLogsFromLocal(
          teamId,
          includeDeleted: true,
        ).where((log) => !log.isDeleted && !log.isSynced).toList();

        final pendingDeleted = _teamLogsFromLocal(
          teamId,
          includeDeleted: true,
        ).where((log) => log.isDeleted).toList();

        final mergedLogs = _mergeWithoutDuplicate(
          cloudLogs: cloudData,
          pendingLocalLogs: pendingLocal,
          deletedLocalIds: pendingDeleted
              .map((log) => log.id)
              .whereType<String>()
              .toSet(),
        );

        await _replaceTeamLogs(teamId, [...mergedLogs, ...pendingDeleted]);
        logsNotifier.value = [...mergedLogs, ...pendingDeleted];

        await LogHelper.writeLog(
          "☁️  SYNC: ${cloudData.length} cloud logs, $syncedPendingCount pending synced, $deletedPendingCount pending deleted",
          source: _source,
          level: 2,
        );
      } catch (mongoError) {
        await LogHelper.writeLog(
          "📴 OFFLINE: Using local cache - $mongoError",
          source: _source,
          level: 2,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Error loading logs: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// STEP 2: ADD DATA (Instant Local + Background Cloud)
  /// Saves immediately to Hive, then syncs to MongoDB in background
  Future<void> addLog(
    String title,
    String desc,
    String authorId,
    String teamId,
    bool isPublic, [
    String category = 'Software',
  ]) async {
    try {
      final objectId = mongo.ObjectId();
      // Catat waktu pembuatan catatan oleh pengguna (tidak berubah saat edit)
      final createdAt = DateTime.now().toIso8601String();
      final newLog = LogModel(
        id: objectId.oid,
        title: title,
        description: desc,
        date: createdAt,
        authorId: authorId,
        teamId: teamId,
        isPublic: isPublic,
        isSynced: false,
        category: category,
      );

      // ACTION 1: Save to Hive instantly
      await _myBox.add(newLog);
      logsNotifier.value = [...logsNotifier.value, newLog];

      await LogHelper.writeLog(
        "💾 Log '$title' saved locally (Hive)",
        source: _source,
        level: 3,
      );

      // ACTION 2: Sync to Cloud in background
      try {
        await _remoteDataSource.insertLog(newLog);
        await _markSyncedInLocalAndNotifier(newLog.id!, true);

        await LogHelper.writeLog(
          "☁️  SUCCESS: '$title' synced to Cloud",
          source: _source,
          level: 2,
        );
      } catch (mongoError) {
        await LogHelper.writeLog(
          "⚠️  WARNING: '$title' saved locally, will sync when online - $mongoError",
          source: _source,
          level: 1,
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

  /// STEP 3: UPDATE DATA (Instant Local + Background Cloud)
  Future<void> updateLog(
    int index,
    String title,
    String desc,
    bool isPublic, [
    String category = 'Software',
  ]) async {
    try {
      final currentLog = logsNotifier.value[index];
      final updatedLog = LogModel(
        id: currentLog.id,
        title: title,
        description: desc,
        // BUGFIX: Pertahankan tanggal pembuatan asli — jangan diubah saat edit
        date: currentLog.date,
        authorId: currentLog.authorId,
        teamId: currentLog.teamId,
        isPublic: isPublic,
        isSynced: false,
        category: category,
        syncedAt: currentLog.syncedAt,
        isDeleted: false,
      );

      // Find Hive key by matching log
      int? hiveKey;
      for (var i = 0; i < _myBox.length; i++) {
        final log = _myBox.getAt(i);
        if (log?.id == currentLog.id) {
          hiveKey = i;
          break;
        }
      }

      // ACTION 1: Update in Hive instantly
      if (hiveKey != null) {
        await _myBox.putAt(hiveKey, updatedLog);
      }

      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "💾 Log '$title' updated locally (Hive)",
        source: _source,
        level: 3,
      );

      // ACTION 2: Sync to Cloud in background
      if (currentLog.id != null) {
        try {
          await _remoteDataSource.updateLog(updatedLog);
          await _markSyncedInLocalAndNotifier(currentLog.id!, true);

          await LogHelper.writeLog(
            "☁️  SUCCESS: '$title' updated in Cloud",
            source: _source,
            level: 2,
          );
        } catch (mongoError) {
          await LogHelper.writeLog(
            "⚠️  WARNING: '$title' updated locally, will sync when online - $mongoError",
            source: _source,
            level: 1,
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

  /// STEP 4: DELETE DATA (Instant Local + Background Cloud)
  Future<void> removeLog(int index) async {
    try {
      final logToDelete = logsNotifier.value[index];

      // Find Hive key by matching log
      int? hiveKey;
      for (var i = 0; i < _myBox.length; i++) {
        final log = _myBox.getAt(i);
        if (log?.id == logToDelete.id) {
          hiveKey = i;
          break;
        }
      }

      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;

      final existsInCloud = logToDelete.syncedAt != null;

      // Local-only unsynced note can be removed immediately.
      if (!existsInCloud) {
        if (hiveKey != null) {
          await _myBox.deleteAt(hiveKey);
        }

        await LogHelper.writeLog(
          "💾 Unsynced local log '${logToDelete.title}' removed permanently",
          source: _source,
          level: 3,
        );
        return;
      }

      // Keep tombstone locally when deleting cloud-backed data offline.
      if (hiveKey != null) {
        await _myBox.putAt(
          hiveKey,
          logToDelete.copyWith(isDeleted: true, isSynced: false),
        );
      }

      await LogHelper.writeLog(
        "💾 Log '${logToDelete.title}' marked deleted locally (Hive tombstone)",
        source: _source,
        level: 3,
      );

      // ACTION 2: Delete from Cloud in background
      if (logToDelete.id != null) {
        try {
          await _remoteDataSource.deleteLog(
            mongo.ObjectId.fromHexString(logToDelete.id!),
          );
          await _removeLocalById(logToDelete.id!);

          await LogHelper.writeLog(
            "☁️  SUCCESS: '${logToDelete.title}' deleted from Cloud",
            source: _source,
            level: 2,
          );
        } catch (mongoError) {
          await LogHelper.writeLog(
            "⚠️  WARNING: '${logToDelete.title}' deleted locally, will sync when online - $mongoError",
            source: _source,
            level: 1,
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

  /// BACKWARD COMPATIBILITY: Alias methods for existing UI code
  Future<void> addLogAsync(
    String title,
    String desc, {
    required String authorId,
    required String teamId,
    bool isPublic = false,
    String category = 'Software',
  }) => addLog(title, desc, authorId, teamId, isPublic, category);

  Future<void> updateLogAsync(
    int index,
    String title,
    String desc, {
    required bool isPublic,
    String category = 'Software',
  }) => updateLog(index, title, desc, isPublic, category);

  Future<void> removeLogAsync(int index) => removeLog(index);

  Future<void> loadFromCloudAsync() async {
    final teamId = await UserContextService.getTeamId();
    await loadLogs(teamId);
  }

  /// Deletes log by ObjectId (safer for FutureBuilder pattern)
  /// WITH SECURITY VALIDATION: Checks user permission before deletion
  Future<void> removeLogByObjectId(mongo.ObjectId id, String title) async {
    try {
      final userId = await UserContextService.getUserId();

      // Find the log locally first
      final targetLog = logsNotifier.value.firstWhere(
        (log) => log.id == id.oid,
        orElse: () => throw Exception('Log not found'),
      );

      // Determine if user is owner
      final isOwner = targetLog.authorId == userId;

      // SECURITY CHECK: owner-only sovereignty (role is ignored)
      if (!isOwner) {
        await LogHelper.writeLog(
          "🚨 PRIVACY BLOCK: User '$userId' attempted unauthorized delete of '$title'",
          source: _source,
          level: 1,
        );
        throw Exception('Owner only: hanya pemilik yang boleh menghapus');
      }

      // Permission granted, find index and delete
      final indexToDelete = logsNotifier.value.indexWhere(
        (log) => log.id == id.oid,
      );

      if (indexToDelete != -1) {
        await removeLog(indexToDelete);
        await LogHelper.writeLog(
          "✅ Log '$title' deleted by user '$userId'",
          source: _source,
          level: 2,
        );
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

  Future<void> syncPendingLogs(String teamId) async {
    await _syncPendingDeletedLogs(teamId);
    await _syncPendingLocalLogs(teamId);
  }
}
