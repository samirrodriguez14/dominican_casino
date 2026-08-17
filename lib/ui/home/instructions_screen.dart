import 'dart:convert';

import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  Future<InstructionsData> _loadInstructions() async {
    final raw = await rootBundle.loadString(
      'assets/config/casino_instructions.json',
    );
    return InstructionsData.fromJson(jsonDecode(raw));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppStyle.theme.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Instructions"),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: SoundService.wrapTap(() => context.go('/home')),
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<InstructionsData>(
          future: _loadInstructions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final data = snapshot.data!;

            return PageView.builder(
              itemCount: data.sections.length,
              onPageChanged: (_) {
                SoundService.instance.playLayered(GameSound.softCard);
              },
              itemBuilder: (context, index) {
                final section = data.sections[index];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _InstructionPage(
                    section: section,
                    pageNumber: index + 1,
                    totalPages: data.sections.length,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InstructionPage extends StatelessWidget {
  final InstructionSection section;
  final int pageNumber;
  final int totalPages;

  const _InstructionPage({
    required this.section,
    required this.pageNumber,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppStyle.theme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppStyle.theme.title.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 20),

          for (final paragraph in section.body) ...[
            Text(
              paragraph,
              style: AppStyle.theme.body.copyWith(fontSize: 20, height: 1.35),
            ),
            const SizedBox(height: 14),
          ],

          if (section.specialCards.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: section.specialCards.map((special) {
                return _SpecialInstructionCard(special: special);
              }).toList(),
            ),
          ],

          const SizedBox(height: 24),

          Center(
            child: Text(
              "$pageNumber / $totalPages",
              style: AppStyle.theme.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialInstructionCard extends StatelessWidget {
  final InstructionSpecialCard special;

  const _SpecialInstructionCard({required this.special});

  @override
  Widget build(BuildContext context) {
    final card = PlayingCardModel(
      id: 'instruction-${special.rank}-${special.suit}',
      rank: special.rank,
      suit: special.suit,
    );

    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppStyle.theme.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: PlayingCard(playingCardModel: card, isSelected: false),
          ),
          const SizedBox(height: 10),
          Text(
            special.label,
            textAlign: TextAlign.center,
            style: AppStyle.theme.body,
          ),
          const SizedBox(height: 4),
          Text(
            special.points,
            textAlign: TextAlign.center,
            style: AppStyle.theme.title,
          ),
        ],
      ),
    );
  }
}
