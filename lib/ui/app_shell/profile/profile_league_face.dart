import 'dart:ui';

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/league.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/shared/match_stats_widgets.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

enum _LeagueTab { league, friends }

/// Back face of the profile card: League leaderboard + Friends ranked by league.
class ProfileLeagueFace extends StatefulWidget {
  const ProfileLeagueFace({
    super.key,
    required this.score,
    required this.onFlipBack,
  });

  final AvatarScoreTheme score;
  final VoidCallback onFlipBack;

  @override
  State<ProfileLeagueFace> createState() => _ProfileLeagueFaceState();
}

class _ProfileLeagueFaceState extends State<ProfileLeagueFace> {
  _LeagueTab _tab = _LeagueTab.league;
  PageController? _leaguePager;
  int _pageIndex = 0;
  bool _didScrollToCurrent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileViewModel>().ensureLeagueLoaded();
    });
  }

  @override
  void dispose() {
    _leaguePager?.dispose();
    super.dispose();
  }

  void _ensurePager(JourneyWorld? current) {
    final target = current?.index ?? 0;
    if (_leaguePager == null) {
      _pageIndex = target;
      _leaguePager = PageController(initialPage: target);
      return;
    }
    if (!_didScrollToCurrent && _leaguePager!.hasClients) {
      _didScrollToCurrent = true;
      if (_leaguePager!.page?.round() != target) {
        _leaguePager!.jumpToPage(target);
        _pageIndex = target;
      }
    }
  }

  void _goToJourney() {
    final repo = context.read<AppRepo>();
    widget.onFlipBack();
    repo.requestShellTab(1);
    repo.requestOpenJourney();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<ProfileViewModel>();
    final score = widget.score;
    final palette = StatsPalette.fromAvatarScore(score);
    final league = vm.currentLeague;
    _ensurePager(league);
    final pageWorld = JourneyWorld.values[_pageIndex.clamp(
      0,
      JourneyWorld.values.length - 1,
    )];
    final title = l10n.leagueName(pageWorld.label);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: score.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.swipeLeaguesHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: score.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoSlidingSegmentedControl<_LeagueTab>(
                groupValue: _tab,
                backgroundColor: score.panel.withValues(alpha: 0.7),
                thumbColor: score.panel,
                children: {
                  _LeagueTab.league: _segLabel(l10n.league, score),
                  _LeagueTab.friends: _segLabel(l10n.friends, score),
                },
                onValueChanged: (value) {
                  if (value == null) return;
                  SoundService.instance.playLayered(GameSound.softCard);
                  setState(() => _tab = value);
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: vm.leagueLoading && _tab == _LeagueTab.league
                    ? const Center(child: CupertinoActivityIndicator())
                    : switch (_tab) {
                        _LeagueTab.league => _LeaguePager(
                            controller: _leaguePager!,
                            palette: palette,
                            currentLeague: league,
                            top: vm.leagueTop,
                            ownRank: vm.leagueOwnRank,
                            ownWins: vm.player?.matchStats.wins ?? 0,
                            ownName: vm.player?.name,
                            ownAvatarId: vm.player?.avatarId,
                            ownUid: vm.player?.id,
                            topFriends: vm.leagueTopFriends,
                            exitRankFor: vm.exitRankFor,
                            onGoToJourney: _goToJourney,
                            onPageChanged: (i) {
                              setState(() {
                                _pageIndex = i;
                                _didScrollToCurrent = true;
                              });
                            },
                          ),
                        _LeagueTab.friends => _FriendsTab(
                            palette: palette,
                            friends: vm.leagueFriends,
                          ),
                      },
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _FlipBackButton(
              score: score,
              onPressed: widget.onFlipBack,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _segLabel(String text, AvatarScoreTheme score) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          color: score.ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LeaguePager extends StatefulWidget {
  const _LeaguePager({
    required this.controller,
    required this.palette,
    required this.currentLeague,
    required this.top,
    required this.ownRank,
    required this.ownWins,
    required this.ownName,
    required this.ownAvatarId,
    required this.ownUid,
    required this.topFriends,
    required this.exitRankFor,
    required this.onGoToJourney,
    required this.onPageChanged,
  });

  final PageController controller;
  final StatsPalette palette;
  final JourneyWorld? currentLeague;
  final List<PublicProfile> top;
  final int? ownRank;
  final int ownWins;
  final String? ownName;
  final String? ownAvatarId;
  final String? ownUid;
  final List<PublicProfile> topFriends;
  final int? Function(JourneyWorld world) exitRankFor;
  final VoidCallback onGoToJourney;
  final ValueChanged<int> onPageChanged;

  @override
  State<_LeaguePager> createState() => _LeaguePagerState();
}

class _LeaguePagerState extends State<_LeaguePager> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
  }

  @override
  void didUpdateWidget(covariant _LeaguePager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLeague != widget.currentLeague) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
    }
  }

  void _jumpToCurrent() {
    if (!widget.controller.hasClients) return;
    final target = widget.currentLeague?.index ?? 0;
    if (widget.controller.page?.round() == target) return;
    widget.controller.jumpToPage(target);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.controller,
      scrollDirection: Axis.vertical,
      itemCount: JourneyWorld.values.length,
      onPageChanged: widget.onPageChanged,
      itemBuilder: (context, index) {
        final world = JourneyWorld.values[index];
        final status = leaguePageStatus(
          world: world,
          currentLeague: widget.currentLeague,
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 52),
          child: switch (status) {
            LeaguePageStatus.current => _CurrentLeaguePage(
                world: world,
                palette: widget.palette,
                top: widget.top,
                ownRank: widget.ownRank,
                ownWins: widget.ownWins,
                ownName: widget.ownName,
                ownAvatarId: widget.ownAvatarId,
                ownUid: widget.ownUid,
                topFriends: widget.topFriends,
              ),
            LeaguePageStatus.past => _PastLeaguePage(
                world: world,
                palette: widget.palette,
                exitRank: widget.exitRankFor(world),
              ),
            LeaguePageStatus.locked => _LockedLeaguePage(
                world: world,
                palette: widget.palette,
                isNext: widget.currentLeague == null
                    ? index == 0
                    : index == widget.currentLeague!.index + 1,
                onGoToJourney: widget.onGoToJourney,
              ),
          },
        );
      },
    );
  }
}

class _CurrentLeaguePage extends StatelessWidget {
  const _CurrentLeaguePage({
    required this.world,
    required this.palette,
    required this.top,
    required this.ownRank,
    required this.ownWins,
    required this.ownName,
    required this.ownAvatarId,
    required this.ownUid,
    required this.topFriends,
  });

  final JourneyWorld world;
  final StatsPalette palette;
  final List<PublicProfile> top;
  final int? ownRank;
  final int ownWins;
  final String? ownName;
  final String? ownAvatarId;
  final String? ownUid;
  final List<PublicProfile> topFriends;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inTop = top.any((p) => p.uid == ownUid);

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        _LeagueHeaderChip(
          world: world,
          palette: palette,
          trailing: ownRank == null ? null : l10n.yourRank(ownRank!),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.topOfLeague,
          style: TextStyle(
            color: palette.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (top.isEmpty && ownUid != null)
          _LeaderRow(
            rank: ownRank ?? 1,
            profile: PublicProfile(
              uid: ownUid!,
              name: ownName,
              avatarId: ownAvatarId,
              wins: ownWins,
              league: world,
            ),
            palette: palette,
            highlight: true,
          )
        else if (top.isEmpty)
          Text(
            '—',
            style: TextStyle(color: palette.muted, fontWeight: FontWeight.w600),
          )
        else
          for (var i = 0; i < top.length; i++) ...[
            _LeaderRow(
              rank: i + 1,
              profile: top[i],
              palette: palette,
              highlight: top[i].uid == ownUid,
            ),
            const SizedBox(height: 6),
          ],
        if (!inTop && top.isNotEmpty && ownUid != null) ...[
          const SizedBox(height: 4),
          _LeaderRow(
            rank: ownRank ?? (top.length + 1),
            profile: PublicProfile(
              uid: ownUid!,
              name: ownName,
              avatarId: ownAvatarId,
              wins: ownWins,
              league: world,
            ),
            palette: palette,
            highlight: true,
          ),
        ],
        const SizedBox(height: 14),
        Text(
          l10n.topFriends,
          style: TextStyle(
            color: palette.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (topFriends.isEmpty)
          Text(
            l10n.leagueEmptyFriends,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          for (var i = 0; i < topFriends.length; i++) ...[
            _LeaderRow(
              rank: i + 1,
              profile: topFriends[i],
              palette: palette,
              showLeague: true,
            ),
            const SizedBox(height: 6),
          ],
      ],
    );
  }
}

class _PastLeaguePage extends StatelessWidget {
  const _PastLeaguePage({
    required this.world,
    required this.palette,
    required this.exitRank,
  });

  final JourneyWorld world;
  final StatsPalette palette;
  final int? exitRank;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LeagueHeaderChip(
          world: world,
          palette: palette,
          trailing: l10n.previousLeague,
        ),
        const Spacer(),
        Icon(
          CupertinoIcons.flag_fill,
          size: 36,
          color: palette.muted.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 12),
        Text(
          exitRank != null
              ? l10n.leagueFinishedRank(exitRank!)
              : l10n.leagueFinished,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.leagueName(world.label),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _LockedLeaguePage extends StatelessWidget {
  const _LockedLeaguePage({
    required this.world,
    required this.palette,
    required this.isNext,
    required this.onGoToJourney,
  });

  final JourneyWorld world;
  final StatsPalette palette;
  final bool isNext;
  final VoidCallback onGoToJourney;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LeagueHeaderChip(
          world: world,
          palette: palette,
          trailing: l10n.locked,
          locked: true,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.55,
                      child: _FakeLockedLeaderboard(palette: palette),
                    ),
                  ),
                ),
                Container(
                  color: palette.panel.withValues(alpha: 0.35),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.lock_fill,
                          size: 28,
                          color: palette.ink.withValues(alpha: 0.75),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.leagueLockedFor(world.label),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        if (isNext) ...[
                          const SizedBox(height: 14),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: palette.foreground.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: SoundService.wrapTap(onGoToJourney),
                            child: Text(
                              l10n.goToJourney,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FakeLockedLeaderboard extends StatelessWidget {
  const _FakeLockedLeaderboard({required this.palette});

  final StatsPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      children: [
        for (var i = 1; i <= 5; i++) ...[
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Text(
                  '#$i',
                  style: TextStyle(
                    color: palette.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: palette.ink.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: palette.ink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 10,
                  decoration: BoxDecoration(
                    color: palette.ink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LeagueHeaderChip extends StatelessWidget {
  const _LeagueHeaderChip({
    required this.world,
    required this.palette,
    this.trailing,
    this.locked = false,
  });

  final JourneyWorld world;
  final StatsPalette palette;
  final String? trailing;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          world.suitSymbol,
          style: TextStyle(
            color: locked
                ? palette.ink.withValues(alpha: 0.45)
                : palette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            world.label,
            style: TextStyle(
              color: palette.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              color: palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (locked) ...[
          const SizedBox(width: 4),
          Icon(CupertinoIcons.lock_fill, size: 12, color: palette.muted),
        ],
      ],
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({
    required this.palette,
    required this.friends,
  });

  final StatsPalette palette;
  final List<LeagueFriendRow> friends;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (friends.isEmpty) {
      return Center(
        child: Text(
          l10n.leagueEmptyFriends,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 56),
      physics: const BouncingScrollPhysics(),
      children: [
        for (final row in friends) ...[
          OpponentRecordRow(
            stats: row.opponent,
            palette: palette,
            subtitle: l10n.leagueBadge(row.profile.league?.label),
            trailing: Text(
              '${row.profile.wins} ${l10n.leagueWinsLabel}',
              style: TextStyle(
                color: palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.profile,
    required this.palette,
    this.highlight = false,
    this.showLeague = false,
  });

  final int rank;
  final PublicProfile profile;
  final StatsPalette palette;
  final bool highlight;
  final bool showLeague;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? palette.foreground.withValues(alpha: 0.14)
            : palette.panel.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          PlayerAvatarView(
            avatarId: profile.avatarId,
            size: 28,
            showBorder: false,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name?.trim().isNotEmpty == true
                      ? profile.name!
                      : 'Rival',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (showLeague) ...[
                  const SizedBox(height: 1),
                  Text(
                    l10n.leagueBadge(profile.league?.label),
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${profile.wins}',
            style: TextStyle(
              color: palette.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipBackButton extends StatelessWidget {
  const _FlipBackButton({required this.score, required this.onPressed});

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
          CupertinoIcons.arrow_left_right_circle_fill,
          size: 22,
          color: score.ink,
          semanticLabel: l10n.league,
        ),
      ),
    );
  }
}
