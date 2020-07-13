import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
        SizedBox(height: 8),
        friendsSection(),
        Divider(),
        friendRequestsSection(),
        Divider(),
        blockedUsersSection(),
        Divider(),
      ];

      return SingleChildScrollView(
        child: Column(
          children: children,
        ),
      );
    });
  }

  Widget blockedUsersSection() {
    List<Widget> children = [];
    List<String> blockedUserIds = data.friendsDb.getBlockedUserIds(data.currentUser.userId);
    children.add(ListTile(
      title: Text('Blocked Users', style: textTheme.headline6),
      dense: true,
    ));
    for (String userId in blockedUserIds) {
      User user = users[userId];
      if (user != null) {
        children.add(ListTile(
          title: Text(user.name, style: textTheme.subtitle1),
          trailing: Icon(Icons.person),
          dense: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Blocked Friend'),
                  contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                  content: Text('Unblock ${user.name}?'),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    FlatButton(
                      child: Text('Unblock'),
                      onPressed: () {
                        setState(() {
                          friendsDb.deleteBlockedFriendRequest(currentUser.userId, userId);
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
        ));
      }
    }
    return Column(children: children);
  }

  Widget friendsSection() {
    List<Widget> children = [];
    List<String> friendIds = friendsDb.getFriendIds(currentUser.userId);
    children.add(ListTile(
      title: Text('Friends', style: textTheme.headline6),
      dense: true,
    ));
    for (String userId in friendIds) {
      User user = users[userId];
      if (user != null) {
        children.add(ListTile(
          title: Text(user.name, style: textTheme.subtitle1),
          trailing: Icon(Icons.person),
          dense: true,
          onTap: () {
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
        ));
      }
    }
    return Column(children: children);
  }

  Widget friendRequestsSection() {
    List<Widget> children = [];
    List<String> requestingFriendIds = friendsDb.getRequestingFriendIds(currentUser.userId);
    List<String> pendingFriendRequestsIds = friendsDb.getPendingFriendRequestIds(currentUser.userId);
    List<String> allRequestIds = requestingFriendIds + pendingFriendRequestsIds;
    children.add(ListTile(
      title: Text('Friend Requests', style: textTheme.headline6),
      trailing: OutlineButton.icon(
        icon: Icon(Icons.person_add),
        label: Text('Request Friend'),
        onPressed: () {
          List<User> usersList = users.values
              .where((u) =>
                  u.userId != currentUser.userId && friendsDb.getRelationship(currentUser.userId, u.userId) == null)
              .toList();
          requestFriend(context, usersList);
        },
      ),
      dense: true,
    ));
    for (String userId in allRequestIds) {
      User user = users[userId];
      if (user != null) {
        children.add(ListTile(
          title: Text(user.name, style: textTheme.subtitle1),
          trailing: Icon(requestingFriendIds.contains(userId) ? MdiIcons.accountArrowLeft : MdiIcons.accountArrowRight),
          dense: true,
          onTap: () {
            if (requestingFriendIds.contains(userId)) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Friend Request'),
                    contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                    content: Text('Friend request from ${user.name}'),
                    actions: <Widget>[
                      FlatButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text('Block'),
                        onPressed: () {
                          setState(() {
                            friendsDb.blockFriendRequest(currentUser.userId, userId);
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text('Accept'),
                        onPressed: () {
                          setState(() {
                            friendsDb.acceptFriendRequest(currentUser.userId, userId);
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            } else {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Friend Request'),
                    contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                    content: Text('Delete friend request to ${user.name}?'),
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
                            friendsDb.cancelFriendRequest(currentUser.userId, userId);
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          },
        ));
      }
    }
    return Column(children: children);
  }

  void requestFriend(BuildContext context, List<User> usersList) async {
    String userId =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => RequestFriendSelection(usersList)));
    if (userId != null) {
      setState(() {
        friendsDb.addFriendRequest(currentUser.userId, userId);
      });
    }
  }
}
