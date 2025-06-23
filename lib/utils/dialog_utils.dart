// lib/utils/dialog_utils.dart
import 'package:flutter/material.dart';

Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required Widget titleWidget,
  required Widget contentWidget,
  List<Widget>? actionsWidget,
  MainAxisAlignment actionsAlignment = MainAxisAlignment.end,
  double maxWidthFactor = 0.85,
  double maxHeightFactor = 0.8,
  EdgeInsetsGeometry dialogPadding = const EdgeInsets.all(24.0),
  bool barrierDismissible = true,
}) {
  final theme = Theme.of(context);
  final dialogTheme = DialogTheme.of(context);

  // Shape için düzeltilmiş mantık
  ShapeBorder? effectiveShape = dialogTheme.shape;
  if (effectiveShape == null) {
    effectiveShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0));
  } else if (effectiveShape is RoundedRectangleBorder) {
    // Zaten RoundedRectangleBorder, borderRadius'ını kullanabiliriz.
    // Eğer belirli bir köşe yarıçapına erişmek gerekmiyorsa, doğrudan shape'i kullanmak yeterli.
    // Önceki kodda (dialogTheme.shape as RoundedRectangleBorder).borderRadius as BorderRadius.all).topLeft.x
    // gibi bir erişim vardı, bu gereksiz ve hatalıydı. Sadece shape'i kullanmak yeterli.
  } else {
    // Farklı bir ShapeBorder türü ise varsayılanı kullanalım
    effectiveShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0));
  }


  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54.withOpacity(0.7),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * maxWidthFactor,
              maxHeight: MediaQuery.of(context).size.height * maxHeightFactor),
          child: Material(
            type: MaterialType.card,
            color: dialogTheme.backgroundColor ?? theme.dialogBackgroundColor,
            shape: effectiveShape, // Düzeltilmiş shape kullanımı
            elevation: dialogTheme.elevation ?? 24.0,
            child: Padding(
              padding: dialogPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DefaultTextStyle(
                    style: dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge!,
                    child: Semantics(child: titleWidget),
                  ),
                  const SizedBox(height: 16.0),
                  Flexible( // contentWidget'ın kalan alanı doldurması için
                    child: contentWidget,
                  ),
                  if (actionsWidget != null && actionsWidget.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: actionsAlignment,
                        children: actionsWidget,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
      final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInQuart.flipped,
        ),
      );
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
  );
}