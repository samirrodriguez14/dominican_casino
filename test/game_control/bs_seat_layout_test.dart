import 'package:dominican_casino/game_control/game_engine/bs/bs_seat_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('3 opponents match Tres/Rummy left-top-right ring', () {
    final seats = BsSeatLayout.fromOppIds(['a', 'b', 'c']);
    expect(seats.leftTop, 'a');
    expect(seats.top, 'b');
    expect(seats.rightTop, 'c');
    expect(seats.leftBottom, isNull);
    expect(seats.rightBottom, isNull);
  });

  test('5 opponents are clockwise: LB → LT → top → RT → RB', () {
    final seats = BsSeatLayout.fromOppIds(['p1', 'p2', 'p3', 'p4', 'p5']);
    expect(seats.leftBottom, 'p1'); // first after local player
    expect(seats.leftTop, 'p2');
    expect(seats.top, 'p3');
    expect(seats.rightTop, 'p4');
    expect(seats.rightBottom, 'p5');
  });

  test('4 opponents put first seat at left bottom', () {
    final seats = BsSeatLayout.fromOppIds(['p1', 'p2', 'p3', 'p4']);
    expect(seats.leftBottom, 'p1');
    expect(seats.leftTop, 'p2');
    expect(seats.top, 'p3');
    expect(seats.rightTop, 'p4');
    expect(seats.rightBottom, isNull);
  });
}
