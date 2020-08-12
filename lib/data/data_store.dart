import 'package:bideuchre/data/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import 'authentication.dart';
import 'game.dart';
import 'player.dart';
import 'relationships.dart';
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
            if (games.isNotEmpty && players.isNotEmpty) {
              if (statsDb == null ||
                  hashList(games.where((g) => g.isFinished)) != hashList(statsDb.allGames.where((g) => g.isFinished)) ||
                  hashList(players.keys) != hashList(statsDb.allPlayers.keys)) {
                print(
                    'loading new stats db ${hashList(games.where((g) => g.isFinished))}:${hashList(statsDb.allGames.where((g) => g.isFinished))} ${hashList(players.keys)}:${hashList(statsDb.allPlayers.keys)} ');
                statsDb = StatsDb.load(games, players);
                lastStats = statsDb;
//                int correct = 0;
//                int total = 0;
//                for (Game g in games.where((g) => g.isFinished)) {
//                  total++;
//                  if (statsDb.getWinChances(g.initialPlayerIds, [0, 0], 42)[g.winningTeamIndex] >= 0.5) {
//                    correct++;
//                  }
//                }
//                print('$correct/$total (${(correct / total * 100).toStringAsFixed(2)}%)');
              }
            } else {
              if (statsDb == null) {
                statsDb = StatsDb.load([], {});
                lastStats = statsDb;
              }
            }
            Data data = Data(
                currentUser, users, relationshipsDb, games, filteredGames, players, filteredPlayers, statsDb, loaded);
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
