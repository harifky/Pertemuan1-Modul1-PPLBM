import 'package:flutter/material.dart';

/// Custom AppBar dengan styling yang konsisten
/// Bisa dipakai di LogView, CounterView, dll
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool centerTitle;
  final VoidCallback? onLeadingPressed;
  final bool showLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle = true,
    this.onLeadingPressed,
    this.showLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? Text(title),
      centerTitle: centerTitle,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      elevation: 4,
      leading: showLeading
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onLeadingPressed ?? () => Navigator.pop(context),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Widget untuk membuat greeting message dengan styling konsisten
class GreetingMessage extends StatelessWidget {
  final String message;
  final String? secondaryText;

  const GreetingMessage({super.key, required this.message, this.secondaryText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          if (secondaryText != null) ...[
            const SizedBox(height: 8),
            Text(
              secondaryText!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
