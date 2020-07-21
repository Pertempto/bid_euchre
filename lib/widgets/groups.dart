import 'package:bideuchre/data/group.dart';
import 'package:bideuchre/widgets/group_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/data_store.dart';
import '../data/player.dart';
import '../data/relationships.dart';
import '../data/user.dart';

class GroupsPage extends StatefulWidget {
  GroupsPage();

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> with AutomaticKeepAliveClientMixin<GroupsPage> {
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
        groupsSection(),
        groupInvitesSection(),
        blockedGroupsSection(),
        SizedBox(height: 32),
      ];

      return SingleChildScrollView(
        child: Column(
          children: children,
        ),
      );
    });
  }

  Widget blockedGroupsSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Blocked Groups', style: textTheme.headline6),
        dense: true,
      ),
    ];
    List<String> blockedGroupIds = data.relationshipsDb.getBlockedGroupIds(data.currentUser.userId);
    if (blockedGroupIds.isEmpty) {
      return Container();
    }
    for (String groupId in blockedGroupIds) {
      Group group = relationshipsDb.getGroup(groupId);
      if (group != null) {
        children.add(ListTile(
          title: Text(group.name, style: textTheme.subtitle1),
          trailing: Icon(MdiIcons.accountGroup),
          dense: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Blocked Group'),
                  contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                  content: Text('Unblock ${group.name}?'),
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
                          relationshipsDb.deleteBlockedInvite(groupId, currentUser.userId);
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

  Widget groupsSection() {
    List<Widget> children = [];
    List<String> groupIds = relationshipsDb.getGroupIds(currentUser.userId);
    children.add(ListTile(
      title: Text('Groups', style: textTheme.headline6),
      trailing: OutlineButton.icon(
        icon: Icon(Icons.add),
        label: Text('Start Group'),
        onPressed: () {
          createGroup(context);
        },
      ),
      dense: true,
    ));
    for (String groupId in groupIds) {
      Group group = relationshipsDb.getGroup(groupId);
      if (group != null) {
        children.add(ListTile(
          title: Text(group.name, style: textTheme.subtitle1),
          trailing: Icon(MdiIcons.accountGroup),
          dense: true,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => GroupProfile(group)));
          },
        ));
      }
    }
    children.add(Divider());
    return Column(children: children);
  }

  Widget groupInvitesSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Group Invitations', style: textTheme.headline6),
        dense: true,
      )
    ];
    List<String> invitedGroupIds = relationshipsDb.getGroupInvitations(currentUser.userId);
    if (invitedGroupIds.isEmpty) {
      return Container();
    }
    for (String groupId in invitedGroupIds) {
      Group group = relationshipsDb.getGroup(groupId);
      if (group != null) {
        children.add(ListTile(
          title: Text(group.name, style: textTheme.subtitle1),
          trailing: Icon(MdiIcons.accountArrowLeft),
          dense: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Group Invitation'),
                  contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                  content: Text('${users[group.adminId].name} has invited you to join the group "${group.name}"'),
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
                          relationshipsDb.blockInvite(groupId, currentUser.userId);
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                    FlatButton(
                      child: Text('Accept'),
                      onPressed: () {
                        setState(() {
                          relationshipsDb.acceptInvite(groupId, currentUser.userId);
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

  void createGroup(BuildContext context) {
    TextEditingController textFieldController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New Group'),
          contentPadding: EdgeInsets.fromLTRB(24, 0, 24, 0),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Name:'),
              ),
              Expanded(
                child: TextField(controller: textFieldController),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Submit'),
              onPressed: () {
                String name = textFieldController.value.text.trim();
                if (name.isNotEmpty) {
                  Group group = Group.newGroup(currentUser.userId, name);
                  print('new group: ${group.groupId}');
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
