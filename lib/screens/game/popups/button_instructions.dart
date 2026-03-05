import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ControlsLegendContent extends StatelessWidget {
  const ControlsLegendContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _LegendRow(
          icon: CupertinoIcons.square_arrow_up_fill,
          title: "Play",
          desc: "Play your selected card to the table (ends your turn).",
        ),
        _LegendRow(
          icon: CupertinoIcons.square_arrow_down_fill,
          title: "Take",
          desc:
              "Take cards/stacks from the table using your selected hand card.",
        ),
        _LegendRow(
          icon: CupertinoIcons.square_arrow_down_on_square_fill,
          title: "+Take combo",
          desc:
              "Adds the selected table cards and takes them if your hand card matches the value of the sum.",
        ),
        _LegendRow(
          icon: CupertinoIcons.plus_square_fill,
          title: "Add ",
          desc: "Add all selected cards into a stack.",
        ),
        _LegendRow(
          icon: CupertinoIcons.plus_square_fill_on_square_fill,
          title: "+Pair combo",
          desc:
              "Adds your hand card to the selected card/sack and pairs it to any card/stack matching its value.",
        ),
        _LegendRow(
          icon: CupertinoIcons.square_fill_on_square_fill,
          title: "Pair",
          desc: "Pair selected cards/stacks if they are all of the same value.",
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
    final bg = AppStyle.theme.surfaceAlt;
    final fg = AppStyle.theme.textPrimary;
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
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyle.theme.title.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: AppStyle.theme.mutedText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
