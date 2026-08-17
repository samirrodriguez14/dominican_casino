import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/widgets/google_g_mark.dart';
import 'package:flutter/cupertino.dart';

/// Login face: welcome on top, auth at the bottom. Name appears after a choice.
class HomeLoginCard extends StatelessWidget {
  const HomeLoginCard({
    super.key,
    required this.nameController,
    required this.askingName,
    required this.onGuest,
    required this.onGoogle,
    required this.onQuickPlay,
    required this.onContinue,
    required this.onCancelName,
    this.busy = false,
  });

  final TextEditingController nameController;
  final bool askingName;
  final VoidCallback onGuest;
  final VoidCallback onGoogle;
  final VoidCallback onQuickPlay;
  final VoidCallback onContinue;
  final VoidCallback onCancelName;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);

    return AspectRatio(
      aspectRatio: homeCardAspect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: DecorationImage(
            image: AssetImage(theme.loginCardBack),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .30),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CupertinoColors.transparent,
                        theme.background.withValues(alpha: .55),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  children: [
                    Text(
                      l10n.welcome,
                      style: theme.caption.copyWith(
                        color: theme.textPrimary.withValues(alpha: .92),
                        letterSpacing: 3.2,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (askingName) ...[
                      CupertinoTextField(
                        controller: nameController,
                        maxLength: 10,
                        textAlign: TextAlign.center,
                        enabled: !busy,
                        autofocus: true,
                        placeholder: l10n.yourName,
                        placeholderStyle: theme.mutedText.copyWith(
                          color: theme.textPrimary.withValues(alpha: .55),
                        ),
                        style: theme.body.copyWith(
                          color: theme.textPrimary,
                          fontSize: 16,
                        ),
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        decoration: BoxDecoration(
                          color: CupertinoColors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: theme.textPrimary.withValues(alpha: .7),
                            ),
                          ),
                        ),
                        onSubmitted: (_) => onContinue(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: _AuthPill(
                          label: l10n.continueLabel,
                          onPressed: busy ? null : onContinue,
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.only(top: 6),
                        minimumSize: Size.zero,
                        onPressed: busy ? null : onCancelName,
                        child: Text(
                          l10n.back,
                          style: theme.caption.copyWith(
                            color: theme.textPrimary.withValues(alpha: .7),
                            decoration: TextDecoration.underline,
                            decorationColor: theme.textPrimary.withValues(
                              alpha: .3,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Semantics(
                        button: true,
                        label: l10n.play,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: busy ? null : onQuickPlay,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: theme.textPrimary.withValues(alpha: .16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.textPrimary.withValues(alpha: .22),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withValues(
                                    alpha: .28,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              CupertinoIcons.play_fill,
                              size: 30,
                              color: theme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _AuthPill(
                              label: l10n.guest,
                              icon: CupertinoIcons.person,
                              onPressed: busy ? null : onGuest,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AuthPill(
                              label: l10n.google,
                              leading: const GoogleGMark(size: 15),
                              onPressed: busy ? null : onGoogle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthPill extends StatelessWidget {
  const _AuthPill({
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final cream = theme.textPrimary;

    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cream.withValues(alpha: .78)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 16, color: cream),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.title.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
