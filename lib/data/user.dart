import 'package:cloud_firestore/cloud_firestore.dart';

import 'data_store.dart';

class User {
  String userId;
  String name;
  List<String> pinnedPlayerIds;
  ConfettiSettings confettiSettings;

  User.fromDocument(DocumentSnapshot documentSnapshot) {
    userId = documentSnapshot.documentID;
    name = documentSnapshot.data['name'];
    if (documentSnapshot.data['pinnedPlayerIds'] != null) {
      pinnedPlayerIds = documentSnapshot.data['pinnedPlayerIds'].cast<String>();
    } else {
      pinnedPlayerIds = [];
    }
    if (documentSnapshot.data['confettiSettings'] != null) {
      confettiSettings = ConfettiSettings.fromData(documentSnapshot.data['confettiSettings']);
    } else {
      confettiSettings = ConfettiSettings();
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
      'confettiSettings': confettiSettings.dataMap,
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

class ConfettiSettings {
  static const Map<String, String> LOCATION_NAMES = {
    'tl': 'Top Left',
    'tc': 'Top Center',
    'tr': 'Top Right',
    'bl': 'Bottom Left',
    'bc': 'Bottom Center',
    'br': 'Bottom Right',
  };
  Map<String, bool> locations;
  double force;
  double amount;
  double sizeFactor;
  double gravityFactor;

  ConfettiSettings() {
    locations = {};
    for (String l in LOCATION_NAMES.keys) {
      locations[l] = false;
    }
    locations['tc'] = true;
    force = 1;
    amount = 0.5;
    sizeFactor = 1;
    gravityFactor = 1;
  }

  ConfettiSettings.fromData(Map data) {
    locations = data['locations'].cast<String, bool>();
    force = data['force'];
    amount = data['amount'];
    sizeFactor = data['size'];
    gravityFactor = data['gravity'];
  }

  Map get dataMap {
    return {
      'locations': locations,
      'force': force,
      'amount': amount,
      'size': sizeFactor,
      'gravity': gravityFactor,
    };
  }
}
