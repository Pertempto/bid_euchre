import 'package:cloud_firestore/cloud_firestore.dart';

import 'data_store.dart';
import 'user.dart';

class Player {
  String playerId;
  String ownerId;
  String fullName;

  Player.fromDocument(DocumentSnapshot documentSnapshot) {
    playerId = documentSnapshot.documentID;
    Map data = documentSnapshot.data;
    ownerId = data['ownerId'];
    fullName = data['fullName'];
  }

  Player.newPlayer(User user, String fullName) {
    DocumentReference doc = DataStore.playersCollection.document();
    playerId = doc.documentID;
    ownerId = user.userId;
    this.fullName = fullName;
    doc.setData(dataMap);
  }

  Map<String, dynamic> get dataMap {
    return {
      'ownerId': ownerId,
      'fullName': fullName,
    };
  }

  String get shortName {
    String firstName = fullName.split(' ')[0];
    if (firstName.length > 8) {
      return firstName.substring(0, 5) + '...';
    }
    return firstName;
  }

  static Map<String, Player> playersFromSnapshot(QuerySnapshot snapshot) {
    Map<String, Player> players = {};
    for (DocumentSnapshot documentSnapshot in snapshot.documents) {
      Player player = Player.fromDocument(documentSnapshot);
      players[player.playerId] = player;
    }
    return players;
  }

  void updateFirestore() {
    DataStore.playersCollection.document(playerId).updateData(dataMap);
  }
}
