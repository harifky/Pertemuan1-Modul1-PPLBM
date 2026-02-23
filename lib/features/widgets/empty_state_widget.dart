import 'package:flutter/material.dart';

/// Widget untuk menampilkan empty state dengan pesan yang custom
/// Digunakan saat tidak ada data di list
class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    this.title = "Belum ada catatan",
    this.subtitle,
    this.icon = Icons.note_outlined,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: iconColor ?? Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title ?? "Belum ada catatan",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
