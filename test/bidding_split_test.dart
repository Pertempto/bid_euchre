import 'package:bideuchre/data/bidding_split.dart';
import 'package:bideuchre/data/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dummyRounds = [
    Round(0, 0, 0, 3, 4), // +4 points
    Round(0, 0, 0, 3, 2), // -3 points, didn't make bid
    Round(0, 0, 0, 3, 5), // +5 points
  ];

  test('Average points with no rounds is nan', () {
    final split = BiddingSplit([]);

    expect(split.avgPoints, isNaN);
  });

  test('Average points is correct', () {
    final split = BiddingSplit(dummyRounds);

    expect(split.avgPoints, 2);
  });

  test('Average tricks with no rounds is nan', () {
    final split = BiddingSplit([]);

    expect(split.avgTricks, isNaN);
  });

  test('Average tricks is correct', () {
    final split = BiddingSplit(dummyRounds);

    expect(split.avgTricks, 11 / 3);
  });

  test('Count is correct', () {
    final split = BiddingSplit(dummyRounds);

    expect(split.count, 3);
  });

  test('Made is correct', () {
    final split = BiddingSplit(dummyRounds);

    expect(split.made, 2);
  });

  test('Made pct with no rounds is nan', () {
    final split = BiddingSplit([]);

    expect(split.madePct, isNaN);
  });

  test('Made pct is correct', () {
    final split = BiddingSplit(dummyRounds);

    expect(split.madePct, 2 / 3);
  });
}
