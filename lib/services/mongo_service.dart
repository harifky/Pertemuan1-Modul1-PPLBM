import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_060/features/models/log_model.dart';
import 'package:logbook_app_060/helpers/log_helper.dart';
import 'package:logbook_app_060/services/log_remote_data_source.dart';
import 'dart:async';

class MongoConnectionException implements Exception {
  final String message;

  const MongoConnectionException(this.message);

  @override
  String toString() => message;
}

/// MongoDB Service with Singleton pattern
/// Handles all CRUD operations with integrated logging
class MongoService implements LogRemoteDataSource {
  static final MongoService _instance = MongoService._internal();

  Db? _db;
  DbCollection? _collection;
  Future<void>? _connectFuture;
  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;
  MongoService._internal();

  bool _isConnectivityError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable') ||
        msg.contains('timed out') ||
        msg.contains('connection timeout');
  }

  MongoConnectionException _offlineException() {
    return const MongoConnectionException(
      "Offline Mode Warning: Tidak ada koneksi internet. Menampilkan data lokal terakhir.",
    );
  }

  /// Ensures collection is connected before operations
  Future<DbCollection> _getSafeCollection() async {
    if (_connectFuture != null) {
      await _connectFuture;
    }

    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "⚠️  Collection not ready, reconnecting...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    return _collection!;
  }

  /// Opens MongoDB connection and gets collection reference
  Future<void> connect() async {
    if (_db != null && _db!.isConnected && _collection != null) {
      return;
    }

    if (_connectFuture != null) {
      return _connectFuture;
    }

    final completer = Completer<void>();
    _connectFuture = completer.future;

    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) {
        throw Exception("MONGODB_URI not found in .env file");
      }

      final nextDb = Db(dbUri);
      await nextDb.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Connection timeout (15s)"),
      );

      _db = nextDb;
      _collection = nextDb.collection('logs');

      await LogHelper.writeLog(
        "✅ DATABASE: Connected successfully",
        source: _source,
        level: 2,
      );

      completer.complete();
    } catch (e) {
      _db = null;
      _collection = null;

      await LogHelper.writeLog(
        "❌ DATABASE: Connection failed - $e",
        source: _source,
        level: 1,
      );

      completer.completeError(e);

      if (_isConnectivityError(e)) {
        throw _offlineException();
      }

      rethrow;
    } finally {
      _connectFuture = null;
    }
  }

  /// Retrieves logs from cloud filtered by teamId for collaborative access
  /// This ensures users only see logs from their team
  @override
  Future<List<LogModel>> getLogs([String? teamId]) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        teamId != null
            ? "📥 Fetching logs for team: $teamId..."
            : "📥 Fetching all logs...",
        source: _source,
        level: 3,
      );

      // Collaborative filter: Only get logs for specific team
      final List<Map<String, dynamic>> data = teamId != null
          ? await collection.find(where.eq('teamId', teamId)).toList()
          : await collection.find().toList();

      await LogHelper.writeLog(
        "✅ Fetched ${data.length} logs",
        source: _source,
        level: 3,
      );

      return data.map((json) {
        // Backward compatibility for older documents that do not have isPublic.
        json['isPublic'] ??= false;
        return LogModel.fromMap(json);
      }).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Fetch failed - $e",
        source: _source,
        level: 1,
      );

      if (e is MongoConnectionException || _isConnectivityError(e)) {
        throw _offlineException();
      }

      rethrow;
    }
  }

  /// Inserts new log to cloud
  @override
  Future<ObjectId?> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();

      if (log.id == null) {
        throw Exception("Log ID is required for cloud insert");
      }

      final objectId = ObjectId.fromHexString(log.id!);

      // Duplicate guard: skip insert if document already exists in cloud.
      final existing = await collection.findOne(where.id(objectId));
      if (existing != null) {
        await LogHelper.writeLog(
          "♻️  Skipped duplicate insert for '${log.title}' (ID: ${log.id})",
          source: _source,
          level: 3,
        );
        return objectId;
      }

      await LogHelper.writeLog(
        "📤 Inserting: '${log.title}'...",
        source: _source,
        level: 3,
      );

      final result = await collection.insertOne(log.toMap());
      final insertedId = result.id as ObjectId?;

      await LogHelper.writeLog(
        "✅ Saved '${log.title}' (ID: $insertedId)",
        source: _source,
        level: 2,
      );

      return insertedId;
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Insert failed - $e",
        source: _source,
        level: 1,
      );

      if (e is MongoConnectionException || _isConnectivityError(e)) {
        throw _offlineException();
      }

      rethrow;
    }
  }

  /// Updates log by ID
  @override
  Future<void> updateLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();

      if (log.id == null) {
        throw Exception("Log ID not found for update");
      }

      await LogHelper.writeLog(
        "✏️  Updating: '${log.title}' (ID: ${log.id})...",
        source: _source,
        level: 3,
      );

      await collection.replaceOne(
        where.id(ObjectId.fromHexString(log.id!)),
        log.toMap(),
      );

      await LogHelper.writeLog(
        "✅ Updated '${log.title}'",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Update failed - $e",
        source: _source,
        level: 1,
      );

      if (e is MongoConnectionException || _isConnectivityError(e)) {
        throw _offlineException();
      }

      rethrow;
    }
  }

  /// Deletes log by ID
  @override
  Future<void> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "🗑️  Deleting: ID $id...",
        source: _source,
        level: 3,
      );

      await collection.remove(where.id(id));

      await LogHelper.writeLog(
        "✅ Deleted successfully",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Delete failed - $e",
        source: _source,
        level: 1,
      );

      if (e is MongoConnectionException || _isConnectivityError(e)) {
        throw _offlineException();
      }

      rethrow;
    }
  }

  /// Closes database connection
  Future<void> close() async {
    try {
      if (_db != null && _db!.isConnected) {
        await _db!.close();
        await LogHelper.writeLog(
          "🔌 DATABASE: Closed",
          source: _source,
          level: 2,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "⚠️  Close error: $e",
        source: _source,
        level: 3,
      );
    }
  }

  /// Returns connection status
  bool get isConnected => _db != null && _db!.isConnected;

  /// Returns masked MongoDB URI for security
  String get mongoUri {
    final dbUri = dotenv.env['MONGODB_URI'] ?? 'NOT_SET';
    return dbUri.replaceAll(RegExp(r':([^@]+)@'), ':****@');
  }
}
