import 'package:flutter/material.dart';
import 'package:logbook_app_060/features/models/log_model.dart';

/// Helper function to get color based on category
Color _getCategoryColor(LogCategory category) {
  switch (category) {
    case LogCategory.pekerjaan:
      return Colors.blue[100]!;
    case LogCategory.pribadi:
      return Colors.green[100]!;
    case LogCategory.urgent:
      return Colors.red[100]!;
  }
}

/// Helper function to get badge color based on category
Color _getCategoryBadgeColor(LogCategory category) {
  switch (category) {
    case LogCategory.pekerjaan:
      return Colors.blue[700]!;
    case LogCategory.pribadi:
      return Colors.green[700]!;
    case LogCategory.urgent:
      return Colors.red[700]!;
  }
}

/// Widget untuk menampilkan satu item log dalam bentuk Card
/// Reusable di berbagai tempat (LogView, Search result, dll)
class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.index,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getCategoryBadgeColor(log.category);
    final backgroundColor = _getCategoryColor(log.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      color: backgroundColor,
      child: ListTile(
        leading: Icon(Icons.note, color: badgeColor),
        title: Row(
          children: [
            Expanded(
              child: Text(
                log.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                log.category.displayName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              log.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            Text(
              log.date,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 6,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: badgeColor),
              tooltip: "Edit",
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: "Hapus",
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
