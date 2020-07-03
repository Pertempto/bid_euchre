import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlayerStats extends StatefulWidget {
  final Player player;

  PlayerStats(this.player);

  @override
  _PlayerStatsState createState() => _PlayerStatsState();
}

class _PlayerStatsState extends State<PlayerStats> with AutomaticKeepAliveClientMixin<PlayerStats> {
  Player player;
  Data data;
  TextTheme textTheme;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    player = widget.player;
    data = DataStore.lastData;
    textTheme = Theme.of(context).textTheme;
    List<Widget> children = [];
    return SingleChildScrollView(child: Column(children: children));
  }
}
