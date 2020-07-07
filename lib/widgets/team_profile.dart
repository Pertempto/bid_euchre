import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/data_store.dart';
import '../util.dart';
import 'team_overview.dart';
import 'team_stats.dart';

class TeamProfile extends StatefulWidget {
  final String teamId;

  TeamProfile(this.teamId);

  @override
  _TeamProfileState createState() => _TeamProfileState();
}

class _TeamProfileState extends State<TeamProfile> {
  @override
  Widget build(BuildContext context) {
    String teamId = widget.teamId;
    Data data = DataStore.lastData;
    String teamName = Util.getTeamName(teamId, data);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(teamName == null ? 'Loading...' : teamName),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.people), text: 'Overview'),
              Tab(icon: Icon(MdiIcons.chartLine), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            teamName == null ? Container() : TeamOverview(teamId),
            teamName == null ? Container() : TeamStats(teamId),
          ],
        ),
      ),
    );
  }
}
