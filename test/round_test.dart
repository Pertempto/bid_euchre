import 'package:bideuchre/data/round.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Empty round is empty', () {
    final round = Round.empty(0, 0);

    expect(round.isPlayerSwitch, isFalse);
    expect(round.bidderIndex, isNull);
    expect(round.bid, isNull);
    expect(round.wonTricks, isNull);
  });

  test('Empty round is not finished', () {
    final round = Round.empty(0, 0);

    expect(round.isFinished, isFalse);
  });

  test('Can create player switch', () {
    final round = Round.playerSwitch(0, 0, 'newId');

    expect(round.isPlayerSwitch, isTrue);
  });

  test('Round is finished', () {
    final round = Round(0, 0, 0, 3, 6);

    expect(round.isFinished, isTrue);
  });

  test('Not made slide', () {
    final round = Round(0, 0, 0, 12, 5);

    expect(round.madeBid, isFalse);
  });

  test('Made loner', () {
    final round = Round(0, 0, 0, 24, 6);

    expect(round.madeBid, isTrue);
  });
}
