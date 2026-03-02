import 'dart:developer' as dev;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class LogHelper {
  static Directory? _logsDir;

  /// Initialize logs directory for daily log files
  static Future<void> initializeLogging() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _logsDir = Directory('${appDir.path}/logs');
      if (!await _logsDir!.exists()) {
        await _logsDir!.create(recursive: true);
        dev.log("Logs directory created", name: "LogHelper");
      }
    } catch (e) {
      dev.log("Cannot initialize logs: $e", name: "LogHelper");
    }
  }

  /// Log message with verbosity and source filtering
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2,
  }) async {
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    if (level > configLevel) return;

    final List<String> mutedFiles = (dotenv.env['LOG_MUTE'] ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (mutedFiles.contains(source)) return;

    try {
      final now = DateTime.now();
      final timestamp = DateFormat('HH:mm:ss').format(now);
      final fullTimestamp = DateFormat('dd-MM-yyyy HH:mm:ss').format(now);
      final label = _getLabel(level);
      final color = _getColor(level);

      final logMessage = '[$fullTimestamp] [$label] [$source] -> $message';

      // Debug console
      dev.log(message, name: source, time: now, level: level * 100);

      // Terminal output (only if LOG_LEVEL >= 3)
      if (configLevel >= 3) {
        print('$color[$timestamp][$label][$source] -> $message\x1B[0m');
      }

      // File logging
      await _writeToLogFile(logMessage, now);
    } catch (e) {
      dev.log("Logging error: $e", name: "SYSTEM");
    }
  }

  /// Write log message to daily log file
  static Future<void> _writeToLogFile(String logMessage, DateTime now) async {
    try {
      if (_logsDir == null) await initializeLogging();
      if (_logsDir == null) return;

      final dateFileName = DateFormat('dd-MM-yyyy').format(now);
      final logFile = File('${_logsDir!.path}/$dateFileName.log');

      if (!await logFile.exists()) {
        await logFile.create(recursive: true);
      }

      await logFile.writeAsString('$logMessage\n', mode: FileMode.append);
    } catch (e) {
      dev.log("File write error: $e", name: "LogHelper");
    }
  }

  static String _getLabel(int level) {
    return switch (level) {
      1 => "ERROR",
      2 => "INFO",
      3 => "VERBOSE",
      _ => "LOG",
    };
  }

  static String _getColor(int level) {
    return switch (level) {
      1 => '\x1B[31m', // Red
      2 => '\x1B[32m', // Green
      3 => '\x1B[34m', // Blue
      _ => '\x1B[0m',
    };
  }
}
