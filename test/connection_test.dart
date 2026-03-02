import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_060/services/mongo_service.dart';
import 'package:logbook_app_060/helpers/log_helper.dart';

void main() {
  const String sourceFile = "connection_test.dart";

  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  // ========== TASK 2: Cloud Connector (LOTS) Smoke Testing ==========
  test('Smoke Test: SUCCESS: Terhubung ke MongoDB Atlas 🌐', () async {
    await LogHelper.writeLog(
      "========= TASK 2: CLOUD CONNECTOR SMOKE TEST =========",
      source: sourceFile,
      level: 2,
    );

    // Step 1: Verify MongoService Singleton
    final mongoService = MongoService();
    expect(mongoService, isNotNull);
    await LogHelper.writeLog(
      "✅ Step 1: MongoService Singleton Instance Created",
      source: sourceFile,
      level: 2,
    );

    // Step 2: Verify ENV is loaded
    final mongoUri = dotenv.env['MONGODB_URI'];
    expect(mongoUri, isNotNull);
    await LogHelper.writeLog(
      "✅ Step 2: MONGODB_URI loaded from .env",
      source: sourceFile,
      level: 2,
    );

    // Step 3: Test Connection (Main Test)
    try {
      await mongoService.connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Connection timeout after 15 seconds"),
      );

      // If we reach here, connection succeeded
      await LogHelper.writeLog(
        "✅ SUCCESS: Koneksi ke MongoDB Atlas berhasil 🎉",
        source: sourceFile,
        level: 2,
      );

      expect(mongoService.isConnected, true);
      await LogHelper.writeLog(
        "✅ Step 3: MongoService.isConnected = true",
        source: sourceFile,
        level: 2,
      );

      // Final status
      await LogHelper.writeLog(
        "========= CLOUD CONNECTOR TEST: PASSED ✅ =========",
        source: sourceFile,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "❌ FAILED: Could not connect to MongoDB Atlas",
        source: sourceFile,
        level: 1,
      );

      await LogHelper.writeLog(
        "Error Details: $e",
        source: sourceFile,
        level: 1,
      );

      fail(
        "Cloud Connector Test Failed:\n$e\n\n"
        "Troubleshooting:\n"
        "1. Verify MONGODB_URI in .env is correct\n"
        "2. Check IP Whitelist in MongoDB Atlas (allow 0.0.0.0/0)\n"
        "3. Verify network connectivity\n"
        "4. Check username:password in MONGODB_URI",
      );
    } finally {
      // Cleanup: Close connection
      try {
        await mongoService.close();
        await LogHelper.writeLog(
          "🔌 Cleanup: MongoDB connection closed",
          source: sourceFile,
          level: 3,
        );
      } catch (e) {
        await LogHelper.writeLog(
          "⚠️  Cleanup warning: $e",
          source: sourceFile,
          level: 3,
        );
      }
    }
  });
}
