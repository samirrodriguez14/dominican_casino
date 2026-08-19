import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ShuffleRequest.pileBackCount keeps a full deck as a short stack', () {
    expect(ShuffleRequest.pileBackCount(0), 0);
    expect(ShuffleRequest.pileBackCount(3), 3);
    expect(ShuffleRequest.pileBackCount(8), 8);
    expect(ShuffleRequest.pileBackCount(52), ShuffleRequest.maxPileBacks);
  });
}
