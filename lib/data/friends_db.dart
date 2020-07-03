import 'package:cloud_firestore/cloud_firestore.dart';

import 'data_store.dart';

class FriendsDb {
  Map<String, FriendRelationship> _relationships;

  FriendsDb.empty() {
    _relationships = {};
  }

  FriendsDb.fromSnapshot(QuerySnapshot snapshot) {
    Map<String, FriendRelationship> relationships = {};
    for (DocumentSnapshot documentSnapshot in snapshot.documents) {
      FriendRelationship relationship = FriendRelationship.relationshipFromDocument(documentSnapshot);
      relationships[relationship.relationshipId] = relationship;
    }
    _relationships = relationships;
  }

  void acceptFriendRequest(String user1Id, String user2Id) {
    FriendRelationship relationship = getRelationship(user1Id, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.requested) {
      relationship.status = RelationshipStatus.accepted;
      relationship.updateFirestore();
    }
  }

  void addFriendRequest(String user1Id, String user2Id) {
    FriendRelationship relationship = getRelationship(user1Id, user2Id);
    if (relationship == null) {
      relationship = FriendRelationship(user1Id, user2Id, RelationshipStatus.requested);
      _relationships[relationship.relationshipId] = relationship;
      relationship.updateFirestore();
    }
  }

  bool areFriends(String user1Id, String user2Id) {
    FriendRelationship relationship = getRelationship(user1Id, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.accepted) {
      return true;
    }
    return false;
  }

  void cancelFriendRequest(String user1Id, String user2Id) {
    FriendRelationship relationship = getRelationship(user1Id, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.requested) {
      DataStore.friendsCollection.document(relationship.relationshipId).delete();
      _relationships.remove(relationship.relationshipId);
    }
  }

  void deleteBlockedFriendRequest(String user1Id, String user2Id) {
    FriendRelationship relationship = getRelationship(user1Id, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.blocked) {
      DataStore.friendsCollection.document(relationship.relationshipId).delete();
      _relationships.remove(relationship.relationshipId);
    }
  }

  void deleteFriend(String user1Id, String user2Id) {
    FriendRelationship relationship = getRelationship(user1Id, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.accepted) {
      DataStore.friendsCollection.document(relationship.relationshipId).delete();
      _relationships.remove(relationship.relationshipId);
    }
  }

  List<String> getBlockedUserIds(String userId) {
    List<String> blockedUserIds = [];
    for (FriendRelationship relationship in _relationships.values) {
      if (relationship.user2Id == userId && relationship.status == RelationshipStatus.blocked) {
        blockedUserIds.add(relationship.user1Id);
      }
    }
    return blockedUserIds;
  }

  List<String> getFriendIds(String userId) {
    List<String> friendIds = [];
    for (FriendRelationship relationship in _relationships.values) {
      if (relationship.userIds.contains(userId) && relationship.status == RelationshipStatus.accepted) {
        if (relationship.user1Id == userId) {
          friendIds.add(relationship.user2Id);
        } else {
          friendIds.add(relationship.user1Id);
        }
      }
    }
    return friendIds;
  }

  List<String> getPendingFriendRequestIds(String userId) {
    List<String> userIds = [];
    for (FriendRelationship relationship in _relationships.values) {
      // only if user1Id is the userId, because user1Id is the requester
      if (relationship.user1Id == userId && relationship.status == RelationshipStatus.requested) {
        userIds.add(relationship.user2Id);
      }
    }
    return userIds;
  }

  FriendRelationship getRelationship(String user1Id, String user2Id) {
    if (user1Id == null || user2Id == null) {
      return null;
    }
    String relationshipId = FriendRelationship.generateRelationshipId(user1Id, user2Id);
    return _relationships[relationshipId];
  }

  List<String> getRequestingFriendIds(String userId) {
    List<String> userIds = [];
    for (FriendRelationship relationship in _relationships.values) {
      // only if user2Id is the userId, because user1Id is the requester
      if (relationship.user2Id == userId && relationship.status == RelationshipStatus.requested) {
        userIds.add(relationship.user1Id);
      }
    }
    return userIds;
  }

  void blockFriendRequest(String user1Id, String user2Id) {
    FriendRelationship relationship = getRelationship(user1Id, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.requested) {
      relationship.status = RelationshipStatus.blocked;
      relationship.updateFirestore();
    }
  }
}

class FriendRelationship {
  FriendRelationship(this.user1Id, this.user2Id, this.status);

  String user1Id;
  String user2Id;
  RelationshipStatus status;

  String get relationshipId {
    return generateRelationshipId(user1Id, user2Id);
  }

  List<String> get userIds {
    return [user1Id, user2Id];
  }

  Map<String, dynamic> get dataMap {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'status': status.index,
    };
  }

  static FriendRelationship relationshipFromDocument(DocumentSnapshot documentSnapshot) {
    Map data = documentSnapshot.data;
    return FriendRelationship(
      data['user1Id'],
      data['user2Id'],
      RelationshipStatus.values[data['status']],
    );
  }

  static String generateRelationshipId(String user1Id, String user2Id) {
    List<String> userIds = [user1Id, user2Id];
    userIds.sort();
    return userIds.join(' ');
  }

  void updateFirestore() {
    DataStore.friendsCollection.document(relationshipId).setData(dataMap);
  }
}

enum RelationshipStatus { requested, accepted, blocked }
