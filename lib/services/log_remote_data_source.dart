import 'package:logbook_app_060/features/models/log_model.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Abstraction for cloud log operations.
///
/// LogController depends on this interface, not on Mongo implementation,
/// so it can be tested with mocks.
abstract class LogRemoteDataSource {
  Future<List<LogModel>> getLogs([String? teamId]);
  Future<ObjectId?> insertLog(LogModel log);
  Future<void> updateLog(LogModel log);
  Future<void> deleteLog(ObjectId id);
}
