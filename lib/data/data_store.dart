import 'dart:collection';
import 'dart:math';

import 'package:bideuchre/data/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import 'authentication.dart';
import 'relationships.dart';
import 'game.dart';
import 'player.dart';
import 'stats.dart';

class DataStore {
  static CollectionReference friendsCollection = Firestore.instance.collection('friends');
  static CollectionReference gamesCollection = Firestore.instance.collection('games');
  static CollectionReference groupsCollection = Firestore.instance.collection('groups');
  static CollectionReference playersCollection = Firestore.instance.collection('players');
  static CollectionReference usersCollection = Firestore.instance.collection('users');
  static Auth auth;
  static String currentUserId;
  static Data lastData;
  static StatsDb lastStats;
  static const _eq = ListEquality();
  static Map<List, List> _winData = HashMap(equals: _eq.equals, hashCode: _eq.hash, isValidKey: _eq.isValidKey);

  static StreamBuilder dataWrap(Widget Function(Data data) callback, {bool allowNull = false}) {
    return _usersWrap(allowNull, (users) {
      if (currentUserId == null) {
        print('User id is null, signing out...');
        auth.signOut();
        return Container();
      }
      User currentUser = users[currentUserId];
      return _relationshipsWrap(allowNull, (relationshipsDb) {
        return _gamesWrap(allowNull, (games) {
//          games.forEach((g) {
//            if (g.userId == 'ifyDcznPS5OF4Ng8QCoKydTK6jp1') {
//              print(g.gameId);
//              g.userId = 'saGRfPf2HWdsgWkyWsyDjeKh22N2';
//              g.updateFirestore();
//            }
//          });
          List<Game> filteredGames = [];
          for (Game game in games) {
            if (game.userId == currentUserId) {
              filteredGames.add(game);
            } else {
              if (relationshipsDb.canShare(game.userId, currentUserId)) {
                filteredGames.add(game);
              }
            }
          }
          if (_winData.isEmpty) {
            print('loading win data...');
            int c = 0;
            for (Game g in games.where((g) => g.isFinished)) {
              for (Round r in g.rounds) {
                if (!r.isPlayerSwitch) {
                  List<int> score = g.getScoreAfterRound(r.roundIndex - 1);
                  int scoreDelta = (score[0] - score[1]).abs();
                  if (scoreDelta != 0) {
                    int higherScore = max(score[0], score[1]);
                    int pointsLeftToWin = g.gameOverScore - higherScore;
                    int winningTeamIndex = score.indexOf(higherScore);
                    bool didWin = g.winningTeamIndex == winningTeamIndex;
                    _winData.putIfAbsent([pointsLeftToWin, scoreDelta], () => [0, 0]);
                    if (didWin) {
                      _winData[[pointsLeftToWin, scoreDelta]][0]++;
                    }
                    _winData[[pointsLeftToWin, scoreDelta]][1]++;
                    c++;
                  }
                }
              }
            }
            print('done loading win data, data points: $c');
          }
          return _playersWrap(allowNull, (players, loaded) {
//            players.values.forEach((p) {
//              if (p.ownerId == 'ifyDcznPS5OF4Ng8QCoKydTK6jp1') {
//                print('${p.playerId} ${p.fullName}');
//                p.ownerId = 'saGRfPf2HWdsgWkyWsyDjeKh22N2';
//                p.updateFirestore();
//              }
//            });
            Map<String, Player> filteredPlayers = {};
            for (String playerId in players.keys) {
              Player player = players[playerId];
              if (player.ownerId == currentUserId) {
                filteredPlayers[playerId] = player;
              } else {
                if (relationshipsDb.canShare(player.ownerId, currentUserId)) {
                  filteredPlayers[playerId] = player;
                }
              }
            }
            StatsDb statsDb = lastStats;
            if (statsDb == null || hashList(games) != hashList(statsDb.games)) {
//              print('loading new stats db');
              statsDb = StatsDb.fromGames(games);
              statsDb.preload(filteredPlayers);
              lastStats = statsDb;
            }
            Data data =
                Data(currentUser, users, relationshipsDb, games, filteredGames, players, filteredPlayers, statsDb, loaded);
            if (!loaded && lastData != null) {
//              print('using last data');
              return callback(lastData);
            }
            lastData = data;
            return callback(data);
          });
        });
      });
    });
  }

  static StreamBuilder _relationshipsWrap(bool allowNull, Widget Function(RelationshipsDb relationshipsDb) callback) {
    return StreamBuilder<QuerySnapshot>(
      stream: friendsCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return StreamBuilder<QuerySnapshot>(
            stream: groupsCollection.snapshots(),
            builder: (context, snapshot2) {
              if (snapshot2.hasData) {
                return callback(RelationshipsDb.fromSnapshot(snapshot.data, snapshot2.data));
              } else {
                if (allowNull) {
                  return callback(RelationshipsDb.empty());
                } else {
                  return Container();
                }
              }
            },
          );
        } else {
          if (allowNull) {
            return callback(RelationshipsDb.empty());
          } else {
            return Container();
          }
        }
      },
    );
  }

  static StreamBuilder _gamesWrap(bool allowNull, Widget Function(List<Game> games) callback) {
    return StreamBuilder<QuerySnapshot>(
      stream: gamesCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return callback(Game.gamesFromSnapshot(snapshot.data));
        } else {
          if (allowNull) {
            return callback([]);
          }
          return Container();
        }
      },
    );
  }

  static StreamBuilder _playersWrap(
      bool allowNull, Widget Function(Map<String, Player> players, bool loaded) callback) {
    return StreamBuilder<QuerySnapshot>(
      stream: playersCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return callback(Player.playersFromSnapshot(snapshot.data), true);
        } else {
          if (allowNull) {
            return callback({}, false);
          }
          return Container();
        }
      },
    );
  }

  static StreamBuilder _usersWrap(bool allowNull, Widget Function(Map<String, User> users) callback) {
    return StreamBuilder<QuerySnapshot>(
      stream: usersCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return callback(User.usersFromSnapshot(snapshot.data));
        } else {
          if (allowNull) {
            return callback({});
          }
          return Container();
        }
      },
    );
  }

  static List<double> winProbabilities(List<int> score, int gameOverScore) {
    List<double> probabilities = [0.5, 0.5];

    int scoreDelta = (score[0] - score[1]).abs();
    if (scoreDelta == 0) {
      return [0.5, 0.5];
    }
    int higherScore = max(score[0], score[1]);
    int pointsLeftToWin = gameOverScore - higherScore;
    int winningTeamIndex = score.indexOf(higherScore);
    if (pointsLeftToWin <= 0) {
      probabilities[winningTeamIndex] = 1;
      probabilities[1 - winningTeamIndex] = 0;
      return probabilities;
    }
    double total = 0;
    double count = 0;
    int leftToWinRadius = 5;
    int scoreDeltaRadius = 1;
    while (count < 20) {
      total = 0;
      count = 0;
      for (List key in _winData.keys) {
        if ((key[0] - pointsLeftToWin).abs() < leftToWinRadius && (key[1] - scoreDelta).abs() < scoreDeltaRadius) {
          total += _winData[key][0];
          count += _winData[key][1];
        }
      }
      leftToWinRadius++;
      scoreDeltaRadius++;
    }
    double winningChance = total / count;
    if (winningChance == 1) {
      winningChance = 0.999;
    }
    probabilities[winningTeamIndex] = winningChance;
    probabilities[1 - winningTeamIndex] = 1 - winningChance;
    return probabilities;
  }
}

class Data {
  final User currentUser;
  final Map<String, User> users;
  final RelationshipsDb relationshipsDb;
  final List<Game> allGames;
  final List<Game> games;
  final Map<String, Player> allPlayers;
  final Map<String, Player> players;
  final StatsDb statsDb;
  final bool loaded;

  Data(this.currentUser, this.users, this.relationshipsDb, this.allGames, this.games, this.allPlayers, this.players,
      this.statsDb, this.loaded);
}
