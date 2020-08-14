import 'package:bideuchre/widgets/compare.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/data_store.dart';
import '../data/player.dart';
import 'player_overview.dart';
import 'player_selection.dart';
import 'player_settings.dart';

class PlayerProfile extends StatefulWidget {
  final Player player;

  PlayerProfile(this.player);

  @override
  _PlayerProfileState createState() => _PlayerProfileState();
}

class _PlayerProfileState extends State<PlayerProfile> {
  Player player;

  @override
  Widget build(BuildContext context) {
    Data data = DataStore.lastData;
    player = data.players[widget.player.playerId];
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(player == null ? 'Loading...' : player.fullName),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.person), text: 'Overview'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(MdiIcons.compareHorizontal),
              onPressed: () {
                comparePlayer(context);
              },
            )
          ],
        ),
        body: TabBarView(
          children: <Widget>[
            player == null ? Container() : PlayerOverview(player),
            player == null ? Container() : PlayerSettings(player),
          ],
        ),
      ),
    );
  }

  comparePlayer(BuildContext context) async {
    Player compare = await Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerSelection()));
    if (compare != null) {
      if (compare.playerId == player.playerId) {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text('Can\'t compare a player with themself!'),
        ));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Compare(player.playerId, compare.playerId)));
      }
    }
  }
}
