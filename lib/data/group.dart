import 'package:bideuchre/data/data_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  String groupId;
  String adminId;
  String name;

  Group.fromDocument(DocumentSnapshot documentSnapshot) {
    groupId = documentSnapshot.id;
    adminId = documentSnapshot.data()['adminId'];
    name = documentSnapshot.data()['name'];
  }

  Group.newGroup(String adminId, String name) {
    DocumentReference doc = DataStore.groupsCollection.doc();
    this.groupId = doc.id;
    this.adminId = adminId;
    this.name = name;
    doc.set(dataMap);
  }

  Map<String, dynamic> get dataMap {
    return {
      'adminId': adminId,
      'name': name,
    };
  }

  void updateFirestore() {
    DataStore.groupsCollection.doc(groupId).update(dataMap);
  }
}
