import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Motif géométrique inspiré du wax, dessiné en filigrane sur les en-têtes.
class WaxPatternPainter extends CustomPainter {
  final double opacity;
  WaxPatternPainter({this.opacity = 0.12});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = Colors.white.withValues(alpha: opacity * 0.6);

    const step = 44.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        final cx = x + step / 2;
        final cy = y + step / 2;
        // Losange
        final path = Path()
          ..moveTo(cx, cy - 14)
          ..lineTo(cx + 14, cy)
          ..lineTo(cx, cy + 14)
          ..lineTo(cx - 14, cy)
          ..close();
        canvas.drawPath(path, paint);
        // Point central alterné
        if (((x / step).round() + (y / step).round()) % 2 == 0) {
          canvas.drawCircle(Offset(cx, cy), 3, fill);
        } else {
          canvas.drawCircle(Offset(cx, cy), 6, paint);
        }
      }
    }
    // Arcs décoratifs
    for (double x = 0; x < size.width; x += step) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x, size.height), radius: 18),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaxPatternPainter old) => old.opacity != opacity;
}

/// En-tête dégradé orange/rouge avec motif wax.
class WaxHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? radius;

  const WaxHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final r =
        radius ?? const BorderRadius.vertical(bottom: Radius.circular(32));
    return ClipRRect(
      borderRadius: r,
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: WaxPatternPainter())),
            SafeArea(
              bottom: false,
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientAvatar extends StatelessWidget {
  final Client client;
  final double size;
  const ClientAvatar({super.key, required this.client, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final color = AppColors
        .avatarColors[client.colorIndex % AppColors.avatarColors.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        client.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!, style: TextStyle(fontSize: 12, color: color)),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.orange),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

void showToast(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color ?? AppColors.ink),
    );
}
