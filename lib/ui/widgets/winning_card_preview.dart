import 'dart:math' as math;

import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';

/// Mini identity card — the winning-card look (profile face, not game status).
class WinningCardPreview extends StatelessWidget {
  const WinningCardPreview({
    super.key,
    required this.width,
    this.avatarId,
    this.name = '',
  });

  final double width;
  final String? avatarId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final score = AvatarScoreTheme.of(avatarId);
    final height = width * 1.4;
    final letter = name.trim().isEmpty
        ? null
        : String.fromCharCode(name.trim().runes.first).toUpperCase();

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: score.background,
          borderRadius: BorderRadius.circular((width * 0.125).clamp(6.0, 14.0)),
          border: Border.all(color: score.ink.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .22),
              blurRadius: (width * 0.12).clamp(4.0, 10.0),
              offset: Offset(0, (width * 0.045).clamp(2.0, 4.0)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((width * 0.125).clamp(6.0, 14.0)),
          child: Stack(
            children: [
              Positioned(
                top: 6,
                left: 6,
                child: _pip(score, letter),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Transform.rotate(
                  angle: math.pi,
                  child: _pip(score, letter),
                ),
              ),
              Center(
                child: PlayerAvatarView(
                  avatarId: avatarId,
                  size: width * 0.46,
                  showBorder: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pip(AvatarScoreTheme score, String? letter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerAvatarView(avatarId: avatarId, size: width * 0.18, showBorder: false),
        if (letter != null)
          Text(
            letter,
            style: TextStyle(
              color: score.ink,
              fontSize: (width * 0.14).clamp(8.0, 12.0),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
      ],
    );
  }
}
