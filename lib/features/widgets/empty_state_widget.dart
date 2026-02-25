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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.grey[50];
    final iconBgColor = isDark ? Colors.grey[800] : Colors.blue[50];
    final textColor = isDark ? Colors.grey[300] : Colors.grey[800];

    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative circle background for icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(icon, size: 60, color: iconColor ?? primaryColor),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title ?? "Belum ada catatan",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            // Decorative line
            const SizedBox(height: 32),
            Container(
              width: 60,
              height: 3,
              decoration: BoxDecoration(
                color: primaryColor.withAlpha((255 * 0.3).toInt()),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
