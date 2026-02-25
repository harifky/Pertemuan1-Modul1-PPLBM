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

class LogModel {
  final String title;
  final String date;
  final String description;
  final LogCategory category;

  LogModel({
    required this.title,
    required this.date,
    required this.description,
    this.category = LogCategory.pribadi,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'],
      date: map['date'],
      description: map['description'],
      category: LogCategory.fromString(map['category'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'description': description,
      'category': category.value,
    };
  }
}
