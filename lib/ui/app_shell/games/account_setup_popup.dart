import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/ui/widgets/account_dialogs.dart';
import 'package:dominican_casino/ui/widgets/apple_mark.dart';
import 'package:dominican_casino/ui/widgets/google_g_mark.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:provider/provider.dart';

/// After the pre-login tutorial: pick a name, stay guest, or connect Google.
Future<void> showAccountSetupPopup(BuildContext context) {
  return showAppCenterPopup<void>(
    context: context,
    builder: (dialogContext) => const _AccountSetupCard(),
  );
}

class _AccountSetupCard extends StatefulWidget {
  const _AccountSetupCard();

  @override
  State<_AccountSetupCard> createState() => _AccountSetupCardState();
}

class _AccountSetupCardState extends State<_AccountSetupCard> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  bool _hasName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final player = context.read<AppRepo>().player;
      final name = player?.name?.trim() ?? '';
      if (name.isNotEmpty && !(player?.needsAccountSetup ?? true)) {
        _controller.text = name;
        setState(() => _hasName = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveGuest() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _saveName(_controller.text);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveLinked(Future<GoogleAuthResult> Function() link) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = context.read<AppRepo>();
      final result = await link();
      if (!mounted) return;
      if (result.status == GoogleAuthStatus.canceled) return;
      if (result.status == GoogleAuthStatus.failed) {
        await showLinkAccountError(context, result.errorCode);
        return;
      }
      final typed = _controller.text.trim();
      final name = typed.isNotEmpty
          ? typed
          : (result.suggestedName ?? '').trim();
      if (name.isNotEmpty) {
        await repo.updatePlayer(name);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveGoogle() async {
    if (_busy) return;
    final confirmed = await confirmConnectGoogle(context);
    if (!confirmed || !mounted) return;
    await _saveLinked(() => context.read<AppRepo>().linkGoogleAccount());
  }

  Future<void> _saveApple() async {
    if (_busy) return;
    final confirmed = await confirmConnectApple(context);
    if (!confirmed || !mounted) return;
    await _saveLinked(() => context.read<AppRepo>().linkAppleAccount());
  }

  Future<void> _saveName(String raw) async {
    final name = raw.trim();
    if (name.isEmpty) return;
    await context.read<AppRepo>().updatePlayer(name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: CupertinoColors.transparent,
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border.withValues(alpha: .7)),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .45),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.saveProgressTitle,
              textAlign: TextAlign.center,
              style: theme.title.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _hasName ? l10n.saveProgressGoogleBody : l10n.saveProgressBody,
              textAlign: TextAlign.center,
              style: theme.body.copyWith(height: 1.4),
            ),
            if (!_hasName) ...[
              const SizedBox(height: 18),
              CupertinoTextField(
                controller: _controller,
                maxLength: 10,
                textAlign: TextAlign.center,
                placeholder: l10n.yourName,
                enabled: !_busy,
                autofocus: true,
              ),
            ],
            const SizedBox(height: 16),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: theme.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              onPressed: SoundService.wrapTap(_busy ? null : _saveGuest),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person,
                    size: 16,
                    color: theme.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.guest,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: theme.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: SoundService.wrapTap(_busy ? null : _saveGoogle),
                    child: _busy
                        ? const CupertinoActivityIndicator()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const GoogleGMark(size: 15),
                              const SizedBox(width: 6),
                              Text(
                                l10n.google,
                                style: TextStyle(
                                  color: theme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (appleSignInAvailable) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: theme.surfaceRaised,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: SoundService.wrapTap(_busy ? null : _saveApple),
                      child: _busy
                          ? const CupertinoActivityIndicator()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AppleMark(size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.apple,
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ],
            ),
            CupertinoButton(
              padding: const EdgeInsets.only(top: 4),
              onPressed: SoundService.wrapTap(
                _busy ? null : () => Navigator.pop(context),
              ),
              child: Text(l10n.later, style: TextStyle(color: theme.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
