import 'dart:math';

import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/widgets/color_chooser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  test('Can replace player', () {
    final game = randomEmptyGame();

    int switchingPlayerIndex = randomPlayerIndex();
    String newPlayerId = randomId();
    game.replacePlayer(switchingPlayerIndex, newPlayerId);

    expect(game.rounds.length, 1);
    expect(game.rounds.last.isPlayerSwitch, isTrue);
    expect(game.rounds.last.switchingPlayerIndex, switchingPlayerIndex);
    expect(game.rounds.last.newPlayerId, newPlayerId);
  });

  test('Unfinished round pushed to end when player replaced', () {
    final game = randomEmptyGame();

    int dealerIndex = randomPlayerIndex();
    game.newRound(dealerIndex);
    int bidderIndex = randomPlayerIndex();
    game.addBid(dealerIndex, bidderIndex, randomBid());
    int switchingPlayerIndex = randomPlayerIndex();
    String newPlayerId = randomId();
    game.replacePlayer(switchingPlayerIndex, newPlayerId);

    expect(game.rounds.length, 2);
    expect(game.rounds[0].isPlayerSwitch, isTrue);
    expect(game.rounds.last.dealerIndex, dealerIndex);
    expect(game.rounds.last.bidderIndex, bidderIndex);
  });

  test('Can add new round', () {
    final game = randomEmptyGame();

    int dealerIndex = randomPlayerIndex();
    game.newRound(dealerIndex);

    expect(game.rounds.length, 1);
    expect(game.rounds.last.dealerIndex, dealerIndex);
  });

  test('Can add bidding info', () {
    final game = randomEmptyGame();

    game.newRound(randomPlayerIndex());
    int dealerIndex = randomPlayerIndex();
    int bidderIndex = randomPlayerIndex();
    int bid = randomBid();
    game.addBid(dealerIndex, bidderIndex, bid);

    expect(game.rounds.last.dealerIndex, dealerIndex);
    expect(game.rounds.last.bidderIndex, bidderIndex);
    expect(game.rounds.last.bid, bid);
  });

  test('Can add round result', () {
    final game = randomEmptyGame();

    game.newRound(randomPlayerIndex());
    game.addBid(randomPlayerIndex(), randomPlayerIndex(), randomBid());
    int wonTricks = randomWonTricks();
    game.addRoundResult(wonTricks);

    expect(game.rounds.last.wonTricks, wonTricks);
  });

  test('Adding round result makes round finished', () {
    final game = randomEmptyGame();

    game.newRound(randomPlayerIndex());
    game.addBid(randomPlayerIndex(), randomPlayerIndex(), randomBid());
    game.addRoundResult(randomWonTricks());

    expect(game.rounds.last.isFinished, true);
  });

  test('No new round when last is unfinished', () {
    final game = randomEmptyGame();

    game.newRound(randomPlayerIndex());
    game.addBid(randomPlayerIndex(), randomPlayerIndex(), randomBid());
    game.newRound(randomPlayerIndex());

    expect(game.rounds.length, 1);
  });

  test('No add bid out of order', () {
    final game = randomEmptyGame();

    game.newRound(randomPlayerIndex());
    int oldBidderIndex = randomPlayerIndex();
    int newBidderIndex = randomPlayerIndex();
    game.addBid(randomPlayerIndex(), oldBidderIndex, randomBid());
    game.addBid(randomPlayerIndex(), newBidderIndex, randomBid());

    expect(game.rounds.last.bidderIndex, oldBidderIndex);
  });

  test('No add round result out of order', () {
    final game = randomEmptyGame();

    game.newRound(randomPlayerIndex());
    game.addRoundResult(randomWonTricks());

    expect(game.rounds.last.wonTricks, isNull);
  });

  test('No add round result out of order', () {
    final game = randomEmptyGame();

    game.newRound(randomPlayerIndex());
    game.addRoundResult(randomWonTricks());

    expect(game.rounds.last.wonTricks, isNull);
  });

  test('Undo player switch deletes round', () {
    final game = randomEmptyGame();

    game.replacePlayer(randomPlayerIndex(), randomId());
    game.undoLastAction();

    expect(game.rounds.length, 0);
  });

  test('Undo new round deletes round', () {
    final game = randomEmptyGame();

    game.newRound(randomPlayerIndex());
    game.undoLastAction();

    expect(game.rounds.length, 0);
  });

  test('Undo bid deletes bidder index', () {
    final game = randomEmptyGame();

    game.newRound(randomPlayerIndex());
    game.addBid(randomPlayerIndex(), randomPlayerIndex(), randomBid());
    game.undoLastAction();

    expect(game.rounds.last.bidderIndex, isNull);
  });

  test('Undo round result deletes wonTricks', () {
    final game = randomEmptyGame();

    game.newRound(randomPlayerIndex());
    game.addBid(randomPlayerIndex(), randomPlayerIndex(), randomBid());
    game.addRoundResult(randomWonTricks());
    game.undoLastAction();

    expect(game.rounds.last.wonTricks, isNull);
  });
}

Game randomEmptyGame() {
  Random rand = Random();
  Map gameData = {
    'userId': randomId(),
    'gameOverScore': rand.nextInt(49) + 12,
    'initialPlayerIds': [randomId(), randomId(), randomId(), randomId()],
    'rounds': [],
    'teamColors': [ColorChooser.generateRandomColor().value, ColorChooser.generateRandomColor().value],
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  return Game.fromData(randomId(), gameData);
}

int randomWonTricks() {
  return Random().nextInt(7);
}
