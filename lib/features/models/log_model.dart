import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

/// Kategori catatan teknik yang tersedia
const List<String> kLogCategories = ['Mechanical', 'Electronic', 'Software'];

String normalizeLogCategory(String? category) {
  switch (category) {
    case 'Mechanical':
    case 'Electronic':
    case 'Software':
      return category!;
    // Backward compatibility from older category values.
    case 'Task':
      return 'Mechanical';
    case 'Urgent':
      return 'Electronic';
    case 'Update':
      return 'Software';
    default:
      return 'Software';
  }
}

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  /// Waktu catatan DIBUAT oleh pengguna (tidak berubah saat edit)
  @HiveField(3)
  final String date;

  @HiveField(4)
  final String authorId;

  @HiveField(5)
  final String teamId;

  @HiveField(6, defaultValue: true)
  final bool isSynced;

  @HiveField(7, defaultValue: false)
  final bool isPublic;

  /// Kategori catatan: 'Mechanical', 'Electronic', atau 'Software'
  @HiveField(8, defaultValue: 'Software')
  final String category;

  /// Waktu catatan BERHASIL masuk ke MongoDB (null jika belum tersinkron)
  @HiveField(9)
  final String? syncedAt;

  /// Tombstone lokal untuk delete offline agar data tidak hidup lagi saat sync.
  @HiveField(10, defaultValue: false)
  final bool isDeleted;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.authorId,
    required this.teamId,
    this.isPublic = false,
    this.isSynced = true,
    this.category = 'Software',
    this.syncedAt,
    this.isDeleted = false,
  });

  LogModel copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? authorId,
    String? teamId,
    bool? isSynced,
    bool? isPublic,
    String? category,
    String? syncedAt,
    bool? isDeleted,
  }) {
    return LogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      authorId: authorId ?? this.authorId,
      teamId: teamId ?? this.teamId,
      isSynced: isSynced ?? this.isSynced,
      isPublic: isPublic ?? this.isPublic,
      category: category ?? this.category,
      syncedAt: syncedAt ?? this.syncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() => {
    '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
    'title': title,
    'description': description,
    'date': date,
    'authorId': authorId,
    'teamId': teamId,
    'isPublic': isPublic,
    'category': category,
    'syncedAt': syncedAt,
  };

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? false,
      isSynced: true,
      category: normalizeLogCategory(map['category'] as String?),
      syncedAt: map['syncedAt'] as String?,
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}
