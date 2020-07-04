import 'package:bideuchre/data/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import 'authentication.dart';
import 'friends_db.dart';
import 'game.dart';
import 'player.dart';
import 'stats.dart';

class DataStore {
  static CollectionReference friendsCollection = Firestore.instance.collection('friends');
  static CollectionReference gamesCollection = Firestore.instance.collection('games');
  static CollectionReference playersCollection = Firestore.instance.collection('players');
  static CollectionReference usersCollection = Firestore.instance.collection('users');
  static Auth auth;
  static String currentUserId;
  static Data lastData;

  static StreamBuilder dataWrap(Widget Function(Data data) callback, {bool allowNull = false}) {
    return _usersWrap(allowNull, (users) {
      if (currentUserId == null) {
        print('User id is null, signing out...');
        auth.signOut();
        return Container();
      }
      User currentUser = users[currentUserId];
      return _friendsWrap(allowNull, (friendsDb) {
        return _gamesWrap(allowNull, (games) {
          List<Game> filteredGames = [];
          for (Game game in games) {
            if (game.userId == currentUserId) {
              filteredGames.add(game);
            } else {
              if (friendsDb.areFriends(game.userId, currentUserId)) {
                filteredGames.add(game);
              }
            }
          }
          return _playersWrap(allowNull, (players, loaded) {
            Map<String, Player> filteredPlayers = {};
            for (String playerId in players.keys) {
              Player player = players[playerId];
              if (player.ownerId == currentUserId) {
                filteredPlayers[playerId] = player;
              } else {
                if (friendsDb.areFriends(player.ownerId, currentUserId)) {
                  filteredPlayers[playerId] = player;
                }
              }
            }
            StatsDb statsDb = StatsDb.fromGames(games);
            Data data =
                Data(currentUser, users, friendsDb, games, filteredGames, players, filteredPlayers, statsDb, loaded);
            if (!loaded && lastData != null) {
              print('using last data');
              return callback(lastData);
            }
            lastData = data;
            return callback(data);
          });
        });
      });
    });
  }

  static StreamBuilder _friendsWrap(bool allowNull, Widget Function(FriendsDb friendsDb) callback) {
    return StreamBuilder<QuerySnapshot>(
      stream: friendsCollection.snapshots(),
      builder: (context, snapshot) {
        FriendsDb friendDb;
        if (snapshot.hasData) {
          friendDb = FriendsDb.fromSnapshot(snapshot.data);
          return callback(friendDb);
        } else {
          if (allowNull) {
            return callback(FriendsDb.empty());
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
  final FriendsDb friendsDb;
  final List<Game> allGames;
  final List<Game> games;
  final Map<String, Player> allPlayers;
  final Map<String, Player> players;
  final StatsDb statsDb;
  final bool loaded;

  Data(this.currentUser, this.users, this.friendsDb, this.allGames, this.games, this.allPlayers, this.players,
      this.statsDb, this.loaded);
}
