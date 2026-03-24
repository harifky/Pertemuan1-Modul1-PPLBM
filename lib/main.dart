import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Gunakan hive_flutter, bukan hive biasa
import 'package:intl/date_symbol_data_local.dart';
import 'features/onboarding/onboarding_view.dart';
import 'features/models/log_model.dart';
import 'services/mongo_service.dart';
import 'helpers/log_helper.dart';

void main() async {
  // Wajib untuk operasi asinkron sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // INISIALISASI HIVE
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter()); // WAJIB: Sesuai nama di .g.dart
  await Hive.openBox<LogModel>(
    'offline_logs',
  ); // Buka box sebelum Controller dipakai

  try {
    // Initialize logging and database
    await LogHelper.initializeLogging();
    await initializeDateFormatting('id_ID');
    await dotenv.load(fileName: ".env");

    await LogHelper.writeLog(
      "🚀 APP: Starting application",
      source: "main.dart",
      level: 2,
    );
  } catch (e) {
    await LogHelper.writeLog(
      "⚠️  APP: Initialization warning - $e",
      source: "main.dart",
      level: 2,
    );
  }

  runApp(const MyApp());

  // Warm up MongoDB in background so UI startup is not blocked on mobile.
  unawaited(
    MongoService()
        .connect()
        .then((_) async {
          await LogHelper.writeLog(
            "✅ APP: MongoDB connected",
            source: "main.dart",
            level: 2,
          );
        })
        .catchError((e) async {
          await LogHelper.writeLog(
            "⚠️  APP: Background MongoDB warm-up failed - $e",
            source: "main.dart",
            level: 2,
          );
        }),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFEAF4FF),
          foregroundColor: Color(0xFF17324D),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const OnboardingView(),
    );
  }
}
