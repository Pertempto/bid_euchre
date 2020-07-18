import 'package:cloud_firestore/cloud_firestore.dart';

import 'data_store.dart';

class User {
  String userId;
  String name;
  List<String> pinnedPlayerIds;

  User.fromDocument(DocumentSnapshot documentSnapshot) {
    userId = documentSnapshot.documentID;
    name = documentSnapshot.data['name'];
    if (documentSnapshot.data['pinnedPlayerIds'] != null) {
      pinnedPlayerIds = documentSnapshot.data['pinnedPlayerIds'].cast<String>();
    } else {
      pinnedPlayerIds = [];
    }
  }

  User.newUser(String userId, String name) {
    DocumentReference doc = DataStore.usersCollection.document(userId);
    this.userId = userId;
    this.name = name;
    this.pinnedPlayerIds = [];
    doc.setData(dataMap);
  }

  Map<String, dynamic> get dataMap {
    return {
      'name': name,
      'pinnedPlayerIds': pinnedPlayerIds,
    };
  }

  static Map<String, User> usersFromSnapshot(QuerySnapshot snapshot) {
    Map<String, User> users = {};
    for (DocumentSnapshot documentSnapshot in snapshot.documents) {
      User user = User.fromDocument(documentSnapshot);
      users[user.userId] = user;
    }
    return users;
  }

  @override
  String toString() {
    return 'User $userId, name: "$name"';
  }

  void updateFirestore() {
    DataStore.usersCollection.document(userId).updateData(dataMap);
  }
}
