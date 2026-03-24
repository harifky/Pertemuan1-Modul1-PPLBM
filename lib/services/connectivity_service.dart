import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logbook_app_060/helpers/log_helper.dart';

/// Connectivity Service: Auto-sync when network returns
/// Listens for network state changes and triggers sync operations
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final String _source = "connectivity_service.dart";

  bool _wasOffline = false;
  Function? _onReconnect;

  /// Start listening for connectivity changes
  /// Provide callback to execute when connection is restored
  void startListening({Function? onReconnect}) {
    _onReconnect = onReconnect;

    _subscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      final isOnline =
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      if (isOnline && _wasOffline) {
        // Connection restored!
        await LogHelper.writeLog(
          "🌐 NETWORK RESTORED: Triggering auto-sync...",
          source: _source,
          level: 2,
        );

        // Execute callback (e.g., sync data)
        if (_onReconnect != null) {
          try {
            await _onReconnect!();
            await LogHelper.writeLog(
              "✅ AUTO-SYNC: Data synchronized successfully",
              source: _source,
              level: 2,
            );
          } catch (e) {
            await LogHelper.writeLog(
              "❌ AUTO-SYNC FAILED: $e",
              source: _source,
              level: 1,
            );
          }
        }

        _wasOffline = false;
      } else if (!isOnline) {
        // Connection lost
        await LogHelper.writeLog(
          "📴 NETWORK LOST: Switching to offline mode",
          source: _source,
          level: 2,
        );
        _wasOffline = true;
      }
    });

    LogHelper.writeLog(
      "📡 Connectivity listener started",
      source: _source,
      level: 3,
    );
  }

  /// Stop listening for connectivity changes
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;

    LogHelper.writeLog(
      "📡 Connectivity listener stopped",
      source: _source,
      level: 3,
    );
  }

  /// Check current connectivity status
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Error checking connectivity: $e",
        source: _source,
        level: 1,
      );
      return false;
    }
  }
}
