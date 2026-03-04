import 'package:dominican_casino/style/theme_data.dart';
import 'package:flutter/cupertino.dart';

class ControlsLegendContent extends StatelessWidget {
  const ControlsLegendContent({super.key});


  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _LegendRow(
          icon:  CupertinoIcons.square_arrow_up_on_square_fill,
          title: "Play",
          desc: "Play your selected card to the table (ends your turn).",
        ),
        _LegendRow(
          icon:  CupertinoIcons.square_arrow_down_on_square_fill,
          title: "Take",
          desc:
              "Take cards/stacks from the table using your selected hand card.",
        ),
        _LegendRow(
          icon: CupertinoIcons.plus_square_fill_on_square_fill ,
          title: "Add",
          desc: "Combine selected table cards into a stack.",
        ),
        _LegendRow(
          icon: CupertinoIcons.rectangle_stack_fill_badge_plus ,
          title: "Add/Pair",
          desc: "Add and immediately pair into another stack (combo action).",
        ),
        _LegendRow(
          icon: CupertinoIcons.square_stack_3d_down_dottedline,
          title: "Pair",
          desc: "Pair selected cards/stacks according to your rules.",
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
       final bg =  AppColors.surfaceAlt ;
    final fg =  AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: fg,),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.title.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: AppStyles.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
