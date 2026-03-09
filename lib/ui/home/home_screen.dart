import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/home_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<StatefulWidget> createState()=> HomeScreenState();
}
class HomeScreenState extends State<HomeScreen>{

  @override
  Widget build(BuildContext context) {
    final HomeViewModel vm = context.watch<HomeViewModel>();

    return CupertinoPageScaffold(
      backgroundColor: AppStyle.theme.background,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            opacity: 0.35,
            image: AssetImage(AppStyle.theme.appLogo),
            fit: BoxFit.fitHeight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 28,
                ),
                decoration: AppStyle.theme.raisedSurfaceBox(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Dominican Casino",
                      textAlign: TextAlign.center,
                      style: AppStyle.theme.title.copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      height: 1,
                      width: 120,
                      color: AppStyle.theme.surfaceAlt.withValues(alpha: .6),
                    ),

                    const SizedBox(height: 20),

                    /// ---- PLAYER NAME ----
                    GestureDetector(
                      onTap: () async {
                        final controller = TextEditingController(
                          text: vm.name,
                          
                        );

                        final newName = await showCupertinoDialog<String>(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('Edit name'),
                            content: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: CupertinoTextField(
                                controller: controller,
                                maxLength: 10,
                                placeholder: 'Enter your name',
                                autofocus: true,
                              ),
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                child: const Text('Save'),
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    controller.text.trim(),
                                  );
                                },
                              ),
                            ],
                          ),
                        );

                        if (newName != null &&
                            newName.isNotEmpty &&
                            newName != vm.name) {
                          await vm.updatePlayerName(newName);
                        }
                      },
                     
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
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
                            Text(vm.name??"", style: AppStyle.theme.body),
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

                    /// ---- START BUTTON ----
                    CupertinoButton(
                      color: AppStyle.theme.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 14,
                      ),
                      onPressed: () {
                        context.go('/landing');
                      },
                      child: Text(
                        "Start",
                        style: TextStyle(
                          color: AppStyle.theme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),


                    /// ---- INSTRUCTIONS ----
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      onPressed: () {
                        context.go('/instructions');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.book,
                            size: 18,
                            color: AppStyle.theme.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Instructions",
                            style: TextStyle(
                              color: AppStyle.theme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
     
        ),
      ),
    );
  }
}
