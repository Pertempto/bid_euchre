import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../util.dart';
import 'data_store.dart';
import 'player.dart';
import 'user.dart';

class Game {
  String gameId;
  String userId;
  int gameOverScore;
  List<String> initialPlayerIds;
  List<Round> rounds;
  List<Color> teamColors;
  int timestamp;

  Game.fromDocument(DocumentSnapshot documentSnapshot) {
    gameId = documentSnapshot.id;
    Map data = documentSnapshot.data();
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
        print(documentSnapshot.data);
      }
      initialPlayerIds = data['playerNames'].cast<String>();
    }
    rounds = data['rounds'].map<Round>((rd) => Round.fromData(rd)).toList();
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
    rounds = [Round.empty(0, 0)];
    print(dataMap);
    doc.set(dataMap);
  }

  Map<String, dynamic> get dataMap {
    return {
      'userId': userId,
      'gameOverScore': gameOverScore,
      'initialPlayerIds': initialPlayerIds,
      'rounds': rounds.map((r) => r.dataMap).toList(),
      'teamColors': teamColors.map((c) => c.value).toList(),
      'timestamp': timestamp,
      'variation': 1,
    };
  }

  Set<String> get allPlayerIds {
    Set<String> playerIds = initialPlayerIds.toSet();
    for (Round r in rounds.where((r) => r.isPlayerSwitch)) {
      playerIds.add(r.newPlayerId);
    }
    return playerIds;
  }

  List<Set<String>> get allTeamsPlayerIds {
    List<Set<String>> teamPlayerIds = [{}, {}];
    for (int i = 0; i < rounds.length; i++) {
      List<String> ids = getPlayerIdsAfterRound(i);
      for (int j = 0; j < 4; j++) {
        teamPlayerIds[j % 2].add(ids[j]);
      }
    }
    return teamPlayerIds;
  }

  List<String> get currentPlayerIds {
    return getPlayerIdsAfterRound(rounds.length - 1);
  }

  List<int> get currentScore {
    return getScoreAfterRound(rounds.length - 1);
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

  bool get isFinished {
    int teamIndex = winningTeamIndex;
    if (teamIndex == null) {
      return false;
    }
    return currentScore[teamIndex] >= gameOverScore;
  }

  int get numRounds {
    return rounds.where((r) => !r.isPlayerSwitch).length;
  }

  List<String> get teamIds {
    List<String> teamIds = [null, null];
    Set<String> fullGamers = fullGamePlayerIds;
    for (int i = 0; i < 2; i++) {
      List<String> initialIds = [initialPlayerIds[i], initialPlayerIds[i + 2]];
      if (initialIds.toSet().intersection(fullGamers).length == 2) {
        teamIds[i] = Util.teamId(initialIds);
      }
    }
    return teamIds;
  }

  int get winningTeamIndex {
    List<int> score = currentScore;
    if (score[0] > score[1]) {
      return 0;
    } else if (score[1] > score[0]) {
      return 1;
    }
    return null;
  }

  static List<Game> gamesFromSnapshot(QuerySnapshot snapshot) {
    List<Game> games = [];
    for (DocumentSnapshot documentSnapshot in snapshot.docs) {
      // for some reason player data is being sent to this function
      if (documentSnapshot.data().containsKey('fullName')) {
        return [];
      }
      int variation = documentSnapshot.data()['variation'];
      if (variation == null || variation == 1) {
        games.add(Game.fromDocument(documentSnapshot));
      }
    }
    games.sort((a, b) => -a.timestamp.compareTo(b.timestamp));
    return games;
  }

  List<String> getPlayerIdsAfterRound(int roundIndex) {
    List<String> playerIds = initialPlayerIds.toList();
    for (int i = 0; i <= roundIndex; i++) {
      Round round = rounds[i];
      if (round.isPlayerSwitch) {
        playerIds[round.switchingPlayerIndex] = round.newPlayerId;
      }
    }
    return playerIds;
  }

  List<int> getScoreAfterRound(int roundIndex) {
    List<int> score = [0, 0];
    for (int i = 0; i <= roundIndex; i++) {
      if (!rounds[i].isPlayerSwitch) {
        List<int> roundScore = rounds[i].score;
        score[0] += roundScore[0];
        score[1] += roundScore[1];
      }
    }
    return score;
  }

  String getTeamName(int index, Data data, {bool fullNames = false}) {
    String player1Id = currentPlayerIds[index];
    String player2Id = currentPlayerIds[index + 2];
    List<Player> players = [
      data.allPlayers[player1Id],
      data.allPlayers[player2Id]
    ];
    players.sort((a, b) => a.fullName.compareTo(b.fullName));
    if (fullNames) {
      return '${players[0].fullName} & ${players[1].fullName}';
    } else {
      return '${players[0].shortName} & ${players[1].shortName}';
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
          rounds == other.rounds &&
          teamColors == other.teamColors &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      gameId.hashCode ^
      userId.hashCode ^
      gameOverScore.hashCode ^
      hashList(initialPlayerIds) ^
      hashList(rounds) ^
      hashList(teamColors) ^
      timestamp.hashCode;
}

class Round {
  static const List<int> ALL_BIDS = [3, 4, 5, 6, 12, 24];

  int roundIndex;
  bool isPlayerSwitch;

  int dealerIndex;
  int bidderIndex;
  int bid;
  int wonTricks;

  int switchingPlayerIndex;
  String newPlayerId;

  Round(this.roundIndex, this.dealerIndex, this.bidderIndex, this.bid,
      this.wonTricks) {
    isPlayerSwitch = false;
  }

  Round.empty(this.roundIndex, this.dealerIndex) {
    isPlayerSwitch = false;
  }

  Round.playerSwitch(this.roundIndex, this.switchingPlayerIndex, this.newPlayerId) {
    isPlayerSwitch = true;
  }

  Round.fromData(Map roundData) {
    roundIndex = roundData['roundIndex'];
    isPlayerSwitch = roundData['isPlayerSwitch'];
    if (isPlayerSwitch == null) {
      isPlayerSwitch = false;
    }
    if (isPlayerSwitch) {
      switchingPlayerIndex = roundData['switchingPlayerIndex'];
      newPlayerId = roundData['newPlayerId'];
    } else {
      dealerIndex =
      roundData['dealerIndex'] == -1 ? null : roundData['dealerIndex'];
      bidderIndex =
      roundData['bidderIndex'] == -1 ? null : roundData['bidderIndex'];
      bid = roundData['bid'] == -1 ? null : roundData['bid'];
      wonTricks = roundData['wonPoints'] == -1 ? null : roundData['wonPoints'];
      if (wonTricks == null) {
        wonTricks = roundData['bidderWonHands'];
      }
    }
  }

  Map get dataMap {
    Map roundData = {
      'roundIndex': roundIndex,
      'isPlayerSwitch': isPlayerSwitch,
    };
    if (isPlayerSwitch) {
      roundData['switchingPlayerIndex'] = switchingPlayerIndex;
      roundData['newPlayerId'] = newPlayerId;
    } else {
      roundData['dealerIndex'] = dealerIndex;
      roundData['bidderIndex'] = bidderIndex;
      roundData['bid'] = bid;
      roundData['wonPoints'] = wonTricks;
      roundData['partnerIndex'] = 0;
    }
    return roundData;
  }

  bool get isFinished {
    return dealerIndex != null &&
        bidderIndex != null &&
        bid != null &&
        wonTricks != null;
  }

  bool get madeBid {
    if (!isFinished) {
      return false;
    }
    if (bid == 24 || bid == 12) {
      return wonTricks == 6;
    }
    return wonTricks >= bid;
  }

  List<int> get score {
    if (isPlayerSwitch) {
      return null;
    }
    if (wonTricks == null) {
      return [0, 0];
    }
    List<int> score = [0, 0];
    int bidTeam = bidderIndex % 2;
    int oTeam = 1 - bidTeam;
    if (bid == 24 || bid == 12) {
      if (wonTricks == 6) {
        score[bidTeam] = bid;
      } else {
        score[bidTeam] = -bid;
        score[oTeam] = 6 - wonTricks;
      }
    } else {
      if (wonTricks >= bid) {
        score[bidTeam] = wonTricks;
        score[oTeam] = 6 - wonTricks;
      } else {
        score[bidTeam] = -bid;
        score[oTeam] = 6 - wonTricks;
      }
    }
    return score;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Round &&
          runtimeType == other.runtimeType &&
          roundIndex == other.roundIndex &&
          isPlayerSwitch == other.isPlayerSwitch &&
          dealerIndex == other.dealerIndex &&
          bidderIndex == other.bidderIndex &&
          bid == other.bid &&
          wonTricks == other.wonTricks &&
          switchingPlayerIndex == other.switchingPlayerIndex &&
          newPlayerId == other.newPlayerId;

  @override
  int get hashCode =>
      roundIndex.hashCode ^
      isPlayerSwitch.hashCode ^
      dealerIndex.hashCode ^
      bidderIndex.hashCode ^
      bid.hashCode ^
      wonTricks.hashCode ^
      switchingPlayerIndex.hashCode ^
      newPlayerId.hashCode;
}
