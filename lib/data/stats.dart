import 'dart:math';

import 'package:intl/intl.dart' as intl;

import '../util.dart';
import 'game.dart';
import 'player.dart';

class StatsDb {
  static const int MIN_GAMES = 5;
  List<Game> allGames;
  Map<String, Player> allPlayers;
  Map<String, Map<StatType, StatItem>> _playerStats;
  Map<String, Map<StatType, StatItem>> _teamStats;
  Map<String, List<String>> _gamesMap;
  Map<String, Map<String, double>> _ratingsHistory;

  StatsDb.load(this.allGames, this.allPlayers) {
    _loadStats();
  }

  _loadStats() {
    Map<String, Map> massiveMap = {};
    _gamesMap = {};
    _ratingsHistory = {};
    // only finished games for now
    for (Game g in allGames.reversed.where((g) => g.isFinished)) {
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
              'numOBids': 0,
              'setOpponents': 0,
            },
          );
          _gamesMap.putIfAbsent(teamId, () => []);
          _gamesMap[teamId].add(g.gameId);
        }
      }
      for (String playerId in g.allPlayerIds) {
        massiveMap.putIfAbsent(
          playerId,
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
            'numOBids': 0,
            'setOpponents': 0,
          },
        );
        _gamesMap.putIfAbsent(playerId, () => []);
        _gamesMap[playerId].add(g.gameId);
      }
      int winningTeamIndex = g.winningTeamIndex;
      List<int> score = g.currentScore;
      int scoreDiff = score[winningTeamIndex] - score[1 - winningTeamIndex];
      for (String teamId in teamIds.where((id) => id != null)) {
        if (g.isFinished) {
          massiveMap[teamId]['numGames']++;
          if (teamIds[winningTeamIndex] == teamId) {
            massiveMap[teamId]['scoreDiffs'].add(scoreDiff);
          } else {
            massiveMap[teamId]['scoreDiffs'].add(-scoreDiff);
          }
        }
        massiveMap[teamId]['lastPlayed'] = max(massiveMap[teamId]['lastPlayed'] as int, g.timestamp);
      }
      for (String playerId in g.allPlayerIds) {
        if (g.isFinished) {
          massiveMap[playerId]['numGames']++;
          if (g.fullGamePlayerIds.contains(playerId)) {
            if (g.allTeamsPlayerIds[winningTeamIndex].contains(playerId)) {
              massiveMap[playerId]['scoreDiffs'].add(scoreDiff);
            } else {
              massiveMap[playerId]['scoreDiffs'].add(-scoreDiff);
            }
          }
        }
        massiveMap[playerId]['lastPlayed'] = max(massiveMap[playerId]['lastPlayed'] as int, g.timestamp);
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
            } else {
              massiveMap[teamId]['numOBids']++;
              if (!round.madeBid) {
                massiveMap[teamId]['setOpponents']++;
              }
            }
          }
        }
        List<String> rPlayerIds = g.getPlayerIdsAfterRound(round.roundIndex - 1);
        if (!round.isPlayerSwitch && round.isFinished) {
          for (int i = 0; i < 4; i++) {
            String playerId = rPlayerIds[i];
            massiveMap[playerId]['numRounds']++;
            massiveMap[playerId]['numPoints'] += round.score[i % 2];
          }
          String bidderId = rPlayerIds[round.bidderIndex];
          massiveMap[bidderId]['numBids']++;
          massiveMap[rPlayerIds[(round.bidderIndex + 1) % 4]]['numOBids']++;
          massiveMap[rPlayerIds[(round.bidderIndex + 3) % 4]]['numOBids']++;
          if (round.madeBid) {
            massiveMap[bidderId]['madeBids']++;
          } else {
            massiveMap[rPlayerIds[(round.bidderIndex + 1) % 4]]['setOpponents']++;
            massiveMap[rPlayerIds[(round.bidderIndex + 3) % 4]]['setOpponents']++;
          }
          massiveMap[bidderId]['biddingTotal'] += round.bid;
          massiveMap[bidderId]['pointsOnBids'] += round.score[round.bidderIndex % 2];
          if (round.bid > 6) {
            massiveMap[bidderId]['noPartner']++;
            if (round.madeBid) {
              massiveMap[bidderId]['madeNoPartner']++;
            }
          }
        }
      }
      for (String teamId in teamIds.where((id) => id != null)) {
        _ratingsHistory.putIfAbsent(teamId, () => {});
        _ratingsHistory[teamId][g.gameId] = calculateOverallRating(teamId, massiveMap);
      }
      for (String playerId in g.allPlayerIds) {
        _ratingsHistory.putIfAbsent(playerId, () => {});
        _ratingsHistory[playerId][g.gameId] = calculateOverallRating(playerId, massiveMap);
      }
    }

    _teamStats = {};
    _playerStats = {};
    for (String id in massiveMap.keys) {
      int wins = massiveMap[id]['scoreDiffs'].where((d) => (d as int) > 0).length;
      int losses = massiveMap[id]['scoreDiffs'].where((d) => (d as int) < 0).length;
      int numGames = massiveMap[id]['numGames'];
      int numRounds = massiveMap[id]['numRounds'];
      int numBids = massiveMap[id]['numBids'];
      int numPoints = massiveMap[id]['numPoints'];
      for (StatType statType in StatType.values) {
        StatItem statItem;
        if (statType == StatType.record) {
          statItem = StatItem(id, statType, [wins, losses]);
        } else if (statType == StatType.winningPct) {
          double winningPct = 0;
          if ((wins + losses) != 0) {
            winningPct = wins / (wins + losses);
          }
          statItem = StatItem(id, statType, winningPct);
        } else if (statType == StatType.streak) {
          int streak = 0;
          for (int scoreDiff in massiveMap[id]['scoreDiffs'].reversed) {
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
          statItem = StatItem(id, statType, streak);
        } else if (statType == StatType.numGames) {
          statItem = StatItem(id, statType, numGames);
        } else if (statType == StatType.numRounds) {
          statItem = StatItem(id, statType, numRounds);
        } else if (statType == StatType.numBids) {
          statItem = StatItem(id, statType, numBids);
        } else if (statType == StatType.numPoints) {
          statItem = StatItem(id, statType, numPoints);
        } else if (statType == StatType.biddingFrequency) {
          double biddingRate = 0;
          if (numRounds != 0) {
            biddingRate = numBids / numRounds;
          }
          statItem = StatItem(id, statType, biddingRate);
        } else if (statType == StatType.biddingRecord) {
          int made = massiveMap[id]['madeBids'];
          int set = numBids - made;
          statItem = StatItem(id, statType, [made, set]);
        } else if (statType == StatType.madeBidPercentage) {
          double mbp = 0;
          if (numBids != 0) {
            mbp = massiveMap[id]['madeBids'] / numBids;
          }
          statItem = StatItem(id, statType, mbp);
        } else if (statType == StatType.averageBid) {
          double avgBid = 0;
          if (numBids != 0) {
            avgBid = massiveMap[id]['biddingTotal'] / numBids;
          }
          statItem = StatItem(id, statType, avgBid);
        } else if (statType == StatType.pointsPerBid) {
          double ppb = 0;
          if (numBids != 0) {
            ppb = massiveMap[id]['pointsOnBids'] / numBids;
          }
          statItem = StatItem(id, statType, ppb);
        } else if (statType == StatType.lastPlayed) {
          statItem = StatItem(id, statType, massiveMap[id]['lastPlayed']);
        } else if (statType == StatType.noPartnerFrequency) {
          double rate = 0;
          if (numBids != 0) {
            rate = massiveMap[id]['noPartner'] / numBids;
          }
          statItem = StatItem(id, statType, rate);
        } else if (statType == StatType.noPartnerMadePercentage) {
          double mbp = 0;
          if (massiveMap[id]['noPartner'] != 0) {
            mbp = massiveMap[id]['madeNoPartner'] / massiveMap[id]['noPartner'];
          }
          statItem = StatItem(id, statType, mbp);
        } else if (statType == StatType.winsMinusLosses) {
          statItem = StatItem(id, statType, wins - losses);
        } else if (statType == StatType.wins) {
          statItem = StatItem(id, statType, wins);
        } else if (statType == StatType.losses) {
          statItem = StatItem(id, statType, wins);
        } else if (statType == StatType.bidderRating) {
          double biddingPointsPerRound = 0;
          if (numBids != 0) {
            double ppb = massiveMap[id]['pointsOnBids'] / numBids;
            biddingPointsPerRound = ppb * numBids / numRounds;
          }
          double rating;
          if (id.contains(' ')) {
            rating = biddingPointsPerRound / 3.0 * 100;
          } else {
            rating = biddingPointsPerRound / 1.5 * 100;
          }
          statItem = StatItem(id, statType, rating);
        } else if (statType == StatType.settingPct) {
          int numOBids = massiveMap[id]['numOBids'];
          double sp = 0;
          if (numOBids != 0) {
            sp = massiveMap[id]['setOpponents'] / numOBids;
          }
          statItem = StatItem(id, statType, sp);
        } else if (statType == StatType.overallRating) {
          double overall = calculateOverallRating(id, massiveMap);
          statItem = StatItem(id, statType, overall);
        }
        if (id.contains(' ')) {
          _teamStats.putIfAbsent(id, () => {});
          _teamStats[id][statType] = statItem;
        } else {
          _playerStats.putIfAbsent(id, () => {});
          _playerStats[id][statType] = statItem;
        }
      }
    }
  }

  double calculateOverallRating(String id, Map<String, Map> massiveMap) {
    int numBids = massiveMap[id]['numBids'];
    int numRounds = massiveMap[id]['numRounds'];
    double bidderRating = 50;
    if (numRounds != 0) {
      double biddingPointsPerRound = 0;
      if (numBids != 0) {
        double ppb = massiveMap[id]['pointsOnBids'] / numBids;
        biddingPointsPerRound = ppb * numBids / numRounds;
      }
      if (id.contains(' ')) {
        bidderRating = biddingPointsPerRound / 3.0 * 100;
      } else {
        bidderRating = biddingPointsPerRound / 1.5 * 100;
      }
    }

    int wins = massiveMap[id]['scoreDiffs'].where((d) => (d as int) > 0).length;
    int losses = massiveMap[id]['scoreDiffs'].where((d) => (d as int) < 0).length;
    double winningRating = 50;
    if (wins + losses != 0) {
      winningRating = wins / (wins + losses) * 100;
    }

    int numSets = massiveMap[id]['setOpponents'];
    int numOBids = massiveMap[id]['numOBids'];
    double settingRating = 50;
    if (numOBids != 0) {
      settingRating = (numSets / numOBids) / 0.25 * 100;
    }
//          print('$bidderRating, $winningRating, $settingRating');
    return bidderRating * 0.6 + winningRating * 0.35 + settingRating * 0.05;
  }

  List<Game> getGames(String id) {
    if (_gamesMap[id] == null) {
      return [];
    }
    return allGames.where((g) => _gamesMap[id].contains(g.gameId)).toList();
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

  double getRatingAfterGame(String id, String gameId) {
    return _ratingsHistory[id][gameId];
  }

  double getRatingBeforeGame(String id, String gameId) {
    if (!_gamesMap[id].contains(gameId)) {
      if (id.contains(' ')) {
        return _teamStats[id][StatType.overallRating].statValue;
      } else {
        return _playerStats[id][StatType.overallRating].statValue;
      }
    }
    int index = _gamesMap[id].indexOf(gameId) - 1;
    if (index < 0) {
      return 50;
    }
    String lastGameId = _gamesMap[id][index];
    return _ratingsHistory[id][lastGameId];
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
      case StatType.biddingFrequency:
      case StatType.madeBidPercentage:
      case StatType.averageBid:
      case StatType.pointsPerBid:
      case StatType.noPartnerFrequency:
      case StatType.noPartnerMadePercentage:
      case StatType.bidderRating:
      case StatType.settingPct:
      case StatType.overallRating:
        return StatItem(id, statType, 0.0);
      case StatType.streak:
      case StatType.numGames:
      case StatType.numRounds:
      case StatType.numBids:
      case StatType.numPoints:
      case StatType.lastPlayed:
      case StatType.winsMinusLosses:
      case StatType.wins:
      case StatType.losses:
        return StatItem(id, statType, 0);
    }
    return StatItem(id, statType, 0);
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

  List<String> getTeamIds(Set<String> playerIds) {
    return _teamStats.keys.where((id) {
      List<String> ids = id.split(' ');
      return playerIds.intersection(ids.toSet()).length == 2;
    }).toList();
  }

  List<double> getWinChances(List<String> currentPlayerIds, List<int> score, int gameOverScore, {String beforeGameId}) {
    List<double> teamRatings = [];
    for (int i = 0; i < 2; i++) {
      String teamId = Util.teamId([currentPlayerIds[i], currentPlayerIds[i + 2]]);
      double teamRating;
      if (_teamStats[teamId] == null || _teamStats[teamId][StatType.numGames].statValue < MIN_GAMES) {
        teamRating = 0;
        for (int j = 0; j < 2; j++) {
          String playerId = currentPlayerIds[i + j * 2];
          if (_playerStats[playerId] == null || _playerStats[playerId][StatType.numGames].statValue == 0) {
            teamRating += 50;
          } else {
            if (beforeGameId != null) {
              teamRating += getRatingBeforeGame(playerId, beforeGameId) / 2;
            } else {
              teamRating += _playerStats[playerId][StatType.overallRating].statValue / 2;
            }
          }
        }
      } else {
        if (beforeGameId != null) {
          teamRating = getRatingBeforeGame(teamId, beforeGameId);
        } else {
          teamRating = _teamStats[teamId][StatType.overallRating].statValue;
        }
      }
      teamRatings.add(teamRating);
    }
//    print(teamRatings);
    List<double> winChances = ratingsToWinChances(teamRatings);
    List<double> adjWinChances = [];
    for (int i = 0; i < 2; i++) {
      double chance = winChances[i];
      // used desmos regression to find these coeffiecients
      chance *= (1 / (pow(10, -(score[i] - score[1 - i]) / gameOverScore * 1.943) + 1));
      double sPct = max(score[i] / gameOverScore, 0);
      // used desmos regression to find these coeffiecients
      chance *= 0.716 * pow(sPct, 3) - 0.771 * pow(sPct, 2) + 0.565 * sPct + 0.3321;
      adjWinChances.add(chance);
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
      case StatType.wins:
        return 'Wins';
      case StatType.losses:
        return 'Losses';
      case StatType.bidderRating:
        return 'Bidder Rating';
      case StatType.settingPct:
        return 'Setting Percentage';
      case StatType.overallRating:
        return 'Overall Rating';
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
      case StatType.biddingFrequency:
      case StatType.madeBidPercentage:
      case StatType.averageBid:
      case StatType.pointsPerBid:
      case StatType.noPartnerFrequency:
      case StatType.noPartnerMadePercentage:
      case StatType.bidderRating:
      case StatType.settingPct:
      case StatType.overallRating:
        return -statValue;
      case StatType.streak:
      case StatType.numGames:
      case StatType.numRounds:
      case StatType.numBids:
      case StatType.numPoints:
      case StatType.lastPlayed:
      case StatType.winsMinusLosses:
      case StatType.wins:
      case StatType.losses:
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
      case StatType.settingPct:
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
      case StatType.wins:
      case StatType.losses:
        return '$statValue';
      case StatType.averageBid:
      case StatType.pointsPerBid:
        return (statValue as double).toStringAsFixed(2);
      case StatType.bidderRating:
      case StatType.overallRating:
        return (statValue as double).toStringAsFixed(1);
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
  biddingFrequency,
  biddingRecord,
  madeBidPercentage,
  averageBid,
  pointsPerBid,
  lastPlayed,
  noPartnerFrequency,
  noPartnerMadePercentage,
  winsMinusLosses,
  wins,
  losses,
  bidderRating,
  settingPct,
  overallRating,
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
