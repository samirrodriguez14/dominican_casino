import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/theme_pack.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/profile/avatar_picker_popup.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_wallet_cards.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/view_models/app_theme_view_model.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Playing-card identity face, tinted from the player's avatar like the
/// in-game status scoreboards. The card itself is the winning-card look.
class ProfileCard extends StatefulWidget {
  const ProfileCard({super.key, this.onToggleLooks});

  final VoidCallback? onToggleLooks;

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _editingCard = false;

  void _setEditing(bool value) {
    if (_editingCard == value) return;
    setState(() => _editingCard = value);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final repo = context.watch<AppRepo>();
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
              ),
              if (!_editingCard)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                                  playingCardWidth: avatarSize * 0.32,
                                  onPressed: () => _changeAvatar(context, vm),
                                  onEditPlayingCard: () => _setEditing(true),
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
                      ProfileWalletPills(
                        scoreTheme: score,
                        trailing: widget.onToggleLooks == null
                            ? null
                            : _LooksActionButton(
                                score: score,
                                onPressed: widget.onToggleLooks!,
                              ),
                      ),
                    ],
                  ),
                )
              else
                Positioned.fill(
                  child: _PlayingCardEditor(
                    score: score,
                    repo: repo,
                    onDone: () => _setEditing(false),
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
  });

  final String? avatarId;
  final String name;
  final AvatarScoreTheme score;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty
        ? null
        : String.fromCharCode(name.trim().runes.first).toUpperCase();

    return Positioned(
      top: 10,
      left: 10,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerAvatarView(avatarId: avatarId, size: 40, showBorder: false),
            if (letter != null) ...[
              const SizedBox(height: 4),
              Text(
                letter,
                style: TextStyle(
                  color: score.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LooksActionButton extends StatelessWidget {
  const _LooksActionButton({required this.score, required this.onPressed});

  final AvatarScoreTheme score;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onPressed),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: score.panel,
          shape: BoxShape.circle,
          border: Border.all(color: score.ink.withValues(alpha: 0.18)),
        ),
        alignment: Alignment.center,
        child: Icon(
          CupertinoIcons.paintbrush,
          size: 22,
          color: score.ink,
          semanticLabel: l10n.themes,
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.avatarId,
    required this.size,
    required this.score,
    required this.playingCardWidth,
    required this.onPressed,
    required this.onEditPlayingCard,
  });

  final String? avatarId;
  final double size;
  final AvatarScoreTheme score;
  final double playingCardWidth;
  final VoidCallback onPressed;
  final VoidCallback onEditPlayingCard;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + playingCardWidth * 0.22,
      height: size + playingCardWidth * 0.18,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CupertinoButton(
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
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: PlayingCardBack(
              width: playingCardWidth,
              onTap: SoundService.wrapTap(onEditPlayingCard),
            ),
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

class _PlayingCardEditor extends StatelessWidget {
  const _PlayingCardEditor({
    required this.score,
    required this.repo,
    required this.onDone,
  });

  final AvatarScoreTheme score;
  final AppRepo repo;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<AppThemeViewModel>();
    final tints = tintsForTheme(repo.appTheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          PlayingCardBack(
            width: 132,
            tintId: vm.cardBackTintId,
            mark: vm.cardBackMark,
            avatarId: repo.player?.avatarId,
            onTap: SoundService.wrapTap(
              () => vm.setCardBackMark(vm.cardBackMark.next),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final tint in tints)
                _TintDot(
                  tint: tint,
                  selected: vm.cardBackTintId == tint.id,
                  onTap: () => vm.setCardBackTintId(tint.id),
                ),
            ],
          ),
          const Spacer(),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            onPressed: SoundService.wrapTap(onDone),
            child: Text(
              l10n.done,
              style: TextStyle(
                color: score.ink,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TintDot extends StatelessWidget {
  const _TintDot({
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  final CardBackTint tint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: tint.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? const Color(0xFF1C1612)
                : const Color(0x33000000),
            width: selected ? 2.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .18),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _changeAvatar(BuildContext context, ProfileViewModel vm) async {
  final repo = context.read<AppRepo>();
  final picked = await showAvatarPickerPopup(
    context,
    selectedId: vm.player?.avatarId,
    avatarIds: avatarsForPack(repo.appTheme),
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
                  onPressed: SoundService.wrapTap(() => Navigator.pop(context)),
                  child: Text(l10n.cancel),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: SoundService.wrapTap(() {
                    Navigator.pop(context, controller.text.trim());
                  }),
                  child: Text(l10n.save, style: AppStyle.theme.title),
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
