import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/stats.dart';
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
  Map<StatType, StatItem> playerStats;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    player = widget.player;
    data = DataStore.lastData;
    playerStats = data.statsDb.getPlayerStats(StatType.values.toSet(), {player.playerId})[player.playerId];
    textTheme = Theme.of(context).textTheme;
    List<Widget> children = [
      SizedBox(height: 8),
      biddingSection(),
      Divider(),
      SizedBox(height: 64),
    ];
    return SingleChildScrollView(child: Column(children: children));
  }

  Widget biddingSection() {
    List<List<Widget>> columnChildren = [];
    List<String> titles = ['Bid', 'Count', 'Frequency', 'Made %', 'Tricks', 'Points'];
    for (int i = 0; i < titles.length; i++) {
      columnChildren.add([Text(titles[i], style: textTheme.subtitle2)]);
    }
    Map<int, BiddingSplit> splits = data.statsDb.getPlayerBiddingSplits(player.playerId);
    int numBids = playerStats[StatType.numBids].statValue;
    for (int bid in Round.ALL_BIDS) {
      BiddingSplit split = splits[bid];
      String rateString = '-';
      String madeString = '-';
      String tricksString = '-';
      String pointsString = '-';
      if (split.count != 0) {
        rateString = '1 in ${(numBids / split.count).toStringAsFixed(1)}';
        madeString = '${(split.madePct * 100).toStringAsFixed(1)}%';
        tricksString = split.avgTricks.toStringAsFixed(2);
        pointsString = split.avgPoints.toStringAsFixed(2);
      }
      List<String> row = [
        split.bid.toString(),
        split.count.toString(),
        rateString,
        madeString,
        tricksString,
        pointsString
      ];
      for (int i = 0; i < row.length; i++) {
        columnChildren[i].add(Text(row[i]));
      }
    }
    List<Widget> children = [
      ListTile(
        title: Text('Bidding', style: textTheme.headline6),
        dense: true,
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: columnChildren
                .map(
                  (c) => Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: Column(
                        children: c.map((w) => Padding(padding: EdgeInsets.only(top: 4), child: w)).toList(),
                        crossAxisAlignment: CrossAxisAlignment.end),
                  ),
                )
                .toList()),
      ),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
