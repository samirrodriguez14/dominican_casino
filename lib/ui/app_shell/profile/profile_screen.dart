import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_pill.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProfileViewModel>();
      final pid = vm.player?.id;
      if (pid != null) {
        vm.startListening(pid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ProfileViewModel>();

    return SafeArea(
      child: Stack(
        children: [
          // PROFILE CONTENT
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: const [
                    ClipOval(
                      child: Icon(CupertinoIcons.profile_circled, size: 150),
                    ),
                    Icon(CupertinoIcons.pencil_circle, size: 50),
                  ],
                ),

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () => _changeName(context, vm),
                  child: _buildNameSelectionButton(vm),
                ),
              ],
            ),
          ),

          // HISTORY SHEET
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            snap: true,
            snapSizes: const [0.15, 0.8],
            builder: (context, scrollController) {
              return _GameHistorySheet(
                scrollController: scrollController,
                vm: vm,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GameHistorySheet extends StatelessWidget {
  const _GameHistorySheet({required this.scrollController, required this.vm});
  final ProfileViewModel vm;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, -4),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // handle
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: AppStyle.theme.muted.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          const SizedBox(height: 8),

          Text("Game History", style: AppStyle.theme.mutedText),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: vm.games.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                
                return GamePill(game: vm.games[i], myPid: vm.player?.id ?? "");
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildNameSelectionButton(ProfileViewModel vm) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: AppStyle.theme.raisedSurfaceBox(),

    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.person, size: 30, color: AppStyle.theme.border),
        const SizedBox(width: 8),
        Text(
          vm.player?.name ?? "",
          style: AppStyle.theme.body.copyWith(fontSize: 24),
        ),
        const SizedBox(width: 6),
        Icon(CupertinoIcons.pencil, size: 30, color: AppStyle.theme.muted),
      ],
    ),
  );
}

Future<void> _changeName(BuildContext context, ProfileViewModel vm) async {
  final controller = TextEditingController(text: vm.player?.name);

  final newName =
      await showCupertinoDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return _showCupertinoDialog(context, controller);
        },
      ) ??
      vm.player?.name ??
      "";

  if (newName != vm.player?.name) {
    await vm.updatePlayerName(newName);
  }
}

CupertinoAlertDialog _showCupertinoDialog(
  BuildContext context,
  TextEditingController controller,
) {
  return CupertinoAlertDialog(
    title: const Text('Edit name'),
    content: Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CupertinoTextField(
        groupId: controller.text,
        controller: controller,
        maxLength: 10,
        placeholder: 'Enter your name',
        autofocus: true,
      ),
    ),
    actions: [
      CupertinoDialogAction(
        child: Text('Cancel', style: AppStyle.theme.mutedText),
        onPressed: () => Navigator.pop(context),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        child: Text('Save', style: AppStyle.theme.title),
        onPressed: () {
          Navigator.pop(context, controller.text.trim());
        },
      ),
    ],
  );
}
