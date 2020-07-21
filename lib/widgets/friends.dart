import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/data_store.dart';
import '../data/player.dart';
import '../data/relationships.dart';
import '../data/user.dart';
import 'user_selection.dart';

class FriendsPage extends StatefulWidget {
  FriendsPage();

  @override
  _FriendsState createState() => _FriendsState();
}

class _FriendsState extends State<FriendsPage> with AutomaticKeepAliveClientMixin<FriendsPage> {
  Data data;
  User currentUser;
  RelationshipsDb relationshipsDb;
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
      currentUser = data.currentUser;
      relationshipsDb = data.relationshipsDb;
      players = data.players;
      users = data.users;
      List<Widget> children = [
        SizedBox(height: 8),
        friendsSection(),
        friendRequestsSection(),
        blockedUsersSection(),
        SizedBox(height: 32),
      ];
      return SingleChildScrollView(
        child: Column(
          children: children,
        ),
      );
    });
  }

  Widget friendsSection() {
    List<Widget> children = [];
    List<String> friendIds = relationshipsDb.getFriendIds(currentUser.userId);
    children.add(ListTile(
      title: Text('Friends', style: textTheme.headline6),
      trailing: OutlineButton.icon(
        icon: Icon(Icons.person_add),
        label: Text('Request Friend'),
        onPressed: () {
          List<User> usersList = users.values
              .where((u) =>
                  u.userId != currentUser.userId &&
                  relationshipsDb.getRelationship(currentUser.userId, u.userId) == null)
              .toList();
          requestFriend(context, usersList);
        },
      ),
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
                          relationshipsDb.deleteFriend(currentUser.userId, userId);
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
    children.add(Divider());
    return Column(children: children);
  }

  Widget friendRequestsSection() {
    List<Widget> children = [];
    List<String> requestingFriendIds = relationshipsDb.getRequestingFriendIds(currentUser.userId);
    List<String> pendingFriendRequestsIds = relationshipsDb.getPendingFriendRequestIds(currentUser.userId);
    List<String> allRequestIds = requestingFriendIds + pendingFriendRequestsIds;
    if (allRequestIds.isEmpty) {
      return Container();
    }
    children.add(ListTile(
      title: Text('Friend Requests', style: textTheme.headline6),
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
                            relationshipsDb.blockFriendRequest(currentUser.userId, userId);
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text('Accept'),
                        onPressed: () {
                          setState(() {
                            relationshipsDb.acceptFriendRequest(currentUser.userId, userId);
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
                            relationshipsDb.cancelFriendRequest(currentUser.userId, userId);
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
    children.add(Divider());
    return Column(children: children);
  }

  Widget blockedUsersSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Blocked Users', style: textTheme.headline6),
        dense: true,
      )
    ];
    List<String> blockedUserIds = data.relationshipsDb.getBlockedUserIds(data.currentUser.userId);
    if (blockedUserIds.isEmpty) {
      return Container();
    }
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
                          relationshipsDb.deleteBlockedFriendRequest(currentUser.userId, userId);
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
    children.add(Divider());
    return Column(children: children);
  }

  void requestFriend(BuildContext context, List<User> usersList) async {
    String userId = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => UserSelection('Request Friend', usersList)));
    if (userId != null) {
      setState(() {
        relationshipsDb.addFriendRequest(currentUser.userId, userId);
      });
    }
  }
}
