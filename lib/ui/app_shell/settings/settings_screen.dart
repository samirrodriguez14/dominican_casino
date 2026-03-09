import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/settings/theme_option.dart';
import 'package:dominican_casino/view_models/app_theme_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

///MOVE TO APPSTATE OR SOMEWHERE ELSE
enum Theme { feltWaltnut, walnut, casino, midnight }

enum Cardtheme { blue, dark, wood }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = context.read<AppThemeViewModel>();
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Choose Your Table",
              style: AppStyle.theme.title.copyWith(fontSize: 40),
            ),
            SizedBox(height: 20),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: Theme.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final themeType = Theme.values[index];
                final previewTheme = AppRepo.themeFromEnum(themeType);
                final selected = vm.appTheme == themeType;

                return ThemeOptionCard(
                  themeType: themeType,
                  previewTheme: previewTheme,
                  selected: selected,
                  onTap: () => vm.selectTheme(themeType),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}
