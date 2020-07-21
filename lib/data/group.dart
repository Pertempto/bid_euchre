import 'package:bideuchre/data/data_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  String groupId;
  String adminId;
  String name;

  Group.fromDocument(DocumentSnapshot documentSnapshot) {
    groupId = documentSnapshot.documentID;
    adminId = documentSnapshot.data['adminId'];
    name = documentSnapshot.data['name'];
  }

  Group.newGroup(String adminId, String name) {
    DocumentReference doc = DataStore.groupsCollection.document();
    this.groupId = doc.documentID;
    this.adminId = adminId;
    this.name = name;
    doc.setData(dataMap);
  }

  Map<String, dynamic> get dataMap {
    return {
      'adminId': adminId,
      'name': name,
    };
  }

  void updateFirestore() {
    DataStore.groupsCollection.document(groupId).updateData(dataMap);
  }
}
