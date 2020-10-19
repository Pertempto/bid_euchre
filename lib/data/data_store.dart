import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import 'authentication.dart';
import 'game.dart';
import 'player.dart';
import 'relationships.dart';
import 'stats.dart';
import 'user.dart';

class DataStore {
  static CollectionReference friendsCollection = FirebaseFirestore.instance.collection('friends');
  static CollectionReference gamesCollection = FirebaseFirestore.instance.collection('games');
  static CollectionReference groupsCollection = FirebaseFirestore.instance.collection('groups');
  static CollectionReference playersCollection = FirebaseFirestore.instance.collection('players');
  static CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  static List<Stream> streamList = [
    friendsCollection.snapshots(),
    gamesCollection.snapshots(),
    groupsCollection.snapshots(),
    playersCollection.snapshots(),
    usersCollection.snapshots(),
  ];
  static Stream dataStream = Rx.combineLatest(streamList, combineSnapshots).map(onDataUpdate).asBroadcastStream();
  static Auth auth;
  static String currentUserId;
  static Data currentData = Data.empty();
  static bool displayArchivedStats = false;

  static Map combineSnapshots(List values) {
    return {
      'friends': values[0],
      'games': values[1],
      'groups': values[2],
      'players': values[3],
      'users': values[4],
    };
  }

  static StreamBuilder dataWrap(Widget Function(Data data) callback, {bool allowNull = false}) {
    return StreamBuilder(
      stream: dataStream,
      builder: (context, mainSnapshot) {
        if (currentUserId == null) {
          print('User id is null, signing out...');
          auth.signOut();
          return Container();
        }
        if (currentData.loaded || allowNull) {
          return callback(currentData);
        }
        return Container();
      },
    );
  }

  static void onDataUpdate(Map data) {
    currentData.updateUsers(data['users']);
    currentData.updateRelationships(data['friends']);
    currentData.updateGroups(data['groups']);
    currentData.updateGames(data['games']);
    currentData.updatePlayers(data['players']);
  }
}

class Data {
  User _currentUser;
  Map<String, User> _users;
  QuerySnapshot _lastRelationshipsSnapshot;
  QuerySnapshot _lastGroupsSnapshot;
  RelationshipsDb _relationshipsDb;
  List<Game> _allGames;
  List<Game> _games;
  Map<String, Player> _allPlayers;
  Map<String, Player> _players;
  StatsDb _statsDb;

  User get currentUser => _currentUser;

  Map<String, User> get users => _users;

  RelationshipsDb get relationshipsDb => _relationshipsDb;

  List<Game> get allGames => _allGames;

  List<Game> get games => _games;

  Map<String, Player> get allPlayers => _allPlayers;

  Map<String, Player> get players => _players;

  StatsDb get statsDb => _statsDb;

  bool get loaded {
    return currentUser != null && relationshipsDb != null && allGames != null && allPlayers != null && statsDb != null;
  }

  Data.empty();

  updateUsers(QuerySnapshot snapshot) {
    Map<String, User> users = User.usersFromSnapshot(snapshot);
    _currentUser = users[DataStore.currentUserId];
    _users = users;
  }

  updateRelationships(QuerySnapshot snapshot) {
    _lastRelationshipsSnapshot = snapshot;
    _updateRelationshipsDb();
  }

  updateGroups(QuerySnapshot snapshot) {
    _lastGroupsSnapshot = snapshot;
    _updateRelationshipsDb();
  }

  _updateRelationshipsDb() {
    if (_lastGroupsSnapshot != null && _lastRelationshipsSnapshot != null) {
      _relationshipsDb = RelationshipsDb.fromSnapshot(_lastRelationshipsSnapshot, _lastGroupsSnapshot);
    }
  }

  updateGames(QuerySnapshot snapshot) {
    List<Game> games = Game.gamesFromSnapshot(snapshot);
    List<Game> filteredGames = [];
    for (Game game in games) {
      if (game.userId == DataStore.currentUserId) {
        filteredGames.add(game);
      } else {
        if (relationshipsDb != null && relationshipsDb.canShare(game.userId, DataStore.currentUserId)) {
          filteredGames.add(game);
        }
      }
    }
    _allGames = games;
    _games = filteredGames;
    _updateStats();
  }

  updatePlayers(QuerySnapshot snapshot) {
    Map<String, Player> players = Player.playersFromSnapshot(snapshot);
    Map<String, Player> filteredPlayers = {};
    for (String playerId in players.keys) {
      Player player = players[playerId];
      if (player.ownerId == DataStore.currentUserId) {
        filteredPlayers[playerId] = player;
      } else {
        if (relationshipsDb != null && relationshipsDb.canShare(player.ownerId, DataStore.currentUserId)) {
          filteredPlayers[playerId] = player;
        }
      }
    }
    _allPlayers = players;
    _players = filteredPlayers;
    _updateStats();
  }

  _updateStats() {
    if (allGames != null && allPlayers != null) {
      if (_statsDb == null ||
          hashList(allGames.where((g) => g.isFinished)) != hashList(_statsDb.allGames.where((g) => g.isFinished)) ||
          hashList(allPlayers.keys) != hashList(_statsDb.allPlayers.keys)) {
        print(
            'loading new stats db ${hashList(allGames.where((g) => g.isFinished))}:${hashList(_statsDb.allGames.where((g) => g.isFinished))} ${hashList(allPlayers.keys)}:${hashList(_statsDb.allPlayers.keys)} ');
        _statsDb = StatsDb.load(allGames, allPlayers);
        // if (true) {
        //   int correct = 0;
        //   int total = 0;
        //   for (Game g in games.where((g) => g.isFinished && !g.isArchived)) {
        //     total++;
        //     if (_statsDb.calculateWinChances(g.initialPlayerIds, [0, 0], 42,
        //             beforeGameId: g.gameId)[g.winningTeamIndex] >=
        //         0.5) {
        //       correct++;
        //     }
        //   }
        //   print('$correct/$total (${(correct / total * 100).toStringAsFixed(2)}%)');
        // }
      }
    } else {
      if (_statsDb == null) {
        _statsDb = StatsDb.load([], {});
      }
    }
  }
}
