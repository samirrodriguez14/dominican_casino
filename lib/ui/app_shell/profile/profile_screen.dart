import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/games_screen.dart';
import 'package:dominican_casino/ui/app_shell/profile/game_history.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<StatefulWidget> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  GameMode? selectedMode;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ProfileViewModel>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          SizedBox(height: 10),

          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipOval(child: Icon(CupertinoIcons.profile_circled, size: 150)),
              Icon(CupertinoIcons.pencil_circle, size: 50),
            ],
          ),
          GestureDetector(
            onTap: () => _changeName(context, vm),
            child: _buildNameSelectionButton(vm),
          ),

          Expanded(
            child: GameHistorySection(
              selectedMode: selectedMode,
              onModeChanged: (mode) => setState(() {
                selectedMode = mode;
              }),
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

Widget _buildNameSelectionButton(ProfileViewModel vm) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: AppStyle.theme.raisedSurfaceBox(),
    //  BoxDecoration(
    //   color: AppStyle.theme.surface,
    //   borderRadius: BorderRadius.circular(10),
    // ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.person, size: 30, color: AppStyle.theme.border),
        const SizedBox(width: 8),
        Text(vm.name, style: AppStyle.theme.body.copyWith(fontSize: 24)),
        const SizedBox(width: 6),
        Icon(CupertinoIcons.pencil, size: 30, color: AppStyle.theme.muted),
      ],
    ),
  );
}

Future<void> _changeName(BuildContext context, ProfileViewModel vm) async {
  final controller = TextEditingController(text: vm.name);

  final newName =
      await showCupertinoDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return _showCupertinoDialog(context, controller);
        },
      ) ??
      vm.name;

  if (newName != vm.name) {
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
