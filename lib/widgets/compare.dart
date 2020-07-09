import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/stats.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/player.dart';
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
    StatType.record,
    StatType.numGames,
    StatType.streak,
    StatType.avgScoreDiff,
    StatType.numBids,
    StatType.madeBidPercentage,
    StatType.biddingFrequency,
    StatType.averageBid,
    StatType.pointsPerBid,
  ];
  TextTheme textTheme;
  bool teams = false;
  List<Player> players;
  Map<String, Map<StatType, StatItem>> stats;
  List<Map<int, BiddingSplit>> splits;

  @override
  Widget build(BuildContext context) {
    Data data = DataStore.lastData;
    textTheme = Theme.of(context).textTheme;

    teams = widget.id1.contains(' ');
    if (teams) {
      List<String> team1Ids = widget.id1.split(' ');
      List<String> team2Ids = widget.id2.split(' ');
      players = [
        data.players[team1Ids[0]],
        data.players[team2Ids[0]],
        data.players[team1Ids[1]],
        data.players[team2Ids[1]],
      ];
      stats = data.statsDb.getTeamStats(COMPARE_STATS.toSet(), (team1Ids + team2Ids).toSet());
      splits = [data.statsDb.getTeamBiddingSplits(widget.id1), data.statsDb.getTeamBiddingSplits(widget.id2)];
    } else {
      players = [
        data.players[widget.id1],
        data.players[widget.id2],
      ];
      stats = data.statsDb.getPlayerStats(COMPARE_STATS.toSet(), {widget.id1, widget.id2});
      splits = [data.statsDb.getPlayerBiddingSplits(widget.id1), data.statsDb.getPlayerBiddingSplits(widget.id2)];
    }

    Widget playerTitle(int index) {
      return GestureDetector(
        child: Text(players[index].shortName, style: textTheme.headline5),
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
      child: Text('General Stats', style: textTheme.subtitle1.copyWith(fontWeight: FontWeight.w500)),
    ));
    for (StatType stat in COMPARE_STATS) {
      StatItem stat1 = stats[widget.id1][stat];
      StatItem stat2 = stats[widget.id2][stat];
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
    children.add(Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Text('Bidding Splits', style: textTheme.subtitle1.copyWith(fontWeight: FontWeight.w500)),
    ));
    List<int> numBids = [
      stats[widget.id1][StatType.numBids].statValue,
      stats[widget.id2][StatType.numBids].statValue,
    ];
    for (int bid in Round.ALL_BIDS) {
      if (splits[0][bid].count != 0 || splits[1][bid].count != 0) {
        children.add(Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(bid.toString(), style: textTheme.subtitle2.copyWith(fontWeight: FontWeight.w600)),
        ));
        for (int subStatIndex = 0; subStatIndex < 3; subStatIndex++) {
          List<double> values = [];
          List<String> strings = [];
          String statName = ['Frequency', 'Made %', 'Points'][subStatIndex];
          for (int i = 0; i < 2; i++) {
            BiddingSplit split = splits[i][bid];
            switch (subStatIndex) {
              case (0):
                String rateString = '-';
                double value = 0;
                if (split.count != 0) {
                  value = split.count / numBids[i];
                  rateString = '1 in ${(numBids[i] / split.count).toStringAsFixed(1)}';
                }
                values.add(value);
                strings.add(rateString);
                break;
              case (1):
                String madeString = '-';
                double value = 0;
                if (split.count != 0) {
                  value = split.madePct;
                  madeString = '${(split.madePct * 100).toStringAsFixed(1)}%';
                }
                values.add(value);
                strings.add(madeString);
                break;
              case (2):
                String pointsString = '-';
                double value = 0;
                if (split.count != 0) {
                  value = split.avgTricks;
                  pointsString = split.avgPoints.toStringAsFixed(2);
                }
                values.add(value);
                strings.add(pointsString);
                break;
            }
          }
          List<Color> colors = [Colors.blue, Colors.blue];
          if (values[0] > values[1]) {
            colors = [Colors.green, Colors.red];
          } else if (values[0] < values[1]) {
            colors = [Colors.red, Colors.green];
          }
          children.add(Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    strings[0],
                    textAlign: TextAlign.start,
                    style: textTheme.bodyText1.copyWith(color: colors[0]),
                  ),
                  flex: 1,
                ),
                Expanded(
                  child: Text(
                    statName,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyText2,
                  ),
                  flex: 2,
                ),
                Expanded(
                  child: Text(
                    strings[1],
                    textAlign: TextAlign.end,
                    style: textTheme.bodyText1.copyWith(color: colors[1]),
                  ),
                  flex: 1,
                ),
              ],
            ),
          ));
        }
      }
    }
    children.add(SizedBox(height: 64));
    return Scaffold(
      appBar: AppBar(title: Text(teams ? 'Team Comparison' : 'Player Comparison')),
      body: SingleChildScrollView(child: Column(children: children)),
    );
  }
}
