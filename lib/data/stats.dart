import 'dart:math';

import 'package:bideuchre/data/entity_raw_game_stats.dart';
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
  static const int MIN_ROUNDS = 10;
  List<Game> allGames;
  Map<String, Player> allPlayers;
  Map<int, List<double>> _winChancesCache;
  Map<String, List<String>> _entitiesGameIdsHistories;
  Map<String, Map<String, EntityRawGameStats>> _gameRawStats;

  StatsDb.load(this.allGames, this.allPlayers) {
    _loadRawStats();
  }

  _loadRawStats() {
    _entitiesGameIdsHistories = {};
    _gameRawStats = {};
    _winChancesCache = {};

    int total = 0;
    int count = 0;
    // only finished games for now
    for (Game g in allGames.reversed.where((g) => g.isFinished)) {
      Map<String, EntityRawGameStats> gameRawStatsMap = g.rawStatsMap;
      for (String id in gameRawStatsMap.keys) {
        _entitiesGameIdsHistories.putIfAbsent(id, () => []);
        _entitiesGameIdsHistories[id].add(g.gameId);
        if (!id.contains(" ")) {
          total += gameRawStatsMap[id].gainedOnBids;
          count += gameRawStatsMap[id].numBiddingOpportunities;
        }
      }
      _gameRawStats[g.gameId] = gameRawStatsMap;
    }
    print("$total $count ${total / count}");
  }

  List<double> calculateWinChances(List<String> currentPlayerIds) {
    int hash = hashList(currentPlayerIds);
    if (_winChancesCache.containsKey(hash)) {
      return _winChancesCache[hash];
    }
    List<double> teamRatings = [];
    for (int i = 0; i < 2; i++) {
      String teamId = Util.teamId([currentPlayerIds[i], currentPlayerIds[i + 2]]);
      List<Game> games = getGames(teamId, false);
      double teamRating;
      if (games.isEmpty) {
        double totalPlayerRating = 0;
        for (int j = 0; j < 2; j++) {
          String playerId = currentPlayerIds[i + j * 2];
          totalPlayerRating += (getStat(playerId, StatType.winnerRating, false) as RatingStatItem).rating;
        }
        teamRating = totalPlayerRating / 2;
      } else {
        teamRating = (getStat(teamId, StatType.winnerRating, false) as RatingStatItem).rating;
      }
      teamRatings.add(teamRating);
    }
    List<double> chances = ratingsToWinChances(teamRatings);
    _winChancesCache[hash] = chances;
    return chances;
  }

  double getBidderRatingAfterGame(String entityId, String gameId, {bool includeArchived = false}) {
    int endIndex = _entitiesGameIdsHistories[entityId].indexOf(gameId) + 1;
    List<String> gameIds = _entitiesGameIdsHistories[entityId].sublist(0, endIndex);
    return BidderRatingStatItem.calculateBidderRating(
        getRawStats(entityId, gameIds, includeArchived), entityId.contains(' '),
        isAdjusted: true);
  }

  Map<int, BiddingSplit> getBiddingSplits(String entityId, {int numRecent = 0, bool includeArchived = false}) {
    Map<int, BiddingSplit> splits = {};
    for (int bid in Round.ALL_BIDS) {
      splits[bid] = BiddingSplit([]);
    }
    int count = 0;
    bool isInGame(Game game) {
      if (entityId.contains(" ")) {
        return game.teamIds.contains(entityId);
      } else {
        return game.allPlayerIds.contains(entityId);
      }
    }

    for (Game g in allGames.where((g) => (g.isFinished && (includeArchived || !g.isArchived) && isInGame(g)))) {
      for (Round r in g.rounds.reversed.where((r) => !r.isPlayerSwitch && r.isFinished)) {
        bool isBidder;
        if (entityId.contains(" ")) {
          int teamIndex = g.teamIds.indexOf(entityId);
          isBidder = r.bidderIndex % 2 == teamIndex;
        } else {
          String bidderId = g.getPlayerIdsAfterRound(r.roundIndex - 1)[r.bidderIndex];
          isBidder = bidderId == entityId;
        }
        if (isBidder) {
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

  Color getColor(String entityId) {
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
      List<Game> games = getGames(entityId, true);
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

  List<Game> getGames(String entityId, bool includeArchived) {
    if (_entitiesGameIdsHistories[entityId] == null) {
      return [];
    }
    return allGames
        .where((g) => _entitiesGameIdsHistories[entityId].contains(g.gameId) && (includeArchived || !g.isArchived))
        .toList();
  }

  double getRatingAfterGame(String entityId, String gameId, {bool includeArchived = false}) {
    int endIndex = _entitiesGameIdsHistories[entityId].indexOf(gameId) + 1;
    List<String> gameIds = _entitiesGameIdsHistories[entityId].sublist(0, endIndex);
    return OverallRatingStatItem.calculateOverallRating(
        getRawStats(entityId, gameIds, includeArchived), entityId.contains(' '),
        isAdjusted: true);
  }

  List<EntityRawGameStats> getRawStats(String entityId, List<String> gameIds, bool includeArchived) {
    List<EntityRawGameStats> rawStats = [];
    for (String gameId in gameIds) {
      EntityRawGameStats rawGameStats = _gameRawStats[gameId][entityId];
      if (rawGameStats != null && (includeArchived || !rawGameStats.isArchived)) {
        rawStats.add(rawGameStats);
      }
    }
    return rawStats;
  }

  RatingStatItem getRecentRating(String entityId, StatType statType) {
    if (!_entitiesGameIdsHistories.containsKey(entityId)) {
      return StatItem.empty(statType);
    }
    List<String> gameIds = _entitiesGameIdsHistories[entityId];
    gameIds = gameIds.sublist(max(gameIds.length - 3, 0));
    switch (statType) {
      case StatType.overallRating:
        return OverallRatingStatItem.fromRawStats(getRawStats(entityId, gameIds, false), entityId.contains(' '));
      case StatType.bidderRating:
        return BidderRatingStatItem.fromRawStats(getRawStats(entityId, gameIds, false), entityId.contains(' '));
      default:
        throw Exception('Stat type is not a rating: $statType');
    }
  }

  double getSetterRatingAfterGame(String entityId, String gameId, {bool includeArchived = false}) {
    int endIndex = _entitiesGameIdsHistories[entityId].indexOf(gameId) + 1;
    List<String> gameIds = _entitiesGameIdsHistories[entityId].sublist(0, endIndex);
    return SetterRatingStatItem.calculateSetterRating(
        getRawStats(entityId, gameIds, includeArchived), entityId.contains(' '),
        isAdjusted: true);
  }

  StatItem getStat(String entityId, StatType statType, bool includeArchived) {
    List<String> gameIds = _entitiesGameIdsHistories[entityId];
    if (gameIds == null) {
      gameIds = [];
    }
    List<EntityRawGameStats> rawStats = getRawStats(entityId, gameIds, includeArchived);
    switch (statType) {
      case StatType.overallRating:
        return OverallRatingStatItem.fromRawStats(rawStats, entityId.contains(' '), isAdjusted: true);
      case StatType.bidderRating:
        return BidderRatingStatItem.fromRawStats(rawStats, entityId.contains(' '), isAdjusted: true);
      case StatType.winnerRating:
        return WinnerRatingStatItem.fromRawStats(rawStats, entityId.contains(' '), isAdjusted: true);
      case StatType.setterRating:
        return SetterRatingStatItem.fromRawStats(rawStats, entityId.contains(' '), isAdjusted: true);
      default:
        return StatItem.fromRawStats(statType, rawStats, entityId.contains(' '));
    }
  }

  List<String> getTeamIds(Set<String> playerIds) {
    return _entitiesGameIdsHistories.keys.where((id) {
      List<String> ids = id.split(' ');
      return ids.length >= 2 && playerIds.intersection(ids.toSet()).length == ids.length;
    }).toList();
  }

  double getWinnerRatingAfterGame(String entityId, String gameId, {bool includeArchived = false}) {
    int endIndex = _entitiesGameIdsHistories[entityId].indexOf(gameId) + 1;
    List<String> gameIds = _entitiesGameIdsHistories[entityId].sublist(0, endIndex);
    return WinnerRatingStatItem.calculateWinnerRating(
        getRawStats(entityId, gameIds, includeArchived), entityId.contains(' '),
        isAdjusted: true);
  }

  static List<double> ratingsToWinChances(List<double> teamRatings) {
    double team1WinChance = 1 / (pow(10, ((teamRatings[1] - teamRatings[0]) / 40)) + 1);
    return [team1WinChance, 1 - team1WinChance];
  }
}
