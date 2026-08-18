import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;

/// Full-page overlay (root navigator) so dialogs are not clipped to a
/// nested stack like the in-game player area.
Future<T?> showAppCenterPopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SizedBox.expand(
        child: Material(
          color: CupertinoColors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: barrierDismissible
                ? () => Navigator.of(dialogContext).pop()
                : null,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.viewInsetsOf(dialogContext).bottom + 12,
                  ),
                  child: GestureDetector(
                    onTap: () {},
                    child: builder(dialogContext),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      );
    },
  );
}

Future<T?> showAppPopup<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget content,
  String primaryText = 'OK',
  VoidCallback? onPrimary,
  String? secondaryText,
  VoidCallback? onSecondary,
  String? tertiaryText,
  VoidCallback? onTertiary,
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
                        onPressed: SoundService.wrapTap(() {
                          AppHaptics.mediumImpact();
                          Navigator.of(ctx).pop();
                          onPrimary?.call();
                        }),
                        child: Text(primaryText),
                      ),
                    ),
                    if (secondaryText != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: SoundService.wrapTap(() {
                            AppHaptics.lightImpact();

                            Navigator.of(ctx).pop();
                            onSecondary?.call();
                          }),
                          child: Text(secondaryText),
                        ),
                      ),
                    ],
                    if (tertiaryText != null) ...[
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: SoundService.wrapTap(() {
                            AppHaptics.lightImpact();
                            Navigator.of(ctx).pop();
                            onTertiary?.call();
                          }),
                          child: Text(
                            tertiaryText,
                            style: TextStyle(color: AppStyle.theme.muted),
                          ),
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
