import 'dart:math';

import 'package:dominican_casino/game_control/game_engine/rummy/rummy_requirement.dart';

/// A deal-time contract: one or two requirements that must be satisfied.
///
/// For v1 we always generate 2 requirements that sum to 7 cards, but the
/// matcher supports 1-requirement contracts as well (useful for later UI
/// variants where box B can be hidden).
class RummyContract {
  RummyContract({
    required this.requirements,
  }) : assert(requirements.isNotEmpty);

  final List<RummyRequirement> requirements;

  int get totalCards =>
      requirements.fold<int>(0, (sum, r) => sum + r.count);

  String get label {
    if (requirements.length == 1) return requirements.first.label;
    return '${requirements[0].label} + ${requirements[1].label}';
  }

  Map<String, dynamic> toJson() => {
        'requirements': requirements.map((r) => r.toJson()).toList(),
      };

  static RummyContract fromJson(Map<String, dynamic> m) {
    final rawReqs = m['requirements'] as List<dynamic>? ?? const [];
    final reqs = rawReqs
        .whereType<Map<String, dynamic>>()
        .map((e) => RummyRequirement.fromJson(e))
        .toList();
    if (reqs.isEmpty) {
      throw ArgumentError('RummyContract requires non-empty requirements');
    }
    return RummyContract(requirements: reqs);
  }

  /// v1 random pool:
  /// - Run of 5 + set of 2
  /// - Run of 4 + set of 3
  /// - Set of 4 + set of 3
  /// - Color of 5 + set of 2
  /// - Color of 4 + set of 3
  ///
  /// Note: color is chosen randomly red/black.
  static RummyContract pickRandom({Random? rng}) {
    final r = rng ?? Random.secure();

    final patterns = <RummyContract Function()>[
      () => RummyContract(
            requirements: [
              RummyRequirement.run(5),
              RummyRequirement.set(2),
            ],
          ),
      () => RummyContract(
            requirements: [
              RummyRequirement.run(4),
              RummyRequirement.set(3),
            ],
          ),
      () => RummyContract(
            requirements: [
              RummyRequirement.set(4),
              RummyRequirement.set(3),
            ],
          ),
      () {
        final color = r.nextBool() ? RummyColor.red : RummyColor.black;
        return RummyContract(
          requirements: [
            RummyRequirement.colorOf(5, color),
            RummyRequirement.set(2),
          ],
        );
      },
      () {
        final color = r.nextBool() ? RummyColor.red : RummyColor.black;
        return RummyContract(
          requirements: [
            RummyRequirement.colorOf(4, color),
            RummyRequirement.set(3),
          ],
        );
      },
    ];

    return patterns[r.nextInt(patterns.length)]();
  }
}

