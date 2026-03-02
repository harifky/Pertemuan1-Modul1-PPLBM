import 'package:mongo_dart/mongo_dart.dart';

enum LogCategory {
  pekerjaan('Pekerjaan', 'work'),
  pribadi('Pribadi', 'personal'),
  urgent('Urgent', 'urgent');

  final String displayName;
  final String value;

  const LogCategory(this.displayName, this.value);

  factory LogCategory.fromString(String? value) {
    if (value == null) return LogCategory.pribadi;
    return LogCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => LogCategory.pribadi,
    );
  }
}

/// LogModel dengan ObjectId support untuk MongoDB Atlas
/// Modul 4: Cloud Integration dengan BSON Serialization
class LogModel {
  final ObjectId? id; // Penanda unik global dari MongoDB
  final String title;
  final String date;
  final String description;
  final LogCategory category;

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    this.category = LogCategory.pribadi,
  });

  /// [CONVERT] Memasukkan data ke "Kardus" (BSON/Map) untuk dikirim ke Cloud
  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id, // Include ID jika ada (untuk update/delete)
      'title': title,
      'date': date, // Already ISO8601 format
      'description': description,
      'category': category.value,
    };
  }

  /// [REVERT] Membongkar "Kardus" (BSON/Map) kembali menjadi objek Flutter
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      date: map['date'] ?? DateTime.now().toString(),
      description: map['description'] ?? '',
      category: LogCategory.fromString(map['category'] as String?),
    );
  }
}
