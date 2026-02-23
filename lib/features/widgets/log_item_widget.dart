import 'package:flutter/material.dart';
import '../models/log_model.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.note, color: Colors.blue[400]),
        title: Text(
          log.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(log.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(
              log.date,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 6,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
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
