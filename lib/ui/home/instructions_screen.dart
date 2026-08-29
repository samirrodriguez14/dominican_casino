import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_actions.dart';
import 'package:dominican_casino/ui/home/home_instruction_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  Future<InstructionsData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= loadInstructions(
      GameMode.casino,
      locale: Localizations.localeOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CupertinoPageScaffold(
      backgroundColor: AppStyle.theme.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.instructions),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: SoundService.wrapTap(() => context.go('/home')),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<InstructionsData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  l10n.instructions,
                  style: AppStyle.theme.body,
                ),
              );
            }
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
          InstructionSectionContent(
            section: section,
            bodyFontSize: 20,
            cardWidth: 64,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '$pageNumber / $totalPages',
              style: AppStyle.theme.body,
            ),
          ),
        ],
      ),
    );
  }
}
