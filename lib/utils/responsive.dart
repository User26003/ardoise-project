import 'package:flutter/material.dart';

/// Aides pour adapter l'interface aux petits téléphones, grands écrans et web.
class R {
  /// Largeur maximale du contenu pour éviter des lignes trop longues
  /// sur tablette / navigateur.
  static const double maxContentWidth = 640;

  static double width(BuildContext c) => MediaQuery.sizeOf(c).width;
  static double height(BuildContext c) => MediaQuery.sizeOf(c).height;

  /// Très petit téléphone (ex. 320 px de large).
  static bool isCompact(BuildContext c) => width(c) < 360;

  /// Écran large (tablette, navigateur).
  static bool isWide(BuildContext c) => width(c) >= 700;

  /// Hauteur réduite (paysage sur téléphone, clavier ouvert).
  static bool isShort(BuildContext c) => height(c) < 600;

  /// Facteur d'échelle doux pour les tailles de police / espacements.
  static double scale(BuildContext c) {
    final w = width(c).clamp(320.0, 480.0);
    return 0.9 + (w - 320) / (480 - 320) * 0.2; // 0.90 → 1.10
  }

  static double sp(BuildContext c, double v) => v * scale(c);

  /// Marge horizontale de page.
  static double hPad(BuildContext c) =>
      isCompact(c) ? 12 : (isWide(c) ? 24 : 16);

  /// Nombre de colonnes pour les grilles de statistiques.
  static int statColumns(BuildContext c) {
    final w = width(c);
    if (w >= 900) return 4;
    if (w >= 520) return 3;
    return 2;
  }
}

/// Centre et limite la largeur du contenu sur grands écrans.
class MaxWidth extends StatelessWidget {
  final Widget child;
  final double max;
  const MaxWidth({
    super.key,
    required this.child,
    this.max = R.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}
