import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/group.dart';
import 'package:bideuchre/data/relationships.dart';
import 'package:bideuchre/data/user.dart';
import 'package:bideuchre/widgets/user_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class GroupOverview extends StatefulWidget {
  final Group group;

  GroupOverview(this.group);

  @override
  _GroupOverviewState createState() => _GroupOverviewState();
}

class _GroupOverviewState extends State<GroupOverview> with AutomaticKeepAliveClientMixin<GroupOverview> {
  Group group;
  TextTheme textTheme;
  Data data;
  RelationshipsDb relationshipsDb;
  User currentUser;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    group = widget.group;
    textTheme = Theme.of(context).textTheme;
    return DataStore.dataWrap((data) {
      this.data = data;
      relationshipsDb = data.relationshipsDb;
      currentUser = data.currentUser;
      List<Widget> children = [
        SizedBox(height: 8),
        membersSection(),
        invitedUsersSection(),
      ];
      return SingleChildScrollView(child: Column(children: children));
    });
  }

  Widget membersSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Group Members', style: textTheme.headline6),
        trailing: group.adminId != currentUser.userId
            ? null
            : OutlineButton.icon(
                icon: Icon(Icons.person_add),
                label: Text('Invite User'),
                onPressed: () {
                  List<User> usersList = data.users.values
                      .where((u) =>
                          u.userId != currentUser.userId &&
                          relationshipsDb.getGroupRelationship(group.groupId, u.userId) == null)
                      .toList();
                  inviteUser(context, usersList);
                },
              ),
        dense: true,
      ),
    ];
    for (String userId in relationshipsDb.getMemberIds(group.groupId)) {
      User user = data.users[userId];
      if (user != null) {
        children.add(ListTile(
          title: Text(user.name, style: textTheme.subtitle1),
          trailing: Icon(group.adminId == userId ? MdiIcons.accountCowboyHat : Icons.person),
          dense: true,
          onTap: group.adminId != currentUser.userId || userId == group.adminId
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Remove Member'),
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
                                relationshipsDb.deleteMember(group.groupId, userId);
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

  Widget invitedUsersSection() {
    if (group.adminId != currentUser.userId) {
      return Container();
    }
    List<Widget> children = [
      ListTile(
        title: Text('Invited Users', style: textTheme.headline6),
        dense: true,
      ),
    ];
    List<String> invitedUsers = relationshipsDb.getInvitedUserIds(group.groupId);
    for (String userId in invitedUsers) {
      User user = data.users[userId];
      if (user != null) {
        children.add(ListTile(
          title: Text(user.name, style: textTheme.subtitle1),
          trailing: Icon(MdiIcons.accountArrowRight),
          dense: true,
          onTap: group.adminId != currentUser.userId
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Group Invitation'),
                        contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                        content: Text('Delete group invitation to ${user.name}?'),
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
                                relationshipsDb.cancelInvite(group.groupId, userId);
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

  void inviteUser(BuildContext context, List<User> usersList) async {
    String userId =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => UserSelection('Invite User', usersList)));
    if (userId != null) {
      setState(() {
        relationshipsDb.inviteUser(group.groupId, userId);
      });
    }
  }
}
