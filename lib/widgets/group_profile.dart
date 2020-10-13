import 'package:bideuchre/data/group.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/data_store.dart';
import 'group_overview.dart';
import 'group_settings.dart';

class GroupProfile extends StatefulWidget {
  final Group group;

  GroupProfile(this.group);

  @override
  _GroupProfileState createState() => _GroupProfileState();
}

class _GroupProfileState extends State<GroupProfile> {
  @override
  Widget build(BuildContext context) {
    Data data = DataStore.currentData;
    Group group = data.relationshipsDb.getGroup(widget.group.groupId);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group == null ? 'Loading...' : group.name),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(MdiIcons.accountGroup), text: 'Overview'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            group == null ? Container() : GroupOverview(group),
            group == null ? Container() : GroupSettings(group),
          ],
        ),
      ),
    );
  }
}
