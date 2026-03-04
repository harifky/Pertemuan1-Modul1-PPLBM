import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/onboarding/onboarding_view.dart';
import 'services/mongo_service.dart';
import 'helpers/log_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    // Connect to MongoDB
    final mongoService = MongoService();
    await mongoService.connect().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception("MongoDB connection timeout"),
    );

    await LogHelper.writeLog(
      "✅ APP: MongoDB connected",
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingView(),
    );
  }
}
