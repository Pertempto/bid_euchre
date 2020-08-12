import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'game_overview.dart';
import 'game_settings.dart';
import 'game_stats.dart';

class GameDetail extends StatefulWidget {
  final Game game;

  GameDetail(this.game);

  @override
  _GameDetailState createState() => _GameDetailState();
}

class _GameDetailState extends State<GameDetail> {
  @override
  Widget build(BuildContext context) {
    return DataStore.dataWrap((data) {
      Game game = data.games.firstWhere((g) => g.gameId == widget.game.gameId, orElse: () => null);
      bool notLoaded = !data.loaded || game == null;
      Widget loadingWidget = Center(child: CircularProgressIndicator());
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Game Details'),
            bottom: TabBar(
              tabs: <Widget>[
                Tab(icon: Icon(MdiIcons.scoreboard), text: 'Overview'),
                Tab(icon: Icon(MdiIcons.chartLine), text: 'Stats'),
                Tab(icon: Icon(Icons.settings), text: 'Settings'),
              ],
            ),
          ),
          body: Container(
            color: Colors.white,
            child: TabBarView(
              children: <Widget>[
                notLoaded ? loadingWidget : GameOverview(game),
                notLoaded ? loadingWidget : GameStats(game),
                notLoaded ? loadingWidget : GameSettings(game),
              ],
            ),
          ),
        ),
      );
    }, allowNull: true);
  }
}
