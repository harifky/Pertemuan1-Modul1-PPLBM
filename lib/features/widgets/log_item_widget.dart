import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_060/features/models/log_model.dart';

/// Memetakan kategori ke warna indikator
Color _categoryColor(String category) {
  switch (normalizeLogCategory(category)) {
    case 'Mechanical':
      return Colors.green[600]!;
    case 'Electronic':
      return Colors.blue[600]!;
    case 'Software':
    default:
      return Colors.deepPurple[600]!;
  }
}

/// Memetakan kategori ke icon
IconData _categoryIcon(String category) {
  switch (normalizeLogCategory(category)) {
    case 'Mechanical':
      return Icons.settings;
    case 'Electronic':
      return Icons.memory;
    case 'Software':
    default:
      return Icons.code;
  }
}

String _formatLogDate(String rawDate) {
  final parsedDate = DateTime.tryParse(rawDate);
  if (parsedDate == null) {
    return rawDate;
  }

  final localDate = parsedDate.toLocal();
  final now = DateTime.now();
  final difference = now.difference(localDate);

  if (difference.inMinutes < 1) {
    return "Baru saja";
  }

  if (difference.inMinutes < 60) {
    return "${difference.inMinutes} menit yang lalu";
  }

  if (difference.inHours < 24) {
    return "${difference.inHours} jam yang lalu";
  }

  if (difference.inDays < 7) {
    return "${difference.inDays} hari yang lalu";
  }

  return DateFormat('d MMM y', 'id_ID').format(localDate);
}

/// Widget untuk menampilkan satu item log dalam bentuk Card
/// Dengan RBAC: Button edit/delete hanya muncul jika user punya permission
class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? currentUserRole;
  final String? currentUserId;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.index,
    this.onEdit,
    this.onDelete,
    this.currentUserRole,
    this.currentUserId,
  });

  Widget _buildTag({
    required String text,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMetaText({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget? _buildTrailingActions(
    BuildContext context, {
    required bool canEdit,
    required bool canDelete,
  }) {
    if (!canEdit && !canDelete) {
      return null;
    }

    final isCompact = MediaQuery.of(context).size.width < 380;

    if (isCompact) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'edit') {
            onEdit?.call();
          }
          if (value == 'delete') {
            onDelete?.call();
          }
        },
        itemBuilder: (context) => [
          if (canEdit)
            const PopupMenuItem<String>(
              value: 'edit',
              height: 36,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
          if (canDelete)
            const PopupMenuItem<String>(
              value: 'delete',
              height: 36,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus'),
                ],
              ),
            ),
        ],
      );
    }

    return Wrap(
      spacing: 6,
      children: [
        if (canEdit)
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue[700]),
            tooltip: "Edit",
            onPressed: onEdit,
          ),
        if (canDelete)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: "Hapus",
            onPressed: onDelete,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine ownership
    final bool isOwner = currentUserId != null && log.authorId == currentUserId;
    final bool canEdit = isOwner && !log.isDeleted;
    final bool canDelete = isOwner && !log.isDeleted;
    final normalizedCategory = normalizeLogCategory(log.category);
    final color = _categoryColor(normalizedCategory);
    final isPendingDelete = log.isDeleted;
    final cardBorderColor = isPendingDelete ? Colors.orange[300]! : color;
    final cardTitleColor = isPendingDelete
        ? Colors.grey[600]!
        : Colors.grey[900]!;
    final descriptionColor = isPendingDelete
        ? Colors.grey[500]!
        : Colors.grey[700]!;
    final syncColor = isPendingDelete
        ? Colors.orange[800]!
        : (log.isSynced ? Colors.green[700]! : Colors.orange[700]!);
    final syncText = isPendingDelete
        ? 'Hapus pending'
        : log.isSynced
        ? 'Cloud'
        : 'Pending';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: isPendingDelete ? Colors.orange[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isPendingDelete ? Colors.orange[200]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: cardBorderColor, width: 3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
          minLeadingWidth: 34,
          contentPadding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          tileColor: isPendingDelete ? Colors.orange[50] : Colors.white,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (isPendingDelete ? Colors.orange[700]! : color).withAlpha(
                20,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isPendingDelete
                  ? Icons.delete_sweep_outlined
                  : _categoryIcon(normalizedCategory),
              size: 18,
              color: isPendingDelete ? Colors.orange[700] : color,
            ),
          ),
          title: Text(
            log.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: cardTitleColor,
              decoration: isPendingDelete ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                isPendingDelete
                    ? 'Catatan ini menunggu sinkronisasi penghapusan.'
                    : log.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: descriptionColor, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildTag(
                    text: normalizedCategory,
                    textColor: _categoryColor(normalizedCategory),
                    backgroundColor: _categoryColor(
                      normalizedCategory,
                    ).withAlpha(26),
                  ),
                  _buildTag(
                    text: log.isPublic ? 'Public' : 'Private',
                    textColor: log.isPublic
                        ? Colors.blue[700]!
                        : Colors.grey[700]!,
                    backgroundColor: log.isPublic
                        ? Colors.blue.withAlpha(22)
                        : Colors.grey.withAlpha(30),
                  ),
                  if (isOwner)
                    _buildTag(
                      text: 'Milik Saya',
                      textColor: Colors.green[700]!,
                      backgroundColor: Colors.green.withAlpha(24),
                    ),
                  _buildMetaText(
                    icon: Icons.access_time,
                    text: _formatLogDate(log.date),
                    color: Colors.grey[700]!,
                  ),
                  _buildMetaText(
                    icon: Icons.person,
                    text: log.authorId,
                    color: Colors.grey[700]!,
                  ),
                  _buildMetaText(
                    icon: isPendingDelete
                        ? Icons.cloud_off_rounded
                        : (log.isSynced
                              ? Icons.cloud_done
                              : Icons.cloud_upload),
                    text: syncText,
                    color: syncColor,
                  ),
                ],
              ),
            ],
          ),
          trailing: _buildTrailingActions(
            context,
            canEdit: canEdit,
            canDelete: canDelete,
          ),
        ),
      ), // closes Container (left-border wrapper)
    );
  }
}
