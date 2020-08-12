import 'package:cloud_firestore/cloud_firestore.dart';

import 'data_store.dart';
import 'group.dart';

class RelationshipsDb {
  Map<String, Relationship> _groupRelationships;
  Map<String, Group> _groups;

  RelationshipsDb.empty() {
    _groupRelationships = {};
    _groups = {};
  }

  RelationshipsDb.fromSnapshot(QuerySnapshot friendsSnapshot, QuerySnapshot groupsSnapshot) {
    Map<String, Relationship> groupRelationships = {};
    Map<String, Group> groups = {};
    for (DocumentSnapshot documentSnapshot in friendsSnapshot.documents) {
      Relationship relationship = Relationship.relationshipFromDocument(documentSnapshot);
      if (relationship.type == RelationshipType.group) {
        groupRelationships[relationship.relationshipId] = relationship;
      }
    }
    for (DocumentSnapshot documentSnapshot in groupsSnapshot.documents) {
      Group group = Group.fromDocument(documentSnapshot);
      groups[group.groupId] = group;
    }
    _groupRelationships = groupRelationships;
    _groups = groups;
  }

  void acceptInvite(String groupId, String user2Id) {
    Relationship relationship = getGroupRelationship(groupId, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.requested) {
      relationship.status = RelationshipStatus.accepted;
      relationship.updateFirestore();
    }
  }

  void blockInvite(String groupId, String user2Id) {
    Relationship relationship = getGroupRelationship(groupId, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.requested) {
      relationship.status = RelationshipStatus.blocked;
      relationship.updateFirestore();
    }
  }

  /* See if the two users can see each other's games, players, and other resources in the app */
  bool canShare(String user1Id, String user2Id) {
    // test if the users are the same
    if (user1Id == user2Id) {
      return true;
    }
    // test if the users have any groups in common
    if (getGroupIds(user1Id).toSet().intersection(getGroupIds(user2Id).toSet()).isNotEmpty) {
      return true;
    }
    return false;
  }

  void cancelInvite(String groupId, String user2Id) {
    Relationship relationship = getGroupRelationship(groupId, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.requested) {
      DataStore.friendsCollection.document(relationship.relationshipId).delete();
      _groupRelationships.remove(relationship.relationshipId);
    }
  }

  void deleteBlockedInvite(String groupId, String user2Id) {
    Relationship relationship = getGroupRelationship(groupId, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.blocked) {
      DataStore.friendsCollection.document(relationship.relationshipId).delete();
      _groupRelationships.remove(relationship.relationshipId);
    }
  }

  void deleteMember(String groupId, String user2Id) {
    Relationship relationship = getGroupRelationship(groupId, user2Id);
    if (relationship != null && relationship.status == RelationshipStatus.accepted) {
      DataStore.friendsCollection.document(relationship.relationshipId).delete();
      _groupRelationships.remove(relationship.relationshipId);
    }
  }

  List<String> getBlockedGroupIds(String userId) {
    List<String> blockedGroupIds = [];
    for (Relationship relationship in _groupRelationships.values) {
      if (relationship.user2Id == userId && relationship.status == RelationshipStatus.blocked) {
        blockedGroupIds.add(relationship.groupId);
      }
    }
    return blockedGroupIds;
  }

  /* Get the group with the corresponding id */
  Group getGroup(String groupId) {
    return _groups[groupId];
  }

  /* Get the ids of all the user's groups */
  List<String> getGroupIds(String userId) {
    List<String> groupIds = [];
    for (Group group in _groups.values) {
      if (group.adminId == userId) {
        groupIds.add(group.groupId);
      }
    }
    for (Relationship relationship in _groupRelationships.values) {
      if (relationship.user2Id == userId && relationship.status == RelationshipStatus.accepted) {
        groupIds.add(relationship.groupId);
      }
    }
    return groupIds;
  }

  /* Get the ids of all groups that are inviting this user */
  List<String> getGroupInvitations(String userId) {
    List<String> groupIds = [];
    for (Relationship relationship in _groupRelationships.values) {
      if (relationship.user2Id == userId && relationship.status == RelationshipStatus.requested) {
        groupIds.add(relationship.groupId);
      }
    }
    return groupIds;
  }

  Relationship getGroupRelationship(String groupId, String user2Id) {
    if (groupId == null || user2Id == null) {
      return null;
    }
    String relationshipId = Relationship.generateGroupRelationshipId(groupId, user2Id);
    return _groupRelationships[relationshipId];
  }

  List<String> getInvitedUserIds(String groupId) {
    List<String> invitedIds = [];
    for (Relationship relationship in _groupRelationships.values) {
      if (relationship.groupId == groupId && relationship.status == RelationshipStatus.requested) {
        invitedIds.add(relationship.user2Id);
      }
    }
    return invitedIds;
  }

  List<String> getMemberIds(String groupId) {
    List<String> memberIds = [_groups[groupId].adminId];
    for (Relationship relationship in _groupRelationships.values) {
      if (relationship.groupId == groupId && relationship.status == RelationshipStatus.accepted) {
        memberIds.add(relationship.user2Id);
      }
    }
    return memberIds;
  }

  void inviteUser(String groupId, String user2Id) {
    Relationship relationship = getGroupRelationship(groupId, user2Id);
    if (relationship == null) {
      relationship = Relationship.group(groupId, user2Id, RelationshipStatus.requested);
      _groupRelationships[relationship.relationshipId] = relationship;
      relationship.updateFirestore();
    }
  }
}

class Relationship {
  Relationship(this.user1Id, this.user2Id, this.status);

  Relationship.group(groupId, this.user2Id, this.status) {
    user1Id = '#' + groupId;
  }

  String user1Id;
  String user2Id;
  RelationshipStatus status;

  String get groupId {
    if (type == RelationshipType.group) {
      return user1Id.substring(1);
    }
    return null;
  }

  String get relationshipId {
    return generateRelationshipId(user1Id, user2Id);
  }

  RelationshipType get type {
    if (user1Id.startsWith('#')) {
      return RelationshipType.group;
    }
    return RelationshipType.friend;
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

  static Relationship relationshipFromDocument(DocumentSnapshot documentSnapshot) {
    Map data = documentSnapshot.data;
    return Relationship(
      data['user1Id'],
      data['user2Id'],
      RelationshipStatus.values[data['status']],
    );
  }

  static String generateGroupRelationshipId(String groupId, String user2Id) {
    return '#$groupId $user2Id';
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
enum RelationshipType { friend, group }
