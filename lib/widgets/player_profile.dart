import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/data_store.dart';
import '../data/player.dart';
import 'player_overview.dart';
import 'player_settings.dart';
import 'player_stats.dart';

class PlayerProfile extends StatefulWidget {
  final Player player;

  PlayerProfile(this.player);

  @override
  _PlayerProfileState createState() => _PlayerProfileState();
}

class _PlayerProfileState extends State<PlayerProfile> {
  @override
  Widget build(BuildContext context) {
    return DataStore.dataWrap(
      (data) {
        Player player = data.players[widget.player.playerId];
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(player == null ? 'Loading...' : player.fullName),
              bottom: TabBar(
                tabs: <Widget>[
                  Tab(icon: Icon(Icons.person), text: 'Overview'),
                  Tab(icon: Icon(MdiIcons.chartLine), text: 'Stats'),
                  Tab(icon: Icon(Icons.settings), text: 'Settings'),
                ],
              ),
            ),
            body: TabBarView(
              children: <Widget>[
                player == null ? Container() : PlayerOverview(player),
                player == null ? Container() : PlayerStats(player),
                player == null ? Container() : PlayerSettings(player),
              ],
            ),
          ),
        );
      },
      allowNull: true,
    );
  }
}
