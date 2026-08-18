import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class CasinoBoard extends StatelessWidget {
  final Widget child;

  const CasinoBoard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: theme.surfaceAlt,
        border: Border.all(color: theme.border.withValues(alpha: .45)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: theme.tableBackground().copyWith(
            borderRadius: BorderRadius.circular(22),
          ),
          child: child,
        ),
      ),
    );
  }
}
