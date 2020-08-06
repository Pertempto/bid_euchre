import 'dart:math';

import 'package:intl/intl.dart' as intl;

import '../util.dart';
import 'game.dart';
import 'player.dart';

class StatsDb {
  List<Game> allGames;
  Map<String, Player> allPlayers;
  Map<String, Map<StatType, StatItem>> _playerStats;
  Map<String, Map<StatType, StatItem>> _teamStats;

  StatsDb.load(this.allGames, this.allPlayers) {
    _loadTeamStats();
    _loadPlayerStats();
  }

  _loadTeamStats() {
    Map<String, Map> massiveMap = {};
    for (Game g in allGames.where((g) => g.isFinished)) {
      List<Set<String>> teamsPlayerIds = g.allTeamsPlayerIds;
      List<String> teamIds = [null, null];
      for (int i = 0; i < 2; i++) {
        if (teamsPlayerIds[i].length == 2) {
          String teamId = Util.teamId(teamsPlayerIds[i].toList());

          teamIds[i] = teamId;
          massiveMap.putIfAbsent(
            teamId,
            () => {
              'scoreDiffs': [],
              'numGames': 0,
              'numRounds': 0,
              'numBids': 0,
              'madeBids': 0,
              'biddingTotal': 0,
              'pointsOnBids': 0,
              'numPoints': 0,
              'lastPlayed': 0,
              'noPartner': 0,
              'madeNoPartner': 0,
            },
          );
        }
      }
      if (teamIds[0] == null && teamIds[1] == null) {
        continue;
      }
      int winningTeamIndex = g.winningTeamIndex;
      List<int> score = g.currentScore;
      int scoreDiff = score[winningTeamIndex] - score[1 - winningTeamIndex];
      for (String teamId in teamIds.where((id) => id != null)) {
        massiveMap[teamId]['numGames']++;
        massiveMap[teamId]['lastPlayed'] = max(massiveMap[teamId]['lastPlayed'] as int, g.timestamp);
        if (teamIds[winningTeamIndex] == teamId) {
          massiveMap[teamId]['scoreDiffs'].add(scoreDiff);
        } else {
          massiveMap[teamId]['scoreDiffs'].add(-scoreDiff);
        }
      }
      for (Round round in g.rounds) {
        for (int i = 0; i < 2; i++) {
          String teamId = teamIds[i];
          if (teamId == null) {
            continue;
          }
          if (!round.isPlayerSwitch && round.isFinished) {
            massiveMap[teamId]['numRounds']++;
            massiveMap[teamId]['numPoints'] += round.score[i];
            if (round.bidderIndex % 2 == i) {
              massiveMap[teamId]['numBids']++;
              if (round.madeBid) {
                massiveMap[teamId]['madeBids']++;
              }
              massiveMap[teamId]['biddingTotal'] += round.bid;
              massiveMap[teamId]['pointsOnBids'] += round.score[round.bidderIndex % 2];
              if (round.bid > 6) {
                massiveMap[teamId]['noPartner']++;
                if (round.madeBid) {
                  massiveMap[teamId]['madeNoPartner']++;
                }
              }
            }
          }
        }
      }
    }

    _teamStats = {};
    for (String teamId in massiveMap.keys) {
      _teamStats[teamId] = {};
      int wins = massiveMap[teamId]['scoreDiffs'].where((d) => (d as int) > 0).length;
      int losses = massiveMap[teamId]['scoreDiffs'].where((d) => (d as int) < 0).length;
      int numGames = massiveMap[teamId]['numGames'];
      int numRounds = massiveMap[teamId]['numRounds'];
      int numBids = massiveMap[teamId]['numBids'];
      int numPoints = massiveMap[teamId]['numPoints'];
      for (StatType statType in StatType.values) {
        if (statType == StatType.record) {
          _teamStats[teamId][statType] = StatItem(teamId, statType, [wins, losses]);
        } else if (statType == StatType.winningPct) {
          double winningPct = 0;
          if ((wins + losses) != 0) {
            winningPct = wins / (wins + losses);
          }
          _teamStats[teamId][statType] = StatItem(teamId, statType, winningPct);
        } else if (statType == StatType.streak) {
          int streak = 0;
          for (int scoreDiff in massiveMap[teamId]['scoreDiffs']) {
            if (scoreDiff > 0) {
              if (streak >= 0) {
                streak++;
              } else {
                break;
              }
            } else {
              if (streak <= 0) {
                streak--;
              } else {
                break;
              }
            }
          }
          _teamStats[teamId][statType] = StatItem(teamId, statType, streak);
        } else if (statType == StatType.numGames) {
          _teamStats[teamId][statType] = StatItem(teamId, statType, numGames);
        } else if (statType == StatType.numRounds) {
          _teamStats[teamId][statType] = StatItem(teamId, statType, numRounds);
        } else if (statType == StatType.numBids) {
          _teamStats[teamId][statType] = StatItem(teamId, statType, numBids);
        } else if (statType == StatType.numPoints) {
          _teamStats[teamId][statType] = StatItem(teamId, statType, numPoints);
        } else if (statType == StatType.avgScoreDiff) {
          int totalScoreDiff = massiveMap[teamId]['scoreDiffs'].reduce((a, b) => a + b);
          double avgScoreDiff = 0;
          if (numGames != 0) {
            avgScoreDiff = totalScoreDiff / numGames;
          }
          _teamStats[teamId][statType] = StatItem(teamId, statType, avgScoreDiff);
        } else if (statType == StatType.biddingFrequency) {
          double biddingRate = 0;
          if (numRounds != 0) {
            biddingRate = numBids / numRounds;
          }
          _teamStats[teamId][statType] = StatItem(teamId, statType, biddingRate);
        } else if (statType == StatType.biddingRecord) {
          int made = massiveMap[teamId]['madeBids'];
          int set = numBids - made;
          _teamStats[teamId][statType] = StatItem(teamId, statType, [made, set]);
        } else if (statType == StatType.madeBidPercentage) {
          double mbp = 0;
          if (numBids != 0) {
            mbp = massiveMap[teamId]['madeBids'] / numBids;
          }
          _teamStats[teamId][statType] = StatItem(teamId, statType, mbp);
        } else if (statType == StatType.averageBid) {
          double avgBid = 0;
          if (numBids != 0) {
            avgBid = massiveMap[teamId]['biddingTotal'] / numBids;
          }
          _teamStats[teamId][statType] = StatItem(teamId, statType, avgBid);
        } else if (statType == StatType.pointsPerBid) {
          double ppb = 0;
          if (numBids != 0) {
            ppb = massiveMap[teamId]['pointsOnBids'] / numBids;
          }
          _teamStats[teamId][statType] = StatItem(teamId, statType, ppb);
        } else if (statType == StatType.lastPlayed) {
          _teamStats[teamId][statType] = StatItem(teamId, statType, massiveMap[teamId]['lastPlayed']);
        } else if (statType == StatType.noPartnerFrequency) {
          double rate = 0;
          if (numBids != 0) {
            rate = massiveMap[teamId]['noPartner'] / numBids;
          }
          _teamStats[teamId][statType] = StatItem(teamId, statType, rate);
        } else if (statType == StatType.noPartnerMadePercentage) {
          double mbp = 0;
          if (massiveMap[teamId]['noPartner'] != 0) {
            mbp = massiveMap[teamId]['madeNoPartner'] / massiveMap[teamId]['noPartner'];
          }
          _teamStats[teamId][statType] = StatItem(teamId, statType, mbp);
        } else if (statType == StatType.winsMinusLosses) {
          _teamStats[teamId][statType] = StatItem(teamId, statType, wins - losses);
        }
      }
    }
  }

  _loadPlayerStats() {
    Map<String, List<int>> scoreDiffsMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => []);
    Map<String, int> numGamesMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => 0);
    Map<String, int> numRoundsMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => 0);
    Map<String, int> numBidsMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => 0);
    Map<String, int> madeBidsMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => 0);
    Map<String, int> biddingTotalMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => 0);
    Map<String, int> totalPointsOnBidsMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => 0);
    Map<String, int> numPointsMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => 0);
    Map<String, int> lastPlayedMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => 0);
    Map<String, int> noPartnerMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => 0);
    Map<String, int> madeNoPartnerMap = Map.fromIterable(allPlayers.keys, key: (id) => id, value: (id) => 0);
    if (allPlayers.isNotEmpty) {
      for (Game g in allGames.reversed.where((g) => g.isFinished)) {
        int winningTeamIndex = g.winningTeamIndex;
        Set<String> fullGamePlayerIds = g.fullGamePlayerIds;
        List<int> score = g.currentScore;
        int scoreDiff = score[winningTeamIndex] - score[1 - winningTeamIndex];
        for (String playerId in g.allPlayerIds) {
          if (!numGamesMap.containsKey(playerId)) {
            print('unknown id: $playerId, game: ${g.gameId}');
            print(allPlayers.keys);
          }
          numGamesMap[playerId]++;
          lastPlayedMap[playerId] = max(lastPlayedMap[playerId], g.timestamp);
        }
        for (int i = 0; i < 4; i++) {
          String playerId = g.initialPlayerIds[i];
          if (fullGamePlayerIds.contains(playerId)) {
            if (i % 2 == winningTeamIndex) {
              scoreDiffsMap[playerId].add(scoreDiff);
            } else {
              scoreDiffsMap[playerId].add(-scoreDiff);
            }
          }
        }
        for (Round round in g.rounds) {
          List<String> rPlayerIds = g.getPlayerIdsAfterRound(round.roundIndex - 1);
          if (!round.isPlayerSwitch && round.isFinished) {
            for (int i = 0; i < 4; i++) {
              String playerId = rPlayerIds[i];
              numRoundsMap[playerId]++;
              numPointsMap[playerId] += round.score[i % 2];
            }
            String bidderId = rPlayerIds[round.bidderIndex];
            numBidsMap[bidderId]++;
            if (round.madeBid) {
              madeBidsMap[bidderId]++;
            }
            biddingTotalMap[bidderId] += round.bid;
            totalPointsOnBidsMap[bidderId] += round.score[round.bidderIndex % 2];
            if (round.bid > 6) {
              noPartnerMap[bidderId]++;
              if (round.madeBid) {
                madeNoPartnerMap[bidderId]++;
              }
            }
          }
        }
      }
    }

    _playerStats = {};
    for (String playerId in allPlayers.keys) {
      _playerStats[playerId] = {};
      int wins = scoreDiffsMap[playerId].where((d) => d > 0).length;
      int losses = scoreDiffsMap[playerId].where((d) => d < 0).length;
      int numGames = numGamesMap[playerId];
      int numRounds = numRoundsMap[playerId];
      int numBids = numBidsMap[playerId];
      int numPoints = numPointsMap[playerId];
      for (StatType statType in StatType.values) {
        if (statType == StatType.record) {
          _playerStats[playerId][statType] = StatItem(playerId, statType, [wins, losses]);
        } else if (statType == StatType.winningPct) {
          double winningPct = 0;
          if ((wins + losses) != 0) {
            winningPct = wins / (wins + losses);
          }
          _playerStats[playerId][statType] = StatItem(playerId, statType, winningPct);
        } else if (statType == StatType.streak) {
          int streak = 0;
          for (int scoreDiff in scoreDiffsMap[playerId].reversed) {
            if (scoreDiff > 0) {
              if (streak >= 0) {
                streak++;
              } else {
                break;
              }
            } else {
              if (streak <= 0) {
                streak--;
              } else {
                break;
              }
            }
          }
          _playerStats[playerId][statType] = StatItem(playerId, statType, streak);
        } else if (statType == StatType.numGames) {
          _playerStats[playerId][statType] = StatItem(playerId, statType, numGames);
        } else if (statType == StatType.numRounds) {
          _playerStats[playerId][statType] = StatItem(playerId, statType, numRounds);
        } else if (statType == StatType.numBids) {
          _playerStats[playerId][statType] = StatItem(playerId, statType, numBids);
        } else if (statType == StatType.numPoints) {
          _playerStats[playerId][statType] = StatItem(playerId, statType, numPoints);
        } else if (statType == StatType.avgScoreDiff) {
          int totalScoreDiff = 0;
          if (scoreDiffsMap[playerId].isNotEmpty) {
            totalScoreDiff = scoreDiffsMap[playerId].reduce((a, b) => a + b);
          }
          double avgScoreDiff = 0;
          if (numGames != 0) {
            avgScoreDiff = totalScoreDiff / numGames;
          }
          _playerStats[playerId][statType] = StatItem(playerId, statType, avgScoreDiff);
        } else if (statType == StatType.biddingFrequency) {
          double biddingRate = 0;
          if (numRounds != 0) {
            biddingRate = numBids / numRounds;
          }
          _playerStats[playerId][statType] = StatItem(playerId, statType, biddingRate);
        } else if (statType == StatType.biddingRecord) {
          int made = madeBidsMap[playerId];
          int set = numBids - made;
          _playerStats[playerId][statType] = StatItem(playerId, statType, [made, set]);
        } else if (statType == StatType.madeBidPercentage) {
          double mbp = 0;
          if (numBids != 0) {
            mbp = madeBidsMap[playerId] / numBids;
          }
          _playerStats[playerId][statType] = StatItem(playerId, statType, mbp);
        } else if (statType == StatType.averageBid) {
          double avgBid = 0;
          if (numBids != 0) {
            avgBid = biddingTotalMap[playerId] / numBids;
          }
          _playerStats[playerId][statType] = StatItem(playerId, statType, avgBid);
        } else if (statType == StatType.pointsPerBid) {
          double ppb = 0;
          if (numBids != 0) {
            ppb = totalPointsOnBidsMap[playerId] / numBids;
          }
          _playerStats[playerId][statType] = StatItem(playerId, statType, ppb);
        } else if (statType == StatType.lastPlayed) {
          _playerStats[playerId][statType] = StatItem(playerId, statType, lastPlayedMap[playerId]);
        } else if (statType == StatType.noPartnerFrequency) {
          double rate = 0;
          if (numBids != 0) {
            rate = noPartnerMap[playerId] / numBids;
          }
          _playerStats[playerId][statType] = StatItem(playerId, statType, rate);
        } else if (statType == StatType.noPartnerMadePercentage) {
          double mbp = 0;
          if (noPartnerMap[playerId] != 0) {
            mbp = madeNoPartnerMap[playerId] / noPartnerMap[playerId];
          }
          _playerStats[playerId][statType] = StatItem(playerId, statType, mbp);
        } else if (statType == StatType.winsMinusLosses) {
          _playerStats[playerId][statType] = StatItem(playerId, statType, wins - losses);
        }
      }
    }
  }

  StatItem getStat(String id, StatType statType) {
    Map<StatType, StatItem> stats;
    if (id.contains(' ')) {
      stats = _teamStats[id];
    } else {
      stats = _playerStats[id];
    }
    if (stats != null) {
      return stats[statType];
    }
    switch (statType) {
      case StatType.record:
      case StatType.biddingRecord:
        return StatItem(id, statType, [0, 0]);
      case StatType.winningPct:
      case StatType.avgScoreDiff:
      case StatType.biddingFrequency:
      case StatType.madeBidPercentage:
      case StatType.averageBid:
      case StatType.pointsPerBid:
      case StatType.noPartnerFrequency:
      case StatType.noPartnerMadePercentage:
        return StatItem(id, statType, 0.0);
      case StatType.streak:
      case StatType.numGames:
      case StatType.numRounds:
      case StatType.numBids:
      case StatType.numPoints:
      case StatType.lastPlayed:
      case StatType.winsMinusLosses:
        return StatItem(id, statType, 0);
    }
    return StatItem(id, statType, 0);
  }

  List<String> getTeamIds(Set<String> playerIds) {
    return _teamStats.keys.where((id) {
      List<String> ids = id.split(' ');
      return playerIds.intersection(ids.toSet()).length == 2;
    }).toList();
  }

  Map<int, BiddingSplit> getPlayerBiddingSplits(String playerId, {int numRecent = 0}) {
    Map<int, BiddingSplit> splits = {};
    for (int bid in Round.ALL_BIDS) {
      splits[bid] = BiddingSplit(bid, []);
    }
    int count = 0;
    for (Game g in allGames.where((g) => (g.isFinished && g.allPlayerIds.contains(playerId)))) {
      for (Round r in g.rounds.reversed.where((r) => !r.isPlayerSwitch)) {
        String bidderId = g.getPlayerIdsAfterRound(r.roundIndex - 1)[r.bidderIndex];
        if (bidderId == playerId) {
          splits[r.bid].rounds.add(r);
          count++;
          if (numRecent != 0 && count >= numRecent) {
            return splits;
          }
        }
      }
    }
    return splits;
  }

  Map<int, BiddingSplit> getTeamBiddingSplits(String teamId, {int numRecent = 0}) {
    Map<int, BiddingSplit> splits = {};
    for (int bid in Round.ALL_BIDS) {
      splits[bid] = BiddingSplit(bid, []);
    }
    int count = 0;
    for (Game g in allGames.where((g) => (g.isFinished && g.teamIds.contains(teamId)))) {
      int teamIndex = g.teamIds.indexOf(teamId);
      for (Round r in g.rounds.where((r) => !r.isPlayerSwitch)) {
        if (r.bidderIndex % 2 == teamIndex) {
          splits[r.bid].rounds.add(r);
          count++;
          if (numRecent != 0 && count >= numRecent) {
            return splits;
          }
        }
      }
    }
    return splits;
  }

  double getTeamRating(List<String> playerIds) {
    String teamId = Util.teamId(playerIds);
    double teamRating = 0;
    for (int i = 0; i < 2; i++) {
      teamRating += getStat(playerIds[i], StatType.winsMinusLosses).statValue;
    }
    teamRating += getStat(teamId, StatType.winsMinusLosses).statValue;
    return teamRating;
  }

  List<double> getWinChances(List<String> currentPlayerIds, List<int> score, int gameOverScore) {
    List<double> teamRatings = [];
    for (int i = 0; i < 2; i++) {
      teamRatings.add(getTeamRating([currentPlayerIds[i], currentPlayerIds[i + 2]]));
    }
    List<double> winChances = ratingsToWinChances(teamRatings);
    List<double> adjWinChances = [];
    for (int i = 0; i < 2; i++) {
      adjWinChances.add(winChances[i] * (1 / (pow(10, -(score[i] - score[1 - i]) * 2 / gameOverScore) + 1)));
    }
    double sum = adjWinChances[0] + adjWinChances[1];
    return [adjWinChances[0] / sum, adjWinChances[1] / sum];
  }

  static List<double> ratingsToWinChances(List<double> teamRatings) {
    double team1WinChance = 1 / (pow(10, ((teamRatings[1] - teamRatings[0]) / 40)) + 1);
    return [team1WinChance, 1 - team1WinChance];
  }

  static String statName(StatType statType) {
    switch (statType) {
      case StatType.record:
        return 'Win/Loss Record';
      case StatType.winningPct:
        return 'Winning Percentage';
      case StatType.streak:
        return 'Streak';
      case StatType.numGames:
        return 'Number of Games';
      case StatType.numRounds:
        return 'Number of Rounds';
      case StatType.numBids:
        return 'Number of Bids';
      case StatType.numPoints:
        return 'Number of Points';
      case StatType.avgScoreDiff:
        return 'Average Score Difference';
      case StatType.biddingFrequency:
        return 'Bidding Frequency';
      case StatType.biddingRecord:
        return 'Bidding Record';
      case StatType.madeBidPercentage:
        return 'Made Bid Percentage';
      case StatType.averageBid:
        return 'Average Bid';
      case StatType.pointsPerBid:
        return 'Points Per Bid';
      case StatType.lastPlayed:
        return 'Last Played';
      case StatType.noPartnerFrequency:
        return 'Slide/Loner Frequency';
      case StatType.noPartnerMadePercentage:
        return 'Slider/Loner Made %';
      case StatType.winsMinusLosses:
        return 'Wins Minus Losses';
    }
    return '';
  }
}

class StatItem {
  String entityId;
  StatType statType;
  dynamic statValue;

  StatItem(this.entityId, this.statType, this.statValue);

  double get sortValue {
    switch (statType) {
      case StatType.record:
      case StatType.biddingRecord:
        List<int> record = statValue.cast<int>();
        int total = record[0] + record[1];
        if (total == 0) {
          return 1;
        }
        return -(record[0] / total);
      case StatType.winningPct:
      case StatType.avgScoreDiff:
      case StatType.biddingFrequency:
      case StatType.madeBidPercentage:
      case StatType.averageBid:
      case StatType.pointsPerBid:
      case StatType.noPartnerFrequency:
      case StatType.noPartnerMadePercentage:
        return -statValue;
      case StatType.streak:
      case StatType.numGames:
      case StatType.numRounds:
      case StatType.numBids:
      case StatType.numPoints:
      case StatType.lastPlayed:
      case StatType.winsMinusLosses:
        return -statValue.toDouble();
    }
    return 0;
  }

  @override
  String toString() {
    switch (statType) {
      case StatType.record:
      case StatType.biddingRecord:
        List<int> record = statValue.cast<int>();
        return '${record[0]}-${record[1]}';
      case StatType.winningPct:
      case StatType.madeBidPercentage:
      case StatType.noPartnerMadePercentage:
        return ((statValue as double) * 100).toStringAsFixed(1) + '%';
      case StatType.streak:
        if (statValue > 0) {
          return '${statValue}W';
        } else if (statValue < 0) {
          return '${-statValue}L';
        }
        return '-';
      case StatType.numGames:
      case StatType.numRounds:
      case StatType.numBids:
      case StatType.numPoints:
        return '$statValue';
      case StatType.avgScoreDiff:
      case StatType.averageBid:
      case StatType.pointsPerBid:
        return (statValue as double).toStringAsFixed(2);
      case StatType.biddingFrequency:
      case StatType.noPartnerFrequency:
        double biddingRate = statValue as double;
        if (biddingRate == 0) {
          return '-';
        }
        String inverseRateString = (1 / biddingRate).toStringAsFixed(1);
        return '1 in $inverseRateString';
      case StatType.lastPlayed:
        if (statValue == 0) {
          return '-';
        }
        DateTime date = DateTime.fromMillisecondsSinceEpoch(statValue);
        return intl.DateFormat.yMd().add_jm().format(date);
      case StatType.winsMinusLosses:
        String s = statValue.toString();
        if (statValue > 0) {
          s = '+' + s;
        }
        return s;
    }
    return '';
  }
}

enum StatType {
  record,
  winningPct,
  streak,
  numGames,
  numRounds,
  numBids,
  numPoints,
  avgScoreDiff,
  biddingFrequency,
  biddingRecord,
  madeBidPercentage,
  averageBid,
  pointsPerBid,
  lastPlayed,
  noPartnerFrequency,
  noPartnerMadePercentage,
  winsMinusLosses,
}

class BiddingSplit {
  int bid;
  List<Round> rounds;

  BiddingSplit(this.bid, this.rounds);

  double get avgPoints {
    if (count == 0) {
      return double.nan;
    }
    return rounds.map((r) => r.score[r.bidderIndex % 2]).reduce((a, b) => a + b) / count;
  }

  double get avgTricks {
    if (count == 0) {
      return double.nan;
    }
    return rounds.map((r) => r.wonTricks).reduce((a, b) => a + b) / count;
  }

  int get count {
    return rounds.length;
  }

  int get made {
    return rounds.where((r) => r.madeBid).length;
  }

  double get madePct {
    if (count == 0) {
      return double.nan;
    }
    return made / count;
  }
}
