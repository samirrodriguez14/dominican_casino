import 'package:dominican_casino/game_control/game_engine/rummy/rummy_contract.dart';

/// Rummy-specific match state.
///
/// - The chosen [contract] is determined at deal time and persisted.
/// - [boxAByPid] / [boxBByPid] are the card-id overlays the UI draws into the
///   two dotted boxes for each player.
class RummyState {
  const RummyState({
    required this.contract,
    required this.boxAByPid,
    required this.boxBByPid,
  });

  final RummyContract contract;
  final Map<String, List<String>> boxAByPid;
  final Map<String, List<String>> boxBByPid;

  Map<String, dynamic> toJson() => {
        'contract': contract.toJson(),
        'boxAByPid': boxAByPid,
        'boxBByPid': boxBByPid,
      };

  static RummyState? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;

    final contractRaw = m['contract'];
    if (contractRaw is! Map<String, dynamic>) return null;

    final contract = RummyContract.fromJson(contractRaw);

    Map<String, List<String>> mapList(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map(
        (k, v) => MapEntry(
          k.toString(),
          (v as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        ),
      );
    }

    return RummyState(
      contract: contract,
      boxAByPid: mapList(m['boxAByPid']),
      boxBByPid: mapList(m['boxBByPid']),
    );
  }
}

