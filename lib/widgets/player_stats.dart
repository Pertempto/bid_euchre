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
    List<Widget> children = [
      ListTile(
        title: Text('Bidding', style: textTheme.headline6),
        dense: true,
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text('Bid', style: textTheme.subtitle2, textAlign: TextAlign.end), flex: 6),
            Expanded(child: Text('Count', style: textTheme.subtitle2, textAlign: TextAlign.end), flex: 14),
            Expanded(child: Text('Frequency', style: textTheme.subtitle2, textAlign: TextAlign.end), flex: 17),
            Expanded(child: Text('Made %', style: textTheme.subtitle2, textAlign: TextAlign.end), flex: 15),
            Expanded(child: Text('Tricks', style: textTheme.subtitle2, textAlign: TextAlign.end), flex: 12),
            Expanded(child: Text('Points', style: textTheme.subtitle2, textAlign: TextAlign.end), flex: 12),
          ],
        ),
      )
    ];
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
      children.add(Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(split.bid.toString(), textAlign: TextAlign.end), flex: 6),
            Expanded(child: Text(split.count.toString(), textAlign: TextAlign.end), flex: 14),
            Expanded(child: Text(rateString, textAlign: TextAlign.end), flex: 17),
            Expanded(child: Text(madeString, textAlign: TextAlign.end), flex: 15),
            Expanded(child: Text(tricksString, textAlign: TextAlign.end), flex: 12),
            Expanded(child: Text(pointsString, textAlign: TextAlign.end), flex: 12),
          ],
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
