import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/friends_db.dart';
import '../data/player.dart';
import '../data/user.dart';
import 'request_friend_selection.dart';

class FriendsPage extends StatefulWidget {
  FriendsPage();

  @override
  _FriendsState createState() => _FriendsState();
}

class _FriendsState extends State<FriendsPage> with AutomaticKeepAliveClientMixin<FriendsPage> {
  Map<String, Player> allPlayers;
  Data data;
  User currentUser;
  FriendsDb friendsDb;
  Map<String, Player> players;
  Map<String, User> users;
  TextTheme textTheme;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    textTheme = Theme.of(context).textTheme;
    return DataStore.dataWrap((data) {
      this.data = data;
      allPlayers = data.allPlayers;
      currentUser = data.currentUser;
      friendsDb = data.friendsDb;
      players = data.players;
      users = data.users;
      List<Widget> children = [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: <Widget>[
              Spacer(),
              OutlineButton.icon(
                icon: Icon(Icons.person_add),
                label: Text('Request Friend'),
                onPressed: () {
                  List<User> usersList = users.values
                      .where((u) =>
                          u.userId != currentUser.userId &&
                          friendsDb.getRelationship(currentUser.userId, u.userId) == null)
                      .toList();
                  requestFriend(context, usersList);
                },
              ),
            ],
          ),
        ),
      ];

      children.addAll(friendsSection());
      children.addAll(friendRequestsSection());
      children.addAll(blockedUsersSection());

      return SingleChildScrollView(
        child: Column(
          children: children,
        ),
      );
    });
  }

  List<Widget> blockedUsersSection() {
    List<Widget> children = [];
    List<String> blockedUserIds = data.friendsDb.getBlockedUserIds(data.currentUser.userId);
    if (blockedUserIds.isNotEmpty) {
      children.add(_buildHeader(context, 'Blocked Users'));
      children.add(SizedBox(height: 8));
      for (String userId in blockedUserIds) {
        List<Widget> trailingButtons = [
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.red,
            ),
            onPressed: () {
              setState(() {
                friendsDb.deleteBlockedFriendRequest(currentUser.userId, userId);
              });
            },
          )
        ];
        children.add(ListTile(
          dense: true,
          title: Text(users[userId].name, style: textTheme.headline6),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: trailingButtons,
          ),
        ));
        if (userId != blockedUserIds.last) {
          children.add(Divider());
        } else {
          children.add(SizedBox(height: 8));
        }
      }
    }
    return children;
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      color: Colors.grey[200],
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
            child: Text(title, style: textTheme.subtitle2),
          ),
          Spacer(),
        ],
      ),
    );
  }

  List<Widget> friendsSection() {
    List<Widget> children = [];
    List<String> friendIds = friendsDb.getFriendIds(currentUser.userId);
    if (friendIds.isNotEmpty) {
      children.add(_buildHeader(context, 'Friends'));
      children.add(SizedBox(height: 8));
      for (String userId in friendIds) {
        children.add(ListTile(
          title: Text(users[userId].name, style: textTheme.headline6),
          trailing: IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.red,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Delete Friend'),
                    contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                    content: Text('Are you sure?'),
                    actions: <Widget>[
                      FlatButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text('Delete'),
                        onPressed: () {
                          setState(() {
                            friendsDb.deleteFriend(currentUser.userId, userId);
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          dense: true,
        ));
        if (userId != friendIds.last) {
          children.add(Divider());
        } else {
          children.add(SizedBox(height: 8));
        }
      }
    }
    return children;
  }

  List<Widget> friendRequestsSection() {
    List<Widget> children = [];
    List<String> requestingFriendIds = friendsDb.getRequestingFriendIds(currentUser.userId);
    List<String> pendingFriendRequestsIds = friendsDb.getPendingFriendRequestIds(currentUser.userId);
    List<String> allRequestIds = requestingFriendIds + pendingFriendRequestsIds;
    if (allRequestIds.isNotEmpty) {
      children.add(_buildHeader(context, 'Friend Requests'));
      children.add(SizedBox(height: 8));
      for (String userId in allRequestIds) {
        List<Widget> trailingButtons;
        if (requestingFriendIds.contains(userId)) {
          trailingButtons = [
            IconButton(
              icon: Icon(
                Icons.check,
                color: Colors.green,
              ),
              onPressed: () {
                print('accepted $userId');
                setState(() {
                  friendsDb.acceptFriendRequest(currentUser.userId, userId);
                });
              },
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.red,
              ),
              onPressed: () {
                print('rejected $userId');
                setState(() {
                  friendsDb.blockFriendRequest(currentUser.userId, userId);
                });
              },
            )
          ];
        } else {
          trailingButtons = [
            IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.red,
              ),
              onPressed: () {
                print('canceled $userId');
                setState(() {
                  friendsDb.cancelFriendRequest(currentUser.userId, userId);
                });
              },
            )
          ];
        }
        children.add(ListTile(
          title: Text(users[userId].name, style: textTheme.headline6),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: trailingButtons,
          ),
          dense: true,
        ));
        if (userId != allRequestIds.last) {
          children.add(Divider());
        } else {
          children.add(SizedBox(height: 8));
        }
      }
    }
    return children;
  }

  void requestFriend(BuildContext context, List<User> usersList) async {
    String userId =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => RequestFriendSelection(usersList, data)));
    if (userId != null) {
      setState(() {
        friendsDb.addFriendRequest(currentUser.userId, userId);
      });
    }
  }
}
