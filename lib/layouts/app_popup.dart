import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

Future<T?> showAppPopup<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget content,
  String primaryText = 'OK',
  VoidCallback? onPrimary,
  String? secondaryText,
  VoidCallback? onSecondary,
  bool barrierDismissible = true,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      return CupertinoPopupSurface(
        isSurfacePainted: true,
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style:  TextStyle(
                      fontSize: 13,
                      color: AppStyle.theme.surface,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Body
                content,

                const SizedBox(height: 14),

                // Actions
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(ctx).pop();
                          onPrimary?.call();
                        },
                        child: Text(primaryText),
                      ),
                    ),
                    if (secondaryText != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: () {
                            HapticFeedback.lightImpact();

                            Navigator.of(ctx).pop();
                            onSecondary?.call();
                          },
                          child: Text(secondaryText),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
