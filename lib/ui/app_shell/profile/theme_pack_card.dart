import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/theme_pack.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/ui/widgets/winning_card_preview.dart';
import 'package:dominican_casino/view_models/app_theme_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Theme catalog card. Preview only — dressing room lives on Profile.
class ThemePackCard extends StatefulWidget {
  const ThemePackCard({
    super.key,
    required this.pack,
    this.compact = false,
    this.showActions = false,
  });

  final ThemePack pack;
  final bool compact;
  final bool showActions;

  @override
  State<ThemePackCard> createState() => _ThemePackCardState();
}

class _ThemePackCardState extends State<ThemePackCard> {
  late String _previewAvatarId;
  late String _previewTintId;
  late CardBackMark _previewMark;

  ThemePack get pack => widget.pack;

  @override
  void initState() {
    super.initState();
    _syncPreviewFromPack();
  }

  @override
  void didUpdateWidget(covariant ThemePackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pack.id != pack.id) {
      _syncPreviewFromPack();
    }
  }

  void _syncPreviewFromPack() {
    _previewAvatarId = pack.avatarIds.first;
    _previewTintId = pack.defaultTintId;
    _previewMark = CardBackMark.logo;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepo>();
    final packTheme = themeFromEnum(pack.id);
    final owned = repo.ownsPack(pack.id);
    final equipped = repo.appTheme == pack.id;
    final tints = tintsForTheme(pack.id);

    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: packTheme.pickerFace,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: equipped
                ? packTheme.turnHighlight.withValues(alpha: .85)
                : packTheme.textPrimary.withValues(alpha: .14),
            width: equipped ? 1.8 : 1.2,
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
              if (widget.compact)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeLabel(pack.id),
                          textAlign: TextAlign.center,
                          style: packTheme.title.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.02,
                            color: packTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PreviewPair(
                          packTheme: packTheme,
                          avatarId: pack.avatarIds.first,
                          tintId: pack.defaultTintId,
                          mark: CardBackMark.logo,
                          width: 40,
                        ),
                      ],
                    ),
                  ),
                ),
              if (equipped)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    color: packTheme.turnHighlight,
                    size: 22,
                  ),
                )
              else if (!owned && widget.compact)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Icon(
                    CupertinoIcons.lock_fill,
                    color: packTheme.textPrimary.withValues(alpha: .62),
                    size: 18,
                  ),
                ),
              if (!widget.compact)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !widget.showActions,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 70),
                      child: Column(
                        children: [
                          Text(
                            themeLabel(pack.id),
                            textAlign: TextAlign.center,
                            style: packTheme.title.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.02,
                              color: packTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final id in pack.avatarIds)
                                GestureDetector(
                                  onTap: SoundService.wrapTap(() {
                                    setState(() => _previewAvatarId = id);
                                  }),
                                  child: PlayerAvatarView(
                                    avatarId: id,
                                    size: 44,
                                    showBorder: true,
                                    selected: _previewAvatarId == id,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final tint in tints)
                                GestureDetector(
                                  onTap: SoundService.wrapTap(() {
                                    setState(() => _previewTintId = tint.id);
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: tint.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _previewTintId == tint.id
                                            ? packTheme.turnHighlight
                                            : packTheme.textPrimary.withValues(
                                                alpha: .28,
                                              ),
                                        width: _previewTintId == tint.id
                                            ? 2
                                            : 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _PreviewPair(
                            packTheme: packTheme,
                            avatarId: _previewAvatarId,
                            tintId: _previewTintId,
                            mark: _previewMark,
                            width: 52,
                            onTapBack: () {
                              setState(() => _previewMark = _previewMark.next);
                            },
                          ),
                          if (pack.isCoinLocked && !owned) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  coinIcon,
                                  size: 12,
                                  color: packTheme.turnHighlight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${pack.coinCost}',
                                  style: packTheme.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: packTheme.textPrimary.withValues(
                                      alpha: .88,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!widget.compact)
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: widget.showActions
                      ? _PackActionButton(
                          pack: pack,
                          owned: owned,
                          equipped: equipped,
                          packTheme: packTheme,
                          previewAvatarId: _previewAvatarId,
                          previewTintId: _previewTintId,
                        )
                      : IgnorePointer(
                          child: _CircleBadge(
                            packTheme: packTheme,
                            child: const SizedBox.shrink(),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPair extends StatelessWidget {
  const _PreviewPair({
    required this.packTheme,
    required this.avatarId,
    required this.tintId,
    required this.mark,
    required this.width,
    this.onTapBack,
  });

  final AppTheme packTheme;
  final String avatarId;
  final String tintId;
  final CardBackMark mark;
  final double width;
  final VoidCallback? onTapBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlayingCardBack(
          width: width,
          tintId: tintId,
          mark: mark,
          avatarId: avatarId,
          previewTheme: packTheme,
          onTap: onTapBack == null ? null : SoundService.wrapTap(onTapBack),
        ),
        SizedBox(width: width > 44 ? 12 : 8),
        WinningCardPreview(width: width, avatarId: avatarId),
      ],
    );
  }
}

class _PackActionButton extends StatelessWidget {
  const _PackActionButton({
    required this.pack,
    required this.owned,
    required this.equipped,
    required this.packTheme,
    required this.previewAvatarId,
    required this.previewTintId,
  });

  final ThemePack pack;
  final bool owned;
  final bool equipped;
  final AppTheme packTheme;
  final String previewAvatarId;
  final String previewTintId;

  @override
  Widget build(BuildContext context) {
    if (pack.isPlayLocked && !owned) {
      return _CircleBadge(
        packTheme: packTheme,
        child: Icon(
          CupertinoIcons.lock_fill,
          size: 20,
          color: packTheme.textPrimary.withValues(alpha: .78),
        ),
      );
    }

    if (!owned && pack.isCoinLocked) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: SoundService.wrapTap(() => _buy(context)),
        child: _CircleBadge(
          packTheme: packTheme,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(coinIcon, size: 12, color: packTheme.turnHighlight),
              Text(
                '${pack.coinCost}',
                style: TextStyle(
                  color: packTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (equipped) {
      return _CircleBadge(
        packTheme: packTheme,
        child: Icon(
          CupertinoIcons.check_mark,
          size: 20,
          color: packTheme.turnHighlight,
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(() => _use(context)),
      child: _CircleBadge(
        packTheme: packTheme,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            child: Text(
              l10n.useTable,
              style: TextStyle(
                color: packTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _use(BuildContext context) async {
    final vm = context.read<AppThemeViewModel>();
    await vm.equipPack(pack.id, avatarId: previewAvatarId);
    vm.setCardBackTintId(previewTintId);
  }

  Future<void> _buy(BuildContext context) async {
    final cost = pack.coinCost ?? 0;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmStorePurchase(
      context,
      body: l10n.confirmBuyPack(themeLabel(pack.id), cost),
    );
    if (!confirmed || !context.mounted) return;
    final repo = context.read<AppRepo>();
    if (repo.wallet.coins < cost) {
      await showInsufficientFundsDialog(context, energy: false);
      return;
    }
    final ok = await context.read<AppThemeViewModel>().buyPack(pack.id);
    if (!ok && context.mounted) {
      await showInsufficientFundsDialog(context, energy: false);
    }
  }
}

class _CircleBadge extends StatelessWidget {
  const _CircleBadge({required this.packTheme, required this.child});

  final AppTheme packTheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: packTheme.textPrimary.withValues(alpha: .14),
        shape: BoxShape.circle,
        border: Border.all(color: packTheme.textPrimary.withValues(alpha: .18)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
