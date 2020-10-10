import 'dart:math';

import 'package:bideuchre/data/round.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  test('Empty round is empty', () {
    final round = emptyRound();

    expect(round.isPlayerSwitch, isFalse);
    expect(round.bidderIndex, isNull);
    expect(round.bid, isNull);
    expect(round.wonTricks, isNull);
  });

  test('Empty round is not finished', () {
    final round = emptyRound();

    expect(round.isFinished, isFalse);
  });

  test('Can create player switch', () {
    final round = playerSwitch();

    expect(round.isPlayerSwitch, isTrue);
  });

  test('Player switch is finished', () {
    final round = Round.playerSwitch(0, 0, 'newId');

    expect(round.isFinished, isTrue);
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

Round emptyRound() {
  int roundIndex = Random().nextInt(30);
  return Round.empty(roundIndex, randomPlayerIndex());
}

Round playerSwitch() {
  return Round.playerSwitch(randomPlayerIndex(), randomPlayerIndex(), randomId());
}
