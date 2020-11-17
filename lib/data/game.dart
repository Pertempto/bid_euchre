import 'dart:math';

import 'package:bideuchre/data/entity_raw_game_stats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../util.dart';
import 'data_store.dart';
import 'player.dart';
import 'round.dart';
import 'user.dart';

class Game {
  static const int ARCHIVE_AGE = 90;

  String gameId;
  String userId;
  int gameOverScore;
  List<String> initialPlayerIds;
  List<Round> _rounds;
  List<Color> teamColors;
  int timestamp;

  Game.fromData(String id, Map data) {
    gameId = id;
    userId = data['userId'];
    gameOverScore = data['gameOverScore'];
    if (gameOverScore == null) {
      gameOverScore = 42;
    }
    if (data['initialPlayerIds'] != null) {
      initialPlayerIds = data['initialPlayerIds'].cast<String>();
    } else {
      if (data['playerNames'] == null) {
        print('can\'t get player names for game id: $gameId');
        print(data);
      }
      initialPlayerIds = data['playerNames'].cast<String>();
    }
    _rounds = data['rounds'].map<Round>((rd) => Round.fromData(rd)).toList();
    List<int> teamColorInts;
    if (data['teamColors'] != null) {
      teamColorInts = data['teamColors'].cast<int>();
    } else {
      teamColorInts = [data['playerColors'][0], data['playerColors'][1]];
    }
    teamColors = teamColorInts.map((i) => Color(i)).toList();
    timestamp = data['timestamp'];
  }

  Game.newGame(User user, List<String> initialPlayerIds, List<Color> teamColors, int gameOverScore) {
    DocumentReference doc = DataStore.gamesCollection.doc();
    gameId = doc.id;
    userId = user.userId;
    this.initialPlayerIds = initialPlayerIds;
    this.teamColors = teamColors;
    this.gameOverScore = gameOverScore;
    timestamp = DateTime.now().millisecondsSinceEpoch;
    _rounds = [Round.empty(0)];
    print(dataMap);
    doc.set(dataMap);
  }

  Map<String, dynamic> get dataMap {
    return {
      'userId': userId,
      'gameOverScore': gameOverScore,
      'initialPlayerIds': initialPlayerIds,
      'rounds': _rounds.map((r) => r.dataMap).toList(),
      'teamColors': teamColors.map((c) => c.value).toList(),
      'timestamp': timestamp,
      'variation': 1,
    };
  }

  Set<String> get allPlayerIds {
    Set<String> playerIds = initialPlayerIds.toSet();
    for (Round r in _rounds.where((r) => r.isPlayerSwitch)) {
      playerIds.add(r.newPlayerId);
    }
    return playerIds;
  }

  List<Set<String>> get allTeamsPlayerIds {
    List<Set<String>> teamPlayerIds = [{}, {}];
    for (int i = 0; i < _rounds.length; i++) {
      List<String> ids = getPlayerIdsAfterRound(i);
      for (int j = 0; j < 4; j++) {
        teamPlayerIds[j % 2].add(ids[j]);
      }
    }
    return teamPlayerIds;
  }

  List<String> get currentPlayerIds {
    return getPlayerIdsAfterRound(_rounds.length - 1);
  }

  List<int> get currentScore {
    return getScoreAfterRound(_rounds.length - 1);
  }

  String get dateString {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateFormat formatter = DateFormat.yMd().add_jm();
    return formatter.format(date);
  }

  Set<String> get fullGamePlayerIds {
    List<Set<String>> gameSpots = [{}, {}, {}, {}];
    for (Round round in rounds) {
      List<String> playerIds = getPlayerIdsAfterRound(round.roundIndex - 1);
      for (int i = 0; i < 4; i++) {
        gameSpots[i].add(playerIds[i]);
      }
    }
    Set<String> fullGamePlayerIds = {};
    for (int i = 0; i < 4; i++) {
      if (gameSpots[i].length == 1) {
        fullGamePlayerIds.add(initialPlayerIds[i]);
      }
    }
    return fullGamePlayerIds;
  }

  bool get isArchived {
    DateTime gameDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().subtract(Duration(days: ARCHIVE_AGE)).isAfter(gameDateTime);
  }

  bool get isFinished {
    List<int> score = currentScore;
    if (score[0] == score[1]) {
      return false;
    }
    return max(score[0], score[1]) >= gameOverScore;
  }

  int get numRounds {
    return _rounds.where((r) => !r.isPlayerSwitch && r.isFinished).length;
  }

  Map<String, EntityRawGameStats> get rawStatsMap {
    Map<String, EntityRawGameStats> gameStatsMap = {};
    Set<String> ids = allPlayerIds.toSet();
    ids.addAll(teamIds);
    for (String id in ids) {
      gameStatsMap.putIfAbsent(id, () => EntityRawGameStats(id));
    }
    for (int i = 0; i < 2; i++) {
      String teamId = teamIds[i];
      gameStatsMap[teamId].isArchived = isArchived;
      if (isFinished) {
        gameStatsMap[teamId].isFinished = true;
        gameStatsMap[teamId].won = winningTeamIndex == i;
      }
      gameStatsMap[teamId].isFullGame = true;
      gameStatsMap[teamId].timestamp = timestamp;
    }
    Set<String> winningPlayerIds = winningTeamIndex == null ? {} : allTeamsPlayerIds[winningTeamIndex];
    Set<String> fullGamers = fullGamePlayerIds;
    for (String playerId in allPlayerIds) {
      gameStatsMap[playerId].isArchived = isArchived;
      if (isFinished) {
        gameStatsMap[playerId].isFinished = true;
        gameStatsMap[playerId].won = winningPlayerIds.contains(playerId);
      }
      gameStatsMap[playerId].isFullGame = fullGamers.contains(playerId);
      gameStatsMap[playerId].timestamp = timestamp;
    }
    for (Round round in rounds) {
      for (int i = 0; i < 2; i++) {
        String teamId = teamIds[i];
        if (teamId == null) {
          continue;
        }
        if (!round.isPlayerSwitch && round.isFinished) {
          gameStatsMap[teamId].numRounds++;
          gameStatsMap[teamId].numPoints += round.score[i];
          if (round.bidderIndex % 2 == i) {
            gameStatsMap[teamId].numBids++;
            int gainedPts = round.score[round.bidderIndex % 2] - round.score[1 - round.bidderIndex % 2];
            if (round.madeBid) {
              gameStatsMap[teamId].madeBids++;
            } else {
              gameStatsMap[teamIds[1 - i]].gainedBySet += -gainedPts;
            }
            gameStatsMap[teamId].biddingTotal += round.bid;
            gameStatsMap[teamId].gainedOnBids += gainedPts;
          }
        }
      }
      List<String> rPlayerIds = getPlayerIdsAfterRound(round.roundIndex - 1);
      if (!round.isPlayerSwitch && round.isFinished) {
        for (int i = 0; i < 4; i++) {
          String playerId = rPlayerIds[i];
          gameStatsMap[playerId].numRounds++;
          gameStatsMap[playerId].numPoints += round.score[i % 2];
        }
        String bidderId = rPlayerIds[round.bidderIndex];
        gameStatsMap[bidderId].numBids++;
        int gainedPts = round.score[round.bidderIndex % 2] - round.score[1 - round.bidderIndex % 2];
        if (round.madeBid) {
          gameStatsMap[bidderId].madeBids++;
        } else {
          gameStatsMap[rPlayerIds[(round.bidderIndex + 1) % 4]].gainedBySet += -gainedPts;
          gameStatsMap[rPlayerIds[(round.bidderIndex + 3) % 4]].gainedBySet += -gainedPts;
        }
        gameStatsMap[bidderId].biddingTotal += round.bid;
        gameStatsMap[bidderId].gainedOnBids += gainedPts;
      }
    }
    return gameStatsMap;
  }

  List<Round> get rounds {
    List<Round> rounds = [];
    for (int i = 0; i < _rounds.length; i++) {
      _rounds[i].roundIndex = i;
      rounds.add(_rounds[i]);
    }
    return rounds;
  }

  List<String> get teamIds {
    List<Set<String>> teamsPlayerIds = allTeamsPlayerIds;
    return [Util.teamId(teamsPlayerIds[0].toList()), Util.teamId(teamsPlayerIds[1].toList())];
  }

  int get winningTeamIndex {
    if (isFinished) {
      List<int> score = currentScore;
      return score.indexOf(max(score[0], score[1]));
    }
    return null;
  }

  addBid(int dealerIndex, int bidderIndex, int bid) {
    if (_rounds.isEmpty || _rounds.last.bidderIndex == null) {
      _rounds.last.dealerIndex = dealerIndex;
      _rounds.last.bidderIndex = bidderIndex;
      _rounds.last.bid = bid;
    }
  }

  addRoundResult(int wonTricks) {
    if (_rounds.isEmpty || (_rounds.last.bidderIndex != null && _rounds.last.wonTricks == null)) {
      _rounds.last.wonTricks = wonTricks;
    }
  }

  static List<Game> gamesFromSnapshot(QuerySnapshot snapshot) {
    List<Game> games = [];
    for (DocumentSnapshot documentSnapshot in snapshot.docs) {
      Map data = documentSnapshot.data();
      // for some reason player data is being sent to this function
      if (data.containsKey('fullName')) {
        return [];
      }
      int variation = data['variation'];
      if (variation == null || variation == 1) {
        games.add(Game.fromData(documentSnapshot.id, data));
      }
    }
    games.sort((a, b) => -a.timestamp.compareTo(b.timestamp));
    return games;
  }

  List<String> getPlayerIdsAfterRound(int roundIndex) {
    List<String> playerIds = initialPlayerIds.toList();
    for (int i = 0; i <= roundIndex; i++) {
      Round round = _rounds[i];
      if (round.isPlayerSwitch) {
        playerIds[round.switchingPlayerIndex] = round.newPlayerId;
      }
    }
    return playerIds;
  }

  List<int> getScoreAfterRound(int roundIndex) {
    List<int> score = [0, 0];
    for (int i = 0; i <= roundIndex; i++) {
      if (!_rounds[i].isPlayerSwitch) {
        List<int> _roundscore = _rounds[i].score;
        score[0] += _roundscore[0];
        score[1] += _roundscore[1];
      }
    }
    return score;
  }

  String getTeamName(int index, Data data, {bool fullNames = false}) {
    String player1Id = currentPlayerIds[index];
    String player2Id = currentPlayerIds[index + 2];
    List<Player> players = [data.allPlayers[player1Id], data.allPlayers[player2Id]];
    players.sort((a, b) => a.fullName.compareTo(b.fullName));
    if (fullNames) {
      return '${players[0].fullName} & ${players[1].fullName}';
    } else {
      return '${players[0].shortName} & ${players[1].shortName}';
    }
  }

  newRound(int dealerIndex) {
    if (_rounds.isEmpty || _rounds.last.isFinished) {
      _rounds.add(Round.empty(dealerIndex));
    }
  }

  replacePlayer(int switchingPlayerIndex, String newPlayerId) {
    Round playerSwitch = Round.playerSwitch(switchingPlayerIndex, newPlayerId);
    if (_rounds.isNotEmpty && !_rounds.last.isFinished) {
      _rounds.insert(_rounds.length - 1, playerSwitch);
    } else {
      _rounds.add(playerSwitch);
    }
  }

  undoLastAction() {
    if (_rounds.isEmpty) {
      return;
    }
    Round lastRound = _rounds.last;

    if (lastRound.isPlayerSwitch) {
      // delete round
      _rounds.remove(lastRound);
    } else if (lastRound.bidderIndex == null) {
      // if this round is only a placeholder dealer, and the round before that was a player switch
      if (_rounds.length > 1 && _rounds[_rounds.length - 2].isPlayerSwitch) {
        // delete player switch
        _rounds.remove(_rounds[_rounds.length - 2]);
        return;
      } else {
        // delete round
        _rounds.remove(lastRound);
        // delete thing before it
        undoLastAction();
      }
    } else if (lastRound.wonTricks == null) {
      // delete bid
      lastRound.bidderIndex = null;
      lastRound.bid = null;
    } else {
      // delete result
      lastRound.wonTricks = null;
    }
  }

  void updateFirestore() {
    DataStore.gamesCollection.doc(gameId).update(dataMap);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game &&
          runtimeType == other.runtimeType &&
          gameId == other.gameId &&
          userId == other.userId &&
          gameOverScore == other.gameOverScore &&
          initialPlayerIds == other.initialPlayerIds &&
          _rounds == other._rounds &&
          teamColors == other.teamColors &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      gameId.hashCode ^
      userId.hashCode ^
      gameOverScore.hashCode ^
      hashList(initialPlayerIds) ^
      hashList(_rounds) ^
      hashList(teamColors) ^
      timestamp.hashCode;
}
