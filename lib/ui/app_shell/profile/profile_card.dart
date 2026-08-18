import 'dart:math' as math;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/profile/avatar_picker_popup.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_wallet_cards.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Playing-card identity face, tinted from the player's avatar like the
/// in-game status scoreboards.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final name = vm.player?.name ?? '';
    final avatarId = vm.player?.avatarId;
    final score = AvatarScoreTheme.of(avatarId);

    return AspectRatio(
      aspectRatio: homeCardAspect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: score.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: score.ink.withValues(alpha: 0.08),
            width: 0.6,
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
              _CornerPip(
                avatarId: avatarId,
                name: name,
                score: score,
                inverted: false,
              ),
              _CornerPip(
                avatarId: avatarId,
                name: name,
                score: score,
                inverted: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, inner) {
                          final avatarSize = (inner.maxHeight * 0.52).clamp(
                            108.0,
                            156.0,
                          );
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AvatarButton(
                                avatarId: avatarId,
                                size: avatarSize,
                                score: score,
                                onPressed: () => _changeAvatar(context, vm),
                              ),
                              const SizedBox(height: 16),
                              _NameButton(
                                name: name,
                                score: score,
                                onPressed: () => _changeName(context, vm),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: ProfileWalletCards(
                        embeddedInCard: true,
                        scoreTheme: score,
                      ),
                    ),
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

class _CornerPip extends StatelessWidget {
  const _CornerPip({
    required this.avatarId,
    required this.name,
    required this.score,
    required this.inverted,
  });

  final String? avatarId;
  final String name;
  final AvatarScoreTheme score;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty
        ? null
        : String.fromCharCode(name.trim().runes.first).toUpperCase();
    final pip = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerAvatarView(avatarId: avatarId, size: 26, showBorder: false),
        if (letter != null) ...[
          const SizedBox(height: 3),
          Text(
            letter,
            style: TextStyle(
              color: score.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ],
    );

    return Positioned(
      top: inverted ? null : 12,
      left: inverted ? null : 12,
      bottom: inverted ? 12 : null,
      right: inverted ? 12 : null,
      child: IgnorePointer(
        child: inverted ? Transform.rotate(angle: math.pi, child: pip) : pip,
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.avatarId,
    required this.size,
    required this.score,
    required this.onPressed,
  });

  final String? avatarId;
  final double size;
  final AvatarScoreTheme score;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onPressed),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          PlayerAvatarView(avatarId: avatarId, size: size),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: score.panel,
              border: Border.all(color: score.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(CupertinoIcons.pencil, size: 16, color: score.ink),
          ),
        ],
      ),
    );
  }
}

class _NameButton extends StatelessWidget {
  const _NameButton({
    required this.name,
    required this.score,
    required this.onPressed,
  });

  final String name;
  final AvatarScoreTheme score;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onPressed),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: score.ink,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          const SizedBox(width: 8),
          Icon(CupertinoIcons.pencil, size: 18, color: score.muted),
        ],
      ),
    );
  }
}

Future<void> _changeAvatar(BuildContext context, ProfileViewModel vm) async {
  final picked = await showAvatarPickerPopup(
    context,
    selectedId: vm.player?.avatarId,
  );
  if (picked == null || picked == vm.player?.avatarId) return;
  await vm.updatePlayerAvatar(picked);
}

Future<void> _changeName(BuildContext context, ProfileViewModel vm) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: vm.player?.name);

  try {
    final newName =
        await showCupertinoDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text(l10n.editName),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: CupertinoTextField(
                  controller: controller,
                  maxLength: 10,
                  placeholder: l10n.enterYourName,
                  autofocus: true,
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: Text(l10n.cancel, style: AppStyle.theme.mutedText),
                  onPressed: SoundService.wrapTap(() => Navigator.pop(context)),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text(l10n.save, style: AppStyle.theme.title),
                  onPressed: SoundService.wrapTap(() {
                    Navigator.pop(context, controller.text.trim());
                  }),
                ),
              ],
            );
          },
        ) ??
        vm.player?.name ??
        '';

    if (newName.isNotEmpty && newName != vm.player?.name) {
      await vm.updatePlayerName(newName);
    }
  } finally {
    controller.dispose();
  }
}
