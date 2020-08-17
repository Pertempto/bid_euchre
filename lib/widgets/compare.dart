import 'package:bideuchre/data/stats.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/player.dart';
import '../util.dart';
import 'bidding_splits_section.dart';
import 'player_profile.dart';

class Compare extends StatefulWidget {
  final String id1;
  final String id2;

  Compare(this.id1, this.id2);

  @override
  _CompareState createState() => _CompareState();
}

class _CompareState extends State<Compare> {
  static const List<StatType> COMPARE_STATS = [
    StatType.overallRating,
    StatType.record,
    StatType.numGames,
    StatType.streak,
    StatType.bidderRating,
    StatType.numBids,
    StatType.madeBidPercentage,
    StatType.biddingFrequency,
    StatType.averageBid,
    StatType.pointsPerBid,
    StatType.settingPct,
  ];
  TextTheme textTheme;
  bool teams = false;
  List<Player> players;
  List<Map<int, BiddingSplit>> splits;

  @override
  Widget build(BuildContext context) {
    Data data = DataStore.lastData;
    textTheme = Theme.of(context).textTheme;

    teams = widget.id1.contains(' ');
    List<Color> colors;
    if (teams) {
      List<String> team1Ids = widget.id1.split(' ');
      List<String> team2Ids = widget.id2.split(' ');
      players = [
        data.players[team1Ids[0]],
        data.players[team2Ids[0]],
        data.players[team1Ids[1]],
        data.players[team2Ids[1]],
      ];
      colors = [];
      for (int i = 0; i < 2; i++) {
        colors.add(data.statsDb.getColor(Util.teamId([players[i].playerId, players[i + 2].playerId])));
      }
      splits = [data.statsDb.getTeamBiddingSplits(widget.id1), data.statsDb.getTeamBiddingSplits(widget.id2)];
    } else {
      players = [
        data.players[widget.id1],
        data.players[widget.id2],
      ];
      colors = [];
      for (int i = 0; i < 2; i++) {
        colors.add(data.statsDb.getColor(players[i].playerId));
      }
      splits = [data.statsDb.getPlayerBiddingSplits(widget.id1), data.statsDb.getPlayerBiddingSplits(widget.id2)];
    }
    Widget playerTitle(int index) {
      return GestureDetector(
        child: Text(players[index].shortName, style: textTheme.headline5.copyWith(color: colors[index % 2])),
        onTap: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PlayerProfile(players[index])));
        },
      );
    }

    List<Widget> children = [];
    if (teams) {
      children.add(Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                playerTitle(0),
                playerTitle(2),
              ],
            ),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                playerTitle(1),
                playerTitle(3),
              ],
            ),
          ],
        ),
      ));
    } else {
      children.add(Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: <Widget>[
            playerTitle(0),
            Spacer(),
            playerTitle(1),
          ],
        ),
      ));
    }
    children.add(Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text('General Stats', style: textTheme.headline6),
    ));
    for (StatType stat in COMPARE_STATS) {
      StatItem stat1 = data.statsDb.getStat(widget.id1, stat);
      StatItem stat2 = data.statsDb.getStat(widget.id2, stat);
      List<Color> colors = [Colors.blue, Colors.blue];
      if (stat1.sortValue < stat2.sortValue) {
        colors = [Colors.green, Colors.red];
      } else if (stat1.sortValue > stat2.sortValue) {
        colors = [Colors.red, Colors.green];
      }
      children.add(Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                stat1.toString(),
                textAlign: TextAlign.start,
                style: textTheme.bodyText1.copyWith(color: colors[0]),
              ),
              flex: 1,
            ),
            Expanded(
              child: Text(
                StatsDb.statName(stat),
                textAlign: TextAlign.center,
                style: textTheme.bodyText2,
              ),
              flex: 2,
            ),
            Expanded(
              child: Text(
                stat2.toString(),
                textAlign: TextAlign.end,
                style: textTheme.bodyText1.copyWith(color: colors[1]),
              ),
              flex: 1,
            ),
          ],
        ),
      ));
    }
    children.add(BiddingSplitsSection(widget.id1, id2: widget.id2));
    children.add(SizedBox(height: 64));
    return Scaffold(
      appBar: AppBar(title: Text(teams ? 'Team Comparison' : 'Player Comparison')),
      body: SingleChildScrollView(child: Column(children: children)),
    );
  }
}
