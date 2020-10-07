import 'dart:math';

import 'package:bideuchre/widgets/color_chooser.dart';
import 'package:flutter/material.dart';

import '../util.dart';
import 'bidding_split.dart';
import 'game.dart';
import 'player.dart';
import 'round.dart';
import 'stat_item.dart';
import 'stat_type.dart';

class StatsDb {
  static const int MIN_GAMES = 3;
  List<Game> allGames;
  Map<String, Player> allPlayers;
  Map<String, List<Map>> _entitiesGamesStats;
  Map<String, List<String>> _entitiesGameIdsHistories;

  StatsDb.load(this.allGames, this.allPlayers) {
    _loadRawStats();
  }

  _loadRawStats() {
    _entitiesGameIdsHistories = {};
    _entitiesGamesStats = {};

    // only finished games for now
    for (Game g in allGames.reversed.where((g) => g.isFinished && !g.isArchived)) {
      Map gameRawStatsMap = g.rawStatsMap;
      for (String id in gameRawStatsMap.keys) {
        _entitiesGameIdsHistories.putIfAbsent(id, () => []);
        _entitiesGameIdsHistories[id].add(g.gameId);
        _entitiesGamesStats.putIfAbsent(id, () => []);
        _entitiesGamesStats[id].add(gameRawStatsMap[id]);
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

  double getBidderRatingAfterGame(String entityId, String gameId) {
    int endIndex = _entitiesGameIdsHistories[entityId].indexOf(gameId) + 1;
    return BidderRatingStatItem.calculateBidderRating(
        _entitiesGamesStats[entityId].sublist(0, endIndex), entityId.contains(' '));
  }

  Color getEntityColor(String entityId) {
    if (_entitiesGameIdsHistories[entityId] == null || _entitiesGameIdsHistories[entityId].isEmpty) {
      // return random color for new team
      return ColorChooser.generateRandomColor(seed: entityId.hashCode);
    }
    if (entityId.contains(' ')) {
      Game lastGame = allGames.firstWhere((g) => g.gameId == _entitiesGameIdsHistories[entityId].last);
      List<String> teamIds = lastGame.teamIds;
      if (teamIds.contains(entityId)) {
        return Util.checkColor(lastGame.teamColors[teamIds.indexOf(entityId)], entityId);
      }
    } else {
      Map<String, Color> teamColors = {};
      Map<String, int> numGames = {};
      List<Game> games = getEntityGames(entityId);
      for (Game game in games) {
        for (int i = 0; i < 2; i++) {
          if (game.allTeamsPlayerIds[i].contains(entityId)) {
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
          if (game.allTeamsPlayerIds[i].contains(entityId)) {
            return Util.checkColor(game.teamColors[i], entityId);
          }
        }
      } else {
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

  List<Game> getEntityGames(String entityId) {
    if (_entitiesGameIdsHistories[entityId] == null) {
      return [];
    }
    return allGames.where((g) => _entitiesGameIdsHistories[entityId].contains(g.gameId)).toList();
  }

  List<Map> getEntityRawGamesStats(String entityId) {
    if (_entitiesGamesStats[entityId] == null) {
      return [];
    }
    return _entitiesGamesStats[entityId].toList();
  }

  Map<int, BiddingSplit> getPlayerBiddingSplits(String playerId, {int numRecent = 0}) {
    Map<int, BiddingSplit> splits = {};
    for (int bid in Round.ALL_BIDS) {
      splits[bid] = BiddingSplit([]);
    }
    int count = 0;
    for (Game g in allGames.where((g) => (g.isFinished && !g.isArchived && g.allPlayerIds.contains(playerId)))) {
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

  double getRatingAfterGame(String entityId, String gameId) {
    int endIndex = _entitiesGameIdsHistories[entityId].indexOf(gameId) + 1;
    return OverallRatingStatItem.calculateOverallRating(
        _entitiesGamesStats[entityId].sublist(0, endIndex), entityId.contains(' '));
  }

  double getRatingBeforeGame(String entityId, String gameId) {
    List<String> gameIds = _entitiesGameIdsHistories.containsKey(entityId) ? _entitiesGameIdsHistories[entityId] : [];
    int endIndex = gameIds.indexOf(gameId);
    if (endIndex <= 0) {
      return 0;
    }
    return OverallRatingStatItem.calculateOverallRating(
        _entitiesGamesStats[entityId].sublist(0, endIndex), entityId.contains(' '));
  }

  StatItem getStat(String entityId, StatType statType) {
    if (!_entitiesGamesStats.containsKey(entityId)) {
      return StatItem.empty(statType);
    }
    List<Map> gamesStats = _entitiesGamesStats[entityId];
    return StatItem.fromGamesStats(statType, gamesStats, entityId.contains(' '));
  }

  Map<int, BiddingSplit> getTeamBiddingSplits(String teamId, {int numRecent = 0}) {
    Map<int, BiddingSplit> splits = {};
    for (int bid in Round.ALL_BIDS) {
      splits[bid] = BiddingSplit([]);
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
