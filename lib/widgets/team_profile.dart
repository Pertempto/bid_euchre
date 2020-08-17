import 'package:bideuchre/widgets/entity_stats.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/data_store.dart';
import '../util.dart';
import 'compare.dart';
import 'team_overview.dart';
import 'team_selection.dart';

class TeamProfile extends StatefulWidget {
  final String teamId;

  TeamProfile(this.teamId);

  @override
  _TeamProfileState createState() => _TeamProfileState();
}

class _TeamProfileState extends State<TeamProfile> {
  String teamId;

  @override
  Widget build(BuildContext context) {
    teamId = widget.teamId;
    Data data = DataStore.lastData;
    String teamName = Util.teamName(teamId, data);
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
          actions: <Widget>[
            IconButton(
              icon: Icon(MdiIcons.compareHorizontal),
              onPressed: () {
                compareTeam(context);
              },
            )
          ],
        ),
        body: TabBarView(
          children: <Widget>[
            teamName == null ? Container() : TeamOverview(teamId),
            teamName == null ? Container() : EntityStats(teamId),
          ],
        ),
      ),
    );
  }

  compareTeam(BuildContext context) async {
    String oTeamId = await Navigator.push(context, MaterialPageRoute(builder: (context) => TeamSelection()));
    if (oTeamId != null) {
      if (teamId == oTeamId) {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text('Can\'t compare a player with themself!'),
        ));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Compare(teamId, oTeamId)));
      }
    }
  }
}
