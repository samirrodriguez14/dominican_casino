import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<StatefulWidget> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = context.read<ProfileViewModel>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.profile_circled, size: 150),
          GestureDetector(
            onTap: () async {
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
            },

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppStyle.theme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.person,
                    size: 16,
                    color: AppStyle.theme.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(vm.name, style: AppStyle.theme.body),
                  const SizedBox(width: 6),
                  Icon(
                    CupertinoIcons.pencil,
                    size: 14,
                    color: AppStyle.theme.muted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
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
        child: Text('Cancel', style: AppStyle.theme.mutedText,),
        onPressed: () => Navigator.pop(context),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        child: Text('Save',  style: AppStyle.theme.title),
        onPressed: () {
          Navigator.pop(context, controller.text.trim());
        },
      ),
    ],
  );
}
