import 'package:dominican_casino/models/playing_area_stack_model.dart';

class PlayingAreaSetModel {
  final String id;
  final List<PlayingAreaStackModel> stacks;

  final int setValue;

  final bool aceHigh;

  PlayingAreaSetModel({
    required this.id,
    required this.stacks,
    required this.setValue,
    this.aceHigh = false,
  });

  int get stackValue => stacks.fold(0, (sum, c) => sum + c.stackValue);

  bool get isValid => stackValue == setValue && setValue <= 14;
  bool get isOverLimit => stackValue > 14;

  Map<String, dynamic> toMap() => {
    'id': id,
    'setValue': setValue,
    'aceHigh': aceHigh,
    'stacks': stacks.map((c) => c.toMap()).toList(),
  };

  static PlayingAreaSetModel fromMap(Map<String, dynamic> m) {
    final rawCards = (m['stacks'] as List?) ?? const [];
    return PlayingAreaSetModel(
      id: (m['id'] as String?) ?? '',
      setValue: (m['setValue'] as num?)?.toInt() ?? 0,
      aceHigh: (m['aceHigh'] as bool?) ?? false,
      stacks: rawCards
          .map(
            (e) => PlayingAreaStackModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}
