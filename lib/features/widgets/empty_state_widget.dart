import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget empty state animasi mengambang (floating).
/// Digunakan saat tidak ada data di list agar tampilan tidak kosong total.
///
/// Untuk animasi yang lebih kaya, ganti bagian icon dengan:
///   Lottie.asset('assets/animations/empty.json', width: 200, height: 200)
/// setelah menambahkan package `lottie` dan file .json ke assets/.
class EmptyStateWidget extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? svgAssetPath;

  const EmptyStateWidget({
    super.key,
    this.title = "Belum ada catatan",
    this.subtitle,
    this.icon = Icons.note_outlined,
    this.iconColor,
    this.svgAssetPath = 'assets/illustrations/empty_state.svg',
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Animasi naik-turun ±10px
    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.grey[50];
    final textColor = isDark ? Colors.grey[300] : Colors.grey[800];

    return Container(
      color: backgroundColor,
      child: Center(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.6, end: 1.0).animate(
            CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon mengambang dengan animasi
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (widget.iconColor ?? primaryColor).withAlpha(40),
                        (widget.iconColor ?? primaryColor).withAlpha(10),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.iconColor ?? primaryColor).withAlpha(40),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SvgPicture.asset(
                      widget.svgAssetPath!,
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        widget.iconColor ?? primaryColor,
                        BlendMode.srcIn,
                      ),
                      placeholderBuilder: (_) => Icon(
                        widget.icon,
                        size: 72,
                        color: widget.iconColor ?? primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Judul
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.title ?? "Belum ada catatan",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Subtitle instruksional
              if (widget.subtitle != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Tiga titik animasi sebagai dekorasi
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final delay = i * 0.33;
                      final t = (_floatController.value + delay) % 1.0;
                      final scale =
                          0.5 +
                          0.5 *
                              Curves.easeInOut.transform(
                                t < 0.5 ? t * 2 : (1 - t) * 2,
                              );
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (widget.iconColor ?? primaryColor)
                                  .withAlpha((180 * scale).toInt()),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
