import 'dart:math';

import 'package:bideuchre/widgets/color_chooser.dart';
import 'package:flutter/material.dart';

import '../util.dart';
import 'game.dart';
import 'player.dart';
import 'stat_item.dart';
import 'stat_type.dart';

class StatsDb {
  static const int MIN_GAMES = 5;
  static const double DEFAULT_RATING = 50;
  List<Game> allGames;
  Map<String, Player> allPlayers;
  Map<String, List<Map>> _entitiesGamesStats;
  Map<String, List<String>> _entitiesGameIdsHistories;

  StatsDb.load(this.allGames, this.allPlayers) {
    _loadStats();
  }

  _loadStats() {
    _entitiesGameIdsHistories = {};
    _entitiesGamesStats = {};

    Set<String> allEntityIds = {};

    // only finished games for now
    for (Game g in allGames.reversed.where((g) => g.isFinished)) {
      List<Set<String>> teamsPlayerIds = g.allTeamsPlayerIds;
      List<String> teamIds = [null, null];
      Map<String, Map> gameStatsMap = {};
      for (int i = 0; i < 2; i++) {
        if (teamsPlayerIds[i].length == 2) {
          String teamId = Util.teamId(teamsPlayerIds[i].toList());
          teamIds[i] = teamId;
        }
      }
      Set<String> ids = g.allPlayerIds.toSet();
      ids.addAll(teamIds.where((id) => id != null));
      allEntityIds.addAll(ids);
      for (String id in ids) {
        gameStatsMap.putIfAbsent(
          id,
          () => {
            'numRounds': 0,
            'numBids': 0,
            'pointsOnBids': 0,
            'numGames': 0,
            'madeBids': 0,
            'biddingTotal': 0,
            'numPoints': 0,
            'lastPlayed': 0,
            'noPartner': 0,
            'madeNoPartner': 0,
            'setOpponents': 0,
            'scoreDiff': 0,
          },
        );
      }
      int winningTeamIndex = g.winningTeamIndex;
      List<int> score = g.currentScore;
      int scoreDiff = score[winningTeamIndex] - score[1 - winningTeamIndex];
      List<double> adjustedTeamRatings = [];
      for (int i = 0; i < 2; i++) {
        double teamRating = getRatingBeforeGame(teamIds[i], g.gameId) / 2;
        teamRating += getRatingBeforeGame(g.initialPlayerIds[i], g.gameId) / 4;
        teamRating += getRatingBeforeGame(g.initialPlayerIds[i + 2], g.gameId) / 4;
        adjustedTeamRatings.add(teamRating);
      }
      for (String teamId in teamIds.where((id) => id != null)) {
        if (g.isFinished) {
          gameStatsMap[teamId]['numGames']++;
          if (teamIds[winningTeamIndex] == teamId) {
            gameStatsMap[teamId]['scoreDiff'] = scoreDiff;
          } else {
            gameStatsMap[teamId]['scoreDiff'] = -scoreDiff;
          }
        }
        gameStatsMap[teamId]['lastPlayed'] = max(gameStatsMap[teamId]['lastPlayed'] as int, g.timestamp);
      }
      for (String playerId in g.allPlayerIds) {
        if (g.isFinished) {
          gameStatsMap[playerId]['numGames']++;
          if (g.fullGamePlayerIds.contains(playerId)) {
            if (g.allTeamsPlayerIds[winningTeamIndex].contains(playerId)) {
              gameStatsMap[playerId]['scoreDiff'] = scoreDiff;
            } else {
              gameStatsMap[playerId]['scoreDiff'] = -scoreDiff;
            }
          }
        }
        gameStatsMap[playerId]['lastPlayed'] = max(gameStatsMap[playerId]['lastPlayed'] as int, g.timestamp);
      }
      for (Round round in g.rounds) {
        for (int i = 0; i < 2; i++) {
          String teamId = teamIds[i];
          if (teamId == null) {
            continue;
          }
          if (!round.isPlayerSwitch && round.isFinished) {
            gameStatsMap[teamId]['numRounds']++;
            gameStatsMap[teamId]['numPoints'] += round.score[i];
            if (round.bidderIndex % 2 == i) {
              gameStatsMap[teamId]['numBids']++;
              if (round.madeBid) {
                gameStatsMap[teamId]['madeBids']++;
              }
              gameStatsMap[teamId]['biddingTotal'] += round.bid;
              gameStatsMap[teamId]['pointsOnBids'] += round.score[round.bidderIndex % 2];
              if (round.bid > 6) {
                gameStatsMap[teamId]['noPartner']++;
                if (round.madeBid) {
                  gameStatsMap[teamId]['madeNoPartner']++;
                }
              }
            } else {
              if (!round.madeBid) {
                gameStatsMap[teamId]['setOpponents']++;
              }
            }
          }
        }
        List<String> rPlayerIds = g.getPlayerIdsAfterRound(round.roundIndex - 1);
        if (!round.isPlayerSwitch && round.isFinished) {
          for (int i = 0; i < 4; i++) {
            String playerId = rPlayerIds[i];
            gameStatsMap[playerId]['numRounds']++;
            gameStatsMap[playerId]['numPoints'] += round.score[i % 2];
          }
          String bidderId = rPlayerIds[round.bidderIndex];
          gameStatsMap[bidderId]['numBids']++;
          if (round.madeBid) {
            gameStatsMap[bidderId]['madeBids']++;
          } else {
            gameStatsMap[rPlayerIds[(round.bidderIndex + 1) % 4]]['setOpponents']++;
            gameStatsMap[rPlayerIds[(round.bidderIndex + 3) % 4]]['setOpponents']++;
          }
          gameStatsMap[bidderId]['biddingTotal'] += round.bid;
          gameStatsMap[bidderId]['pointsOnBids'] += round.score[round.bidderIndex % 2];
          if (round.bid > 6) {
            gameStatsMap[bidderId]['noPartner']++;
            if (round.madeBid) {
              gameStatsMap[bidderId]['madeNoPartner']++;
            }
          }
        }
      }
      for (String id in ids) {
        _entitiesGameIdsHistories.putIfAbsent(id, () => []);
        _entitiesGameIdsHistories[id].add(g.gameId);
        _entitiesGamesStats.putIfAbsent(id, () => []);
        _entitiesGamesStats[id].add(gameStatsMap[id]);
      }
    }
  }

  List<double> calculateWinChances(List<String> currentPlayerIds, List<int> score, int gameOverScore,
      {String beforeGameId}) {
    List<double> teamRatings = [];
    for (int i = 0; i < 2; i++) {
      String teamId = Util.teamId([currentPlayerIds[i], currentPlayerIds[i + 2]]);
      double teamRating = 0;
      if (beforeGameId != null) {
        teamRating += getRatingBeforeGame(teamId, beforeGameId);
      } else {
        teamRating += (getStat(teamId, StatType.overallRating) as RatingStatItem).rating;
      }
      double totalPlayerRating = 0;
      for (int j = 0; j < 2; j++) {
        String playerId = currentPlayerIds[i + j * 2];
        if (beforeGameId != null) {
          totalPlayerRating += getRatingBeforeGame(playerId, beforeGameId);
        } else {
          totalPlayerRating += (getStat(playerId, StatType.overallRating) as RatingStatItem).rating;
        }
      }
      totalPlayerRating /= 2;
      teamRating *= 0.5;
      teamRating += 0.5 * totalPlayerRating;
      teamRatings.add(teamRating);
    }
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

  double getBidderRatingAfterGame(String id, String gameId) {
    int endIndex = _entitiesGameIdsHistories[id].indexOf(gameId) + 1;
    int startIndex = max(0, endIndex - RecentRecordStatItem.NUM_RECENT_GAMES);
    return BidderRatingStatItem.calculateBidderRating(
        _entitiesGamesStats[id].sublist(startIndex, endIndex), id.contains(' '));
  }

  Color getEntityColor(String id) {
    if (_entitiesGameIdsHistories[id] == null || _entitiesGameIdsHistories[id].isEmpty) {
      // return random color for new team
      return ColorChooser.generateRandomColor(seed: id.hashCode);
    }
    if (id.contains(' ')) {
      Game lastGame = allGames.firstWhere((g) => g.gameId == _entitiesGameIdsHistories[id].last);
      List<String> teamIds = lastGame.teamIds;
      if (teamIds.contains(id)) {
        return Util.checkColor(lastGame.teamColors[teamIds.indexOf(id)], id);
      }
    } else {
      Map<String, Color> teamColors = {};
      Map<String, int> numGames = {};
      List<Game> games = getEntityGames(id);
      for (Game game in games) {
        for (int i = 0; i < 2; i++) {
          if (game.allTeamsPlayerIds[i].contains(id)) {
            String teamId = game.teamIds[i];
            if (teamId != null) {
              if (teamColors[teamId] == null) {
                numGames[teamId] = 0;
                teamColors[teamId] = game.teamColors[i];
              }
              numGames[teamId]++;
            }
          }
        }
      }
      if (numGames.isEmpty) {
        // the player has been in games, but only played partial parts
        Game game = games[0];
        for (int i = 0; i < 2; i++) {
          if (game.allTeamsPlayerIds[i].contains(id)) {
            return Util.checkColor(game.teamColors[i], id);
          }
        }
      } else {
//        print('$teamColors, $numGames');
        int maxGames = numGames.values.reduce(max);
        for (String teamId in numGames.keys) {
          if (numGames[teamId] == maxGames) {
            return Util.checkColor(teamColors[teamId], teamId);
          }
        }
      }
    }
    return Colors.black;
  }

  List<Game> getEntityGames(String id, {String beforeGameId}) {
    if (_entitiesGameIdsHistories[id] == null) {
      return [];
    }
    List<Game> games = allGames.where((g) => _entitiesGameIdsHistories[id].contains(g.gameId)).toList();
    if (beforeGameId == null) {
      return games;
    } else {
      bool haveFoundStart = false;
      List<Game> beforeGames = [];
      for (Game game in games) {
        if (haveFoundStart) {
          beforeGames.add(game);
        } else {
          if (game.gameId == beforeGameId) {
            haveFoundStart = true;
          }
        }
      }
      return beforeGames;
    }
  }

  Map<int, BiddingSplit> getPlayerBiddingSplits(String playerId, {int numRecent = 0}) {
    Map<int, BiddingSplit> splits = {};
    for (int bid in Round.ALL_BIDS) {
      splits[bid] = BiddingSplit(bid, []);
    }
    int count = 0;
    for (Game g in allGames.where((g) => (g.isFinished && g.allPlayerIds.contains(playerId)))) {
      for (Round r in g.rounds.reversed.where((r) => !r.isPlayerSwitch && r.isFinished)) {
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
    int endIndex = _entitiesGameIdsHistories[id].indexOf(gameId) + 1;
    int startIndex = max(0, endIndex - RecentRecordStatItem.NUM_RECENT_GAMES);
    return OverallRatingStatItem.calculateOverallRating(
        _entitiesGamesStats[id].sublist(startIndex, endIndex), id.contains(' '));
  }

  double getRatingBeforeGame(String id, String gameId) {
    if (!_entitiesGameIdsHistories.containsKey(id)) {
      return DEFAULT_RATING;
    }
    int endIndex = _entitiesGameIdsHistories[id].indexOf(gameId);
    if (endIndex <= 0) {
      return DEFAULT_RATING;
    }
    int startIndex = max(0, endIndex - RecentRecordStatItem.NUM_RECENT_GAMES);
    return OverallRatingStatItem.calculateOverallRating(
        _entitiesGamesStats[id].sublist(startIndex, endIndex), id.contains(' '));
  }

  StatItem getStat(String entityId, StatType statType, {bool recentGamesOnly = false}) {
    if (!_entitiesGamesStats.containsKey(entityId)) {
      return StatItem.empty(entityId, statType);
    }
    List<Map> gamesStats = _entitiesGamesStats[entityId];
    if (recentGamesOnly) {
      gamesStats = RecentRecordStatItem.getRecentGamesStats(gamesStats);
    }
    return StatItem.fromGamesStats(entityId, statType, gamesStats);
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
    return _entitiesGamesStats.keys.where((id) {
      List<String> ids = id.split(' ');
      return playerIds.intersection(ids.toSet()).length == 2;
    }).toList();
  }

  static List<double> ratingsToWinChances(List<double> teamRatings) {
    double team1WinChance = 1 / (pow(10, ((teamRatings[1] - teamRatings[0]) / 40)) + 1);
    return [team1WinChance, 1 - team1WinChance];
  }
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
